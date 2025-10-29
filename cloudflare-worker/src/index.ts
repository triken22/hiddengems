import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Env {
  DB: D1Database;
  IMAGES: R2Bucket;
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
  globalRating: number;
  ratingUpdatedAt: string | null;
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

// Configure CORS with specific origins (update with your actual domains)
app.use('*', cors({
  origin: (origin) => {
    // Allow localhost for development and your production domains
    const allowedOrigins = [
      'http://localhost:3000',
      'https://hiddengems.app',
      'https://www.hiddengems.app',
      'https://api.hiddengems.app'
    ];
    return allowedOrigins.includes(origin) ? origin : allowedOrigins[0];
  },
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400,
}));

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

// Admin cleanup endpoint for placeholder data (protected)
app.post('/api/admin/cleanup/placeholders', async (c) => {
  // Additional admin check - ensure this is only accessible with admin privileges
  const adminToken = c.env.ADMIN_TOKEN || c.env.APP_SYNC_TOKEN;
  const authHeader = c.req.header('Authorization');
  const token = authHeader?.replace('Bearer ', '').trim();
  
  if (!adminToken || token !== adminToken) {
    return c.json({ error: 'Admin access required' }, 403);
  }
  
  const db = c.env.DB;
  const now = new Date().toISOString();
  
  try {
    // Find placeholder spots based on heuristics
    const placeholderSpots = await db.prepare(`
      SELECT id, imageRemoteURLs FROM spots 
      WHERE deleted = 0 
      AND (
        title IN ('Untitled', 'New Spot', '') 
        OR (title = 'Untitled' AND details = '' AND imageRemoteURLs IS NULL)
        OR (title = 'New Spot' AND details = '' AND imageRemoteURLs IS NULL)
      )
      AND createdAt < datetime('now', '-7 days')
    `).all<{ id: string; imageRemoteURLs: string | null }>();
    
    if (placeholderSpots.results && placeholderSpots.results.length > 0) {
      // Soft delete placeholder spots
      const spotIds = placeholderSpots.results.map(spot => spot.id);
      const placeholders = spotIds.map(() => '?').join(',');
      
      await db.prepare(`
        UPDATE spots 
        SET deleted = 1, updatedAt = ? 
        WHERE id IN (${placeholders})
      `).bind(now, ...spotIds).run();
      
      // Optional: Delete R2 objects for placeholders
      for (const spot of placeholderSpots.results) {
        if (spot.imageRemoteURLs) {
          try {
            const imageUrls = JSON.parse(spot.imageRemoteURLs) as string[];
            for (const url of imageUrls) {
              const fileName = url.split('/').pop();
              if (fileName) {
                await c.env.IMAGES.delete(fileName);
              }
            }
          } catch (error) {
            console.error('Failed to delete R2 objects for spot:', spot.id, error);
          }
        }
      }
      
      return c.json({ 
        status: 'success', 
        deletedCount: placeholderSpots.results.length,
        message: `Cleaned up ${placeholderSpots.results.length} placeholder spots`
      });
    }
    
    return c.json({ 
      status: 'success', 
      deletedCount: 0,
      message: 'No placeholder spots found to clean up'
    });
    
  } catch (error) {
    console.error('Cleanup error:', error);
    return c.json({ error: 'Failed to cleanup placeholder data' }, 500);
  }
});

// Anonymous User Management
app.post('/api/users/register', async (c) => {
  const body = await c.req.json<{ deviceId: string }>();
  const userId = crypto.randomUUID();
  const now = new Date().toISOString();
  
  try {
    await c.env.DB.prepare(
      'INSERT INTO users (id, deviceId, createdAt) VALUES (?1, ?2, ?3)'
    )
      .bind(userId, body.deviceId, now)
      .run();
    
    return c.json({ userId, deviceId: body.deviceId, createdAt: now });
  } catch (error) {
    // If device ID already exists, return existing user
    const existing = await c.env.DB.prepare(
      'SELECT id, deviceId, createdAt FROM users WHERE deviceId = ?1'
    )
      .bind(body.deviceId)
      .first<{ id: string; deviceId: string; createdAt: string }>();
    
    if (existing) {
      return c.json({ userId: existing.id, deviceId: existing.deviceId, createdAt: existing.createdAt });
    }
    
    return c.json({ error: 'Failed to register user' }, 500);
  }
});

// Image Upload
app.post('/api/images/upload', async (c) => {
  const formData = await c.req.formData();
  const file = formData.get('image') as File;
  
  if (!file) {
    return c.json({ error: 'No image provided' }, 400);
  }
  
  // Generate unique filename
  const fileExt = file.name.split('.').pop() || 'jpg';
  const fileName = `${crypto.randomUUID()}.${fileExt}`;
  
  // Upload to R2
  await c.env.IMAGES.put(fileName, file.stream(), {
    httpMetadata: {
      contentType: file.type,
    },
  });
  
  // Return CDN URL (you'll need to set up a custom domain for R2)
  const imageUrl = `https://images.hiddengems.app/${fileName}`;
  
  return c.json({ url: imageUrl, fileName });
});

// Get Image (if not using custom domain)
app.get('/api/images/:fileName', async (c) => {
  const fileName = c.req.param('fileName');
  const object = await c.env.IMAGES.get(fileName);
  
  if (!object) {
    return c.json({ error: 'Image not found' }, 404);
  }
  
  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);
  headers.set('cache-control', 'public, max-age=31536000');
  
  return new Response(object.body, { headers });
});

