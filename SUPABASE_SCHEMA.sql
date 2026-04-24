-- ============================================================================
-- SUPABASE DATABASE SCHEMA
-- ============================================================================
-- Execute these queries in Supabase Dashboard → SQL Editor
-- This schema matches the code: users (id, created_at, email, name, password_hash)
-- ============================================================================

-- Drop existing tables (clean install)
-- WARNING: this deletes all data!
DROP TABLE IF EXISTS logout CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS watch_log CASCADE;
DROP TABLE IF EXISTS watchlist CASCADE;
DROP TABLE IF EXISTS favorites CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- 1. USERS — main user table
-- Columns: id (BIGSERIAL PK), created_at (TIMESTAMPTZ DEFAULT now()),
--          email (TEXT UNIQUE), name (TEXT), password_hash (TEXT)
-- ============================================================================
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 2. USER_SETTINGS — per-user settings
-- ============================================================================
CREATE TABLE user_settings (
  user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  dark_theme INTEGER DEFAULT 1,
  language TEXT DEFAULT 'ru'
);

-- ============================================================================
-- 3. FAVORITES — favorite movies
-- ============================================================================
CREATE TABLE favorites (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  movie_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  overview TEXT,
  poster_path TEXT,
  backdrop_path TEXT,
  vote_average REAL,
  vote_count INTEGER,
  release_date TEXT,
  genre_ids TEXT,
  popularity REAL,
  added_at TEXT NOT NULL,
  UNIQUE(user_id, movie_id)
);

CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_movie ON favorites(movie_id);

-- ============================================================================
-- 4. WATCHLIST — watchlist with status
-- ============================================================================
CREATE TABLE watchlist (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  movie_id INTEGER NOT NULL,
  imdb_id TEXT,
  title TEXT NOT NULL,
  poster_path TEXT,
  status TEXT NOT NULL,
  user_rating REAL,
  notes TEXT,
  watched_date TEXT,
  added_date TEXT NOT NULL,
  watch_count INTEGER DEFAULT 0,
  UNIQUE(user_id, movie_id)
);

CREATE INDEX idx_watchlist_user ON watchlist(user_id);
CREATE INDEX idx_watchlist_movie ON watchlist(movie_id);
CREATE INDEX idx_watchlist_status ON watchlist(status);

-- ============================================================================
-- 5. WATCH_LOG — activity log
-- ============================================================================
CREATE TABLE watch_log (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  movie_id INTEGER NOT NULL,
  status TEXT NOT NULL,
  watch_date TEXT NOT NULL
);

CREATE INDEX idx_watch_log_user ON watch_log(user_id);
CREATE INDEX idx_watch_log_date ON watch_log(watch_date DESC);

-- ============================================================================
-- 6. REVIEWS — movie reviews
-- ============================================================================
CREATE TABLE reviews (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  movie_id INTEGER NOT NULL,
  user_name TEXT NOT NULL,
  rating REAL NOT NULL,
  comment TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_movie ON reviews(movie_id);

-- ============================================================================
-- 7. LOGOUT — saved accounts after logout
-- ============================================================================
CREATE TABLE logout (
  user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  logged_out_at TEXT NOT NULL
);

CREATE INDEX idx_logout_logged_out_at ON logout(logged_out_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY — отключено для anon ключа (без Supabase Auth)
-- ============================================================================
-- Так как приложение использует прямой доступ к таблицам через anon ключ
-- (без Supabase Auth), RLS должен быть отключен.
-- ВКЛЮЧИТЕ RLS и создайте политики, если будете использовать Auth.
-- ============================================================================

ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE favorites DISABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist DISABLE ROW LEVEL SECURITY;
ALTER TABLE watch_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;
ALTER TABLE logout DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
-- OPTIONAL: ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Enable RLS on tables and create policies to restrict access to own data only.
-- Example:
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE watch_log ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE logout ENABLE ROW LEVEL SECURITY;
--
-- Policies (adjust as needed):
-- CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid()::text = id::text);
-- CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid()::text = id::text);
-- CREATE POLICY "Users can manage own favorites" ON favorites FOR ALL USING (user_id = auth.uid());
-- CREATE POLICY "Users can manage own watchlist" ON watchlist FOR ALL USING (user_id = auth.uid());
-- CREATE POLICY "Users can manage own watch_log" ON watch_log FOR ALL USING (user_id = auth.uid());
-- CREATE POLICY "Users can manage own reviews" ON reviews FOR ALL USING (user_id = auth.uid());
-- CREATE POLICY "Users can manage own settings" ON user_settings FOR ALL USING (user_id = auth.uid());
-- CREATE POLICY "Users can manage own logout" ON logout FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
