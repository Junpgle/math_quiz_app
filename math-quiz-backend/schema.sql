-- 1. 用户表 (Users)
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 触发器：用户更新时自动刷新 updated_at
CREATE TRIGGER IF NOT EXISTS update_users_timestamp AFTER UPDATE ON users
BEGIN
  UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- 2. 增强版排行榜 (Leaderboard)
-- 排行榜通常是历史快照，一般不需要 updated_at，除非允许修改分数
DROP TABLE IF EXISTS leaderboard;
CREATE TABLE leaderboard (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  username TEXT NOT NULL,
  score INTEGER NOT NULL,
  duration INTEGER NOT NULL,
  played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_leaderboard_rank ON leaderboard(score DESC, duration ASC);

-- 3. 待办事项表 (Todos)
DROP TABLE IF EXISTS todos;
CREATE TABLE todos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 用于同步的关键字段
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_todos_user ON todos(user_id);

-- 触发器：待办更新时自动刷新 updated_at (关键！)
CREATE TRIGGER IF NOT EXISTS update_todos_timestamp AFTER UPDATE ON todos
BEGIN
  UPDATE todos SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- 4. 倒计时表 (Countdowns)
DROP TABLE IF EXISTS countdowns;
CREATE TABLE countdowns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  target_time TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 修正了这里的重复字段
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_countdowns_user ON countdowns(user_id);

-- 触发器：倒计时更新时自动刷新 updated_at
CREATE TRIGGER IF NOT EXISTS update_countdowns_timestamp AFTER UPDATE ON countdowns
BEGIN
  UPDATE countdowns SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- 5. 待验证注册表 (Pending Registrations)
DROP TABLE IF EXISTS pending_registrations;
CREATE TABLE pending_registrations (
  email TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  code TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
