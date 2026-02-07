-- 1. 用户表 (Users)
-- 存储用户的基本信息，密码必须存储哈希值(Hash)，严禁存储明文
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,     -- 邮箱作为唯一标识，用于登录
  password_hash TEXT NOT NULL,    -- 存储加密后的密码
  avatar_url TEXT,                -- 用户头像地址 (可选)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 增强版排行榜 (Leaderboard)
-- 关联 user_id，这样如果用户改名，排行榜也可以通过连表查询同步显示新名字
DROP TABLE IF EXISTS leaderboard;
CREATE TABLE leaderboard (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,       -- 关联 users.id
  username TEXT NOT NULL,         -- 冗余存储一份当时的用户名，方便快速查询（快照）
  score INTEGER NOT NULL,
  duration INTEGER NOT NULL,      -- 耗时（秒）
  played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
-- 创建复合索引：分数降序，时间升序（分数高、用时少在前）
CREATE INDEX idx_leaderboard_rank ON leaderboard(score DESC, duration ASC);

-- 3. 待办事项表 (Todos)
DROP TABLE IF EXISTS todos;
CREATE TABLE todos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,       -- 关联 users.id
  content TEXT NOT NULL,          -- 待办内容
  is_completed BOOLEAN DEFAULT 0, -- 0:未完成, 1:已完成
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_todos_user ON todos(user_id);

-- 4. 重要倒计时表 (Countdowns)
DROP TABLE IF EXISTS countdowns;
CREATE TABLE countdowns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,       -- 关联 users.id
  title TEXT NOT NULL,            -- 倒计时标题 (e.g. "期末考试")
  target_time TIMESTAMP NOT NULL, -- 目标时间
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_countdowns_user ON countdowns(user_id);

-- 5. 待验证注册表 (Pending Registrations)
-- 用于暂存注册信息，直到用户输入正确的验证码
DROP TABLE IF EXISTS pending_registrations;
CREATE TABLE pending_registrations (
  email TEXT PRIMARY KEY,       -- 邮箱作为主键，防止重复发送堆积
  username TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  code TEXT NOT NULL,           -- 6位数字验证码
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
