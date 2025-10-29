CREATE TABLE IF NOT EXISTS spots (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  subtitle TEXT,
  details TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  address TEXT,
  tags TEXT,
  topics TEXT,
  imageRemoteURLs TEXT,
  groupId TEXT,
  userId TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  version INTEGER NOT NULL,
  deleted INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_spots_groupId ON spots(groupId);
CREATE INDEX IF NOT EXISTS idx_spots_version ON spots(version);

CREATE TABLE IF NOT EXISTS groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  inviteCode TEXT UNIQUE NOT NULL,
  memberCount INTEGER NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  version INTEGER NOT NULL,
  deleted INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_groups_version ON groups(version);

CREATE TABLE IF NOT EXISTS sync_states (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lastVersion INTEGER NOT NULL,
  updatedAt TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vectors (
  spotId TEXT PRIMARY KEY,
  embedding TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  deviceId TEXT UNIQUE NOT NULL,
  createdAt TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_users_deviceId ON users(deviceId);

CREATE TABLE IF NOT EXISTS device_tokens (
  userId TEXT NOT NULL,
  token TEXT NOT NULL,
  platform TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  PRIMARY KEY (userId, token)
);
CREATE INDEX IF NOT EXISTS idx_device_tokens_userId ON device_tokens(userId);
