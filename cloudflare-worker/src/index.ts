import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Env {
  DB: D1Database;
  APP_SYNC_TOKEN: string;
}

type SpotRow = {
  id: string;
  title: string;
  subtitle: string | null;
  details: string | null;
  latitude: number;
  longitude: number;
  address: string | null;
  tags: string | null;
  topics: string | null;
  imageRemoteURLs: string | null;
  groupId: string | null;
  userId: string | null;
  createdAt: string;
  updatedAt: string;
  version: number;
  deleted: number;
};

type GroupRow = {
  id: string;
  name: string;
  inviteCode: string;
  memberCount: number;
  createdAt: string;
  updatedAt: string;
  version: number;
  deleted: number;
};

const app = new Hono<{ Bindings: Env }>();
app.use('*', cors());

app.use('/api/*', async (c, next) => {
  const header = c.req.header('Authorization');
  if (!header || !header.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401);
  }
  const token = header.replace('Bearer ', '').trim();
  if (token !== c.env.APP_SYNC_TOKEN) {
    return c.json({ error: 'Forbidden' }, 403);
  }
  await next();
});

app.get('/api/health', (c) => c.json({ status: 'ok' }));

app.post('/api/sync/push', async (c) => {
  const payload = await c.req.json<{
    spots: any[];
    groups: any[];
  }>();

  const now = new Date().toISOString();
  const db = c.env.DB;

  for (const spot of payload.spots) {
    await db
      .prepare(
        `INSERT INTO spots (id, title, subtitle, details, latitude, longitude, address, tags, topics, imageRemoteURLs, groupId, userId, createdAt, updatedAt, version, deleted)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16)
         ON CONFLICT(id) DO UPDATE SET
           title = excluded.title,
           subtitle = excluded.subtitle,
           details = excluded.details,
           latitude = excluded.latitude,
           longitude = excluded.longitude,
           address = excluded.address,
           tags = excluded.tags,
           topics = excluded.topics,
           imageRemoteURLs = excluded.imageRemoteURLs,
           groupId = excluded.groupId,
           userId = excluded.userId,
           updatedAt = excluded.updatedAt,
           version = excluded.version,
           deleted = excluded.deleted`
      )
      .bind(
        spot.id,
        spot.title,
        spot.subtitle ?? null,
        spot.details ?? null,
        spot.latitude,
        spot.longitude,
        spot.address ?? null,
        JSON.stringify(spot.tags ?? []),
        JSON.stringify(spot.topics ?? []),
        JSON.stringify(spot.imageRemoteURLs ?? []),
        spot.groupId ?? null,
        spot.userId ?? null,
        spot.createdAt ?? now,
        spot.updatedAt ?? now,
        spot.version ?? 0,
        spot.deleted ? 1 : 0
      )
      .run();
  }

  for (const group of payload.groups) {
    await db
      .prepare(
        `INSERT INTO groups (id, name, inviteCode, memberCount, createdAt, updatedAt, version, deleted)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
         ON CONFLICT(id) DO UPDATE SET
           name = excluded.name,
           inviteCode = excluded.inviteCode,
           memberCount = excluded.memberCount,
           updatedAt = excluded.updatedAt,
           version = excluded.version,
           deleted = excluded.deleted`
      )
      .bind(
        group.id,
        group.name,
        group.inviteCode,
        group.memberCount,
        group.createdAt ?? now,
        group.updatedAt ?? now,
        group.version ?? 0,
        group.deleted ? 1 : 0
      )
      .run();
  }

  return c.json({ status: 'ok' });
});

app.get('/api/sync/pull', async (c) => {
  const since = Number(c.req.query('sinceVersion') ?? '0');
  const rows = await c.env.DB.prepare(
    'SELECT * FROM spots WHERE version > ?1 ORDER BY version ASC'
  )
    .bind(since)
    .all<SpotRow>();

  const groupRows = await c.env.DB.prepare(
    'SELECT * FROM groups WHERE version > ?1 ORDER BY version ASC'
  )
    .bind(since)
    .all<GroupRow>();

  return c.json({
    spots: rows.results?.map(deserializeSpot) ?? [],
    groups: groupRows.results?.map(deserializeGroup) ?? []
  });
});

app.post('/api/group', async (c) => {
  const body = await c.req.json<{ name: string }>();
  const id = crypto.randomUUID();
  const inviteCode = crypto.randomUUID().slice(0, 6).toUpperCase();
  const now = new Date().toISOString();
  await c.env.DB.prepare(
    'INSERT INTO groups (id, name, inviteCode, memberCount, createdAt, updatedAt, version, deleted) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, 0)'
  )
    .bind(id, body.name, inviteCode, 1, now, now, 1)
    .run();

  return c.json({ id, name: body.name, inviteCode, memberCount: 1, createdAt: now, updatedAt: now, version: 1, deleted: false });
});

app.post('/api/group/join', async (c) => {
  const body = await c.req.json<{ inviteCode: string }>();
  const row = await c.env.DB.prepare('SELECT * FROM groups WHERE inviteCode = ?1')
    .bind(body.inviteCode)
    .first<GroupRow>();
  if (!row) {
    return c.json({ error: 'Group not found' }, 404);
  }
  await c.env.DB.prepare('UPDATE groups SET memberCount = memberCount + 1, updatedAt = ?2 WHERE id = ?1')
    .bind(row.id, new Date().toISOString())
    .run();
  return c.json(deserializeGroup(row));
});

app.post('/api/vector/upsert', async (c) => {
  const body = await c.req.json<{ spotId: string; embedding: number[] }>();
  await c.env.DB.prepare(
    'INSERT OR REPLACE INTO vectors (spotId, embedding, updatedAt) VALUES (?1, ?2, ?3)'
  )
    .bind(body.spotId, JSON.stringify(body.embedding), new Date().toISOString())
    .run();
  return c.json({ status: 'ok' });
});

app.post('/api/search/semantic', async (c) => {
  const body = await c.req.json<{ embedding: number[]; topK?: number }>();
  const vectors = await c.env.DB.prepare('SELECT spotId, embedding FROM vectors').all<{ spotId: string; embedding: string }>();
  const query = body.embedding;
  const scored = (vectors.results ?? []).map((row) => {
    const embedding = JSON.parse(row.embedding) as number[];
    return { id: row.spotId, score: cosineSimilarity(query, embedding) };
  });
  scored.sort((a, b) => b.score - a.score);
  const topK = body.topK ?? 10;
  return c.json({ spotIds: scored.slice(0, topK).map((item) => item.id) });
});

function deserializeSpot(row: SpotRow) {
  return {
    id: row.id,
    title: row.title,
    subtitle: row.subtitle,
    details: row.details,
    latitude: row.latitude,
    longitude: row.longitude,
    address: row.address,
    tags: JSON.parse(row.tags ?? '[]'),
    topics: JSON.parse(row.topics ?? '[]'),
    imageRemoteURLs: JSON.parse(row.imageRemoteURLs ?? '[]'),
    groupId: row.groupId,
    userId: row.userId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    version: row.version,
    deleted: row.deleted === 1
  };
}

function deserializeGroup(row: GroupRow) {
  return {
    id: row.id,
    name: row.name,
    inviteCode: row.inviteCode,
    memberCount: row.memberCount,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    version: row.version,
    deleted: row.deleted === 1
  };
}

function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length) return 0;
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

export default app;
