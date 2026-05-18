# KALAN Backend

Configuration et documentation du backend Supabase.

---

## Tables à créer

### 1. users
```sql
id UUID PRIMARY KEY
uuid UUID UNIQUE
pseudo TEXT
first_name TEXT
last_name TEXT
school_name TEXT
class_name TEXT
points INTEGER DEFAULT 0
streak INTEGER DEFAULT 0
avatar_url TEXT
avatar_id INTEGER
sound_enabled BOOLEAN DEFAULT true
reminder_enabled BOOLEAN DEFAULT false
reminder_time TEXT
notifications_enabled BOOLEAN DEFAULT true
sync_status TEXT DEFAULT 'synced'
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

### 2. subjects
```sql
id TEXT PRIMARY KEY
label TEXT
color INTEGER
bg_color INTEGER
icon_code INTEGER
```

### 3. decks
```sql
id UUID PRIMARY KEY
uuid UUID UNIQUE
user_id UUID → users.id
title TEXT
subject TEXT
level TEXT
description TEXT
is_public BOOLEAN DEFAULT false
is_favorite BOOLEAN DEFAULT false
card_count INTEGER DEFAULT 0
mastery_percentage INTEGER DEFAULT 0
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

### 4. flashcards
```sql
id UUID PRIMARY KEY
uuid UUID UNIQUE
deck_id UUID → decks.id
question TEXT
answer TEXT
type TEXT DEFAULT 'direct'
options JSONB
correct_index INTEGER
mastery_level INTEGER DEFAULT 0
next_review TIMESTAMPTZ
created_at TIMESTAMPTZ
```

### 5. quiz_results
```sql
id UUID PRIMARY KEY
user_id UUID → users.id
deck_id UUID → decks.id
score INTEGER
total_questions INTEGER
time_seconds INTEGER
created_at TIMESTAMPTZ
```

### 6. badges
```sql
id UUID PRIMARY KEY
label TEXT
emoji TEXT
color INTEGER
description TEXT
category TEXT
requirement TEXT
created_at TIMESTAMPTZ
```

### 7. user_badges
```sql
user_id UUID → users.id
badge_id UUID → badges.id
unlocked_at TIMESTAMPTZ
PRIMARY KEY (user_id, badge_id)
```

---

## Setup & Schema

Le schéma complet et les scripts de création se trouvent dans le fichier :
👉 [database_schema.sql](file:///c:/Users/angen/Documents/kalan/kalan_backend/database_schema.sql)

1. Créer projet sur https://supabase.com
2. Project Settings → API → copier URL + anon key
3. SQL Editor → Copier le contenu de `database_schema.sql` et l'exécuter.
4. Activer RLS (Row Level Security) sur toutes les tables.
```sql
-- Exemple RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access their own data" ON users FOR ALL USING (auth.uid() = id);
```