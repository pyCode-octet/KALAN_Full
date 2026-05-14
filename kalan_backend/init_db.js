const { Client } = require('pg');

const DATABASE_URL = 'postgresql://postgres:Kalan_2026_I2A@db.cxljiqtrdadlaayvrmik.supabase.co:5432/postgres';

const SQL = `
-- 1. Table decks
CREATE TABLE IF NOT EXISTS decks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  uuid text UNIQUE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  subject text,
  level text,
  is_public boolean DEFAULT false,
  download_count int8 DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE decks ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'decks' AND policyname = 'Public decks visible') THEN
    CREATE POLICY "Public decks visible" ON decks FOR SELECT USING (is_public = true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'decks' AND policyname = 'Own decks visible') THEN
    CREATE POLICY "Own decks visible" ON decks FOR SELECT USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'decks' AND policyname = 'Own decks insert') THEN
    CREATE POLICY "Own decks insert" ON decks FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'decks' AND policyname = 'Own decks update') THEN
    CREATE POLICY "Own decks update" ON decks FOR UPDATE USING (auth.uid() = user_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'decks' AND policyname = 'Own decks delete') THEN
    CREATE POLICY "Own decks delete" ON decks FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- 2. Table flashcards
CREATE TABLE IF NOT EXISTS flashcards (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  uuid text UNIQUE NOT NULL,
  deck_id uuid REFERENCES decks(id) ON DELETE CASCADE,
  question text NOT NULL,
  answer text NOT NULL,
  difficulty smallint DEFAULT 1,
  next_review timestamptz,
  interval integer DEFAULT 0,
  repetitions integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'flashcards' AND policyname = 'Own flashcards') THEN
    CREATE POLICY "Own flashcards" ON flashcards FOR ALL USING (
      EXISTS (SELECT 1 FROM decks WHERE decks.id = flashcards.deck_id AND decks.user_id = auth.uid())
    );
  END IF;
END $$;

-- 3. Table quiz_results
CREATE TABLE IF NOT EXISTS quiz_results (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  deck_id uuid REFERENCES decks(id) ON DELETE SET NULL,
  score int4 NOT NULL,
  total int4 NOT NULL,
  duration_seconds int4 DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'quiz_results' AND policyname = 'Own quiz results') THEN
    CREATE POLICY "Own quiz results" ON quiz_results FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

-- 4. Table leaderboard_entries
CREATE TABLE IF NOT EXISTS leaderboard_entries (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  points int4 NOT NULL DEFAULT 0,
  position int4,
  scope text DEFAULT 'national',
  sync_timestamp int8,
  is_synced boolean DEFAULT false,
  last_updated timestamptz DEFAULT now()
);

ALTER TABLE leaderboard_entries ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'leaderboard_entries' AND policyname = 'Leaderboard public') THEN
    CREATE POLICY "Leaderboard public" ON leaderboard_entries FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'leaderboard_entries' AND policyname = 'Own leaderboard entries') THEN
    CREATE POLICY "Own leaderboard entries" ON leaderboard_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 5. Table user_badges
CREATE TABLE IF NOT EXISTS user_badges (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_key text NOT NULL,
  unlocked_at timestamptz DEFAULT now(),
  UNIQUE(user_id, badge_key)
);

ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_badges' AND policyname = 'Own badges') THEN
    CREATE POLICY "Own badges" ON user_badges FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;
`;

async function run() {
  const client = new Client({ connectionString: DATABASE_URL, ssl: { rejectUnauthorized: false } });
  try {
    await client.connect();
    console.log('Connected to new Supabase DB');
    await client.query(SQL);
    console.log('Tables and Policies created successfully!');
  } catch (e) {
    console.error('Error creating tables:', e.message);
  } finally {
    await client.end();
  }
}

run();