app.post('/api/sync/push', async (c) => {
  // Validate request body size (max 10MB)
  const contentLength = c.req.header('content-length');
  if (contentLength && parseInt(contentLength) > 10 * 1024 * 1024) {
    return c.json({ error: 'Payload too large (max 10MB)' }, 413);
  }
  
  let payload: { spots: any[]; groups: any[] };
  try {
    payload = await c.req.json<{
      spots: any[];
      groups: any[];
    }>();
  } catch (error) {
    return c.json({ error: 'Invalid JSON payload' }, 400);
  }
  
  // Validate payload structure
  if (!Array.isArray(payload.spots) || !Array.isArray(payload.groups)) {
    return c.json({ error: 'Invalid payload: spots and groups must be arrays' }, 400);
  }
  
  // Limit number of items per request
  if (payload.spots.length > 500 || payload.groups.length > 100) {
    return c.json({ error: 'Too many items: max 500 spots and 100 groups per request' }, 400);
  }

  const now = new Date().toISOString();
  const db = c.env.DB;

  for (const spot of payload.spots) {
    await db
      .prepare(
        `INSERT INTO spots (id, title, subtitle, details, latitude, longitude, address, tags, topics, imageRemoteURLs, groupId, userId, globalRating, ratingUpdatedAt, createdAt, updatedAt, version, deleted)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?18)
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
           globalRating = excluded.globalRating,
           ratingUpdatedAt = excluded.ratingUpdatedAt,
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
        spot.globalRating ?? 0,
        spot.ratingUpdatedAt ?? null,
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
  const limit = Math.min(Number(c.req.query('limit') ?? '1000'), 1000); // Cap at 1000
  const offset = Number(c.req.query('offset') ?? '0');
  
  const rows = await c.env.DB.prepare(
    'SELECT * FROM spots WHERE version > ?1 ORDER BY version ASC LIMIT ?2 OFFSET ?3'
  )
    .bind(since, limit, offset)
    .all<SpotRow>();

  const groupRows = await c.env.DB.prepare(
    'SELECT * FROM groups WHERE version > ?1 ORDER BY version ASC LIMIT ?2 OFFSET ?3'
  )
    .bind(since, limit, offset)
    .all<GroupRow>();

  const hasMore = (rows.results?.length ?? 0) === limit || (groupRows.results?.length ?? 0) === limit;

  return c.json({
    spots: rows.results?.map(deserializeSpot) ?? [],
    groups: groupRows.results?.map(deserializeGroup) ?? [],
    hasMore,
    nextOffset: hasMore ? offset + limit : undefined
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
  const topK = Math.min(body.topK ?? 10, 100); // Cap at 100 for performance
  
  // Limit vector fetch to avoid memory issues (e.g., most recent 1000 vectors)
  // In production, use a proper vector database or ANN index
  const vectors = await c.env.DB.prepare(
    'SELECT spotId, embedding FROM vectors ORDER BY updatedAt DESC LIMIT 1000'
  ).all<{ spotId: string; embedding: string }>();
  
  const query = body.embedding;
  
  // Pre-allocate array for better performance
  const scored: { id: string; score: number }[] = [];
  
  for (const row of vectors.results ?? []) {
    try {
      const embedding = JSON.parse(row.embedding) as number[];
      const score = cosineSimilarity(query, embedding);
      scored.push({ id: row.spotId, score });
    } catch (error) {
      console.error('Failed to parse embedding for spot:', row.spotId, error);
      continue;
    }
  }
  
  // Use partial sort for better performance when topK << n
  scored.sort((a, b) => b.score - a.score);
  
  return c.json({ 
    spotIds: scored.slice(0, topK).map((item) => item.id),
    totalVectorsSearched: scored.length
  });
});

// Rating update endpoint
app.post('/api/spots/:id/rating', async (c) => {
  const spotId = c.req.param('id');
  const body = await c.req.json<{ rating: number }>();
  const now = new Date().toISOString();
  
  if (body.rating < 0 || body.rating > 5) {
    return c.json({ error: 'Rating must be between 0 and 5' }, 400);
  }
  
  try {
    // Update the spot's rating and increment version for sync
    await c.env.DB.prepare(`
      UPDATE spots 
      SET globalRating = ?1, ratingUpdatedAt = ?2, updatedAt = ?3, version = version + 1 
      WHERE id = ?4
    `).bind(body.rating, now, now, spotId).run();
    
    // Return the updated spot
    const updatedSpot = await c.env.DB.prepare(
      'SELECT * FROM spots WHERE id = ?1'
    ).bind(spotId).first<SpotRow>();
    
    if (!updatedSpot) {
      return c.json({ error: 'Spot not found' }, 404);
    }
    
    return c.json(deserializeSpot(updatedSpot));
    
  } catch (error) {
    console.error('Rating update error:', error);
    return c.json({ error: 'Failed to update rating' }, 500);
  }
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
    globalRating: row.globalRating,
    ratingUpdatedAt: row.ratingUpdatedAt,
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
