import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kalan.db');
    await _ensureTablesAndSeed(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE leaderboard_entries ADD COLUMN pseudo TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE leaderboard_entries ADD COLUMN avatar TEXT');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN school_id INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN class_id INTEGER');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE flashcards ADD COLUMN interval INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE flashcards ADD COLUMN repetitions INTEGER DEFAULT 0');
      } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        pseudo TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        school_id INTEGER,
        school_name TEXT,
        class_id INTEGER,
        class_name TEXT,
        language TEXT DEFAULT 'fr',
        points INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        streak INTEGER DEFAULT 0,
        is_guest INTEGER DEFAULT 0,
        avatar_id INTEGER,
        sync_status TEXT DEFAULT 'synced',
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_active DATE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE schools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        country TEXT DEFAULT 'Burkina Faso',
        city TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        subject TEXT,
        level TEXT,
        is_public INTEGER DEFAULT 0,
        download_count INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        deck_id TEXT NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        difficulty INTEGER DEFAULT 0,
        next_review DATETIME,
        is_synced INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        deck_id TEXT,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        duration_seconds INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE leaderboard_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        points INTEGER NOT NULL DEFAULT 0,
        position INTEGER,
        scope TEXT DEFAULT 'national',
        pseudo TEXT,
        avatar TEXT,
        last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, scope)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        badge_key TEXT NOT NULL,
        unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, badge_key)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS subjects (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        color INTEGER NOT NULL,
        bg_color INTEGER NOT NULL,
        icon_code INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS badges (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        description TEXT,
        category TEXT,
        image_path TEXT,
        color INTEGER NOT NULL,
        emoji TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Seed default data
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    // Check if badges are empty
    final badgesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM badges')) ?? 0;
    if (badgesCount == 0) {
      final defaultBadges = [
        {
          'id': 'explorateur',
          'label': 'L\'Explorateur',
          'description': 'Explorer 10 fiches',
          'category': 'apprentissage',
          'image_path': 'humanites/ideogram-v3.0_BADGE_Taama_—_L_Explorateur_du_Monde_—_Catégorie_Humanités_Niveau_Découvr-0.jpg',
          'color': 0xFF2D6A2D,
          'emoji': '🌍'
        },
        {
          'id': 'polyglotte',
          'label': 'Le Polyglotte',
          'description': 'Maîtriser 2 langues',
          'category': 'langue',
          'image_path': 'langue/ideogram-v3.0_BADGE_Jàmbaar_—_Le_Polyglotte_Courageux_—_Catégorie_Langues_Niveau_Découv-0.jpg',
          'color': 0xFF185FA5,
          'emoji': '🗣️'
        },
        {
          'id': 'chercheur',
          'label': 'L\'Apprenti Chercheur',
          'description': 'Première recherche',
          'category': 'sciences',
          'image_path': 'sciences/ideogram-v3.0_BADGE_Kalan-So_—_L_Apprenti_Chercheur_—_Catégorie_Sciences_Niveau_Découvre-0 (1).jpg',
          'color': 0xFF6A2D9F,
          'emoji': '🧪'
        },
        {
          'id': 'plume',
          'label': 'La Plume Légère',
          'description': 'Rédiger 5 textes',
          'category': 'litterature',
          'image_path': 'litterature/ideogram-v3.0_BADGE_Soro-Foli_—_La_Plume_Légère_—_Catégorie_Littérature_Niveau_Découv-0.jpg',
          'color': 0xFFBE123C,
          'emoji': '🎭'
        },
        {
          'id': 'philosophe',
          'label': 'Le Philosophe',
          'description': 'Réussir un débat',
          'category': 'apprentissage',
          'image_path': 'humanites/ideogram-v3.0_BADGE_Bɩŋ-Wɩɩga_—_Le_Philosophe_—_Catégorie_Humanités_Niveau_Maître_B-0.jpg',
          'color': 0xFF854F0B,
          'emoji': '📜'
        },
      ];
      for (var b in defaultBadges) {
        await db.insert('badges', b, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    // Check if subjects are empty
    final subjectsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM subjects')) ?? 0;
    if (subjectsCount == 0) {
      final defaultSubjects = [
        {'id': 'SVT', 'label': 'SVT', 'color': 0xFF2D6A2D, 'bg_color': 0xFFEAF3DE, 'icon_code': 0xf0204}, // biotech
        {'id': 'Histoire-Géo', 'label': 'Histoire-Géo', 'color': 0xFF854F0B, 'bg_color': 0xFFFAEEDA, 'icon_code': 0xf011b}, // public
        {'id': 'Mathématiques', 'label': 'Mathématiques', 'color': 0xFF185FA5, 'bg_color': 0xFFE6F1FB, 'icon_code': 0xf0809}, // functions
        {'id': 'Physique-Chimie', 'label': 'Physique-Chimie', 'color': 0xFF6A2D9F, 'bg_color': 0xFFEEEDFE, 'icon_code': 0xf0178}, // science
        {'id': 'Anglais', 'label': 'Anglais', 'color': 0xFFE07B39, 'bg_color': 0xFFFCEFE6, 'icon_code': 0xf06e4}, // language
        {'id': 'Français', 'label': 'Français', 'color': 0xFFB00020, 'bg_color': 0xFFFDECEE, 'icon_code': 0xf05a1}, // menu_book
      ];
      for (var s in defaultSubjects) {
        await db.insert('subjects', s, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<Map<String, dynamic>?> getUserByPseudo(String pseudo) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'pseudo = ?',
      whereArgs: [pseudo],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getDecks(String userId) async {
    final db = await instance.database;
    return await db.query('decks', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getFlashcards(String deckUuid) async {
    final db = await instance.database;
    return await db.query('flashcards', where: 'deck_id = ?', whereArgs: [deckUuid]);
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final db = await instance.database;
    
    final deckCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM decks WHERE user_id = ?', [userId]
    )) ?? 0;

    final flashcardCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM flashcards WHERE deck_id IN (SELECT uuid FROM decks WHERE user_id = ?)', [userId]
    )) ?? 0;

    final quizCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM quiz_results WHERE user_id = ?', [userId]
    )) ?? 0;

    final avgScoreResult = await db.rawQuery(
      'SELECT AVG(CAST(score AS FLOAT) / total) as avg FROM quiz_results WHERE user_id = ?', [userId]
    );
    final avgScore = (avgScoreResult.first['avg'] as double?) ?? 0.0;

    final badgeCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM user_badges WHERE user_id = ?', [userId]
    )) ?? 0;

    return {
      'deckCount': deckCount,
      'flashcardCount': flashcardCount,
      'quizCount': quizCount,
      'avgScore': avgScore,
      'badgeCount': badgeCount,
    };
  }

  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    final db = await instance.database;
    return await db.query(
      'user_badges',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> getCardCount(String deckUuid) async {
    final db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM flashcards WHERE deck_id = ?', [deckUuid]
    )) ?? 0;
  }

  Future<String?> getLastReviewDate(String deckUuid) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(created_at) as last_date FROM quiz_results WHERE deck_id = ? OR deck_id IN (SELECT id FROM decks WHERE uuid = ?)', 
      [deckUuid, deckUuid]
    );
    return result.first['last_date'] as String?;
  }

  Future<void> _ensureTablesAndSeed(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS subjects (id TEXT PRIMARY KEY, label TEXT NOT NULL, color INTEGER NOT NULL, bg_color INTEGER NOT NULL, icon_code INTEGER NOT NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS badges (id TEXT PRIMARY KEY, label TEXT NOT NULL, description TEXT, category TEXT, image_path TEXT, color INTEGER NOT NULL, emoji TEXT NOT NULL)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Les colonnes is_synced sont déjà incluses dans le CREATE TABLE de la version 3.
    // Cette section est conservée uniquement pour la compatibilité avec d'anciennes installations.
    // On utilise PRAGMA table_info pour vérifier l'existence avant d'ALTER.
    
    final tablesToCheck = ['decks', 'flashcards', 'quiz_results'];
    for (var table in tablesToCheck) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      final hasIsSynced = columns.any((c) => c['name'] == 'is_synced');
      if (!hasIsSynced) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN is_synced INTEGER DEFAULT 0');
        } catch (_) {}
      }
    }

    await _seedDefaultData(db);
  }

  Future<List<Map<String, dynamic>>> getAllBadges() async {
    final db = await instance.database;
    await _ensureTablesAndSeed(db);
    return await db.query('badges');
  }

  Future<List<Map<String, dynamic>>> getAllSubjects() async {
    final db = await instance.database;
    await _ensureTablesAndSeed(db);
    return await db.query('subjects');
  }
  Future<List<Map<String, dynamic>>> getRecentActivity(String userId) async {
    final db = await instance.database;
    // Returns recent decks with their card count
    return await db.rawQuery('''
      SELECT d.*, 
             (SELECT COUNT(*) FROM flashcards WHERE deck_id = d.uuid) as cardCount,
             (SELECT score FROM quiz_results WHERE deck_id = d.uuid ORDER BY created_at DESC LIMIT 1) as lastScore
      FROM decks d
      WHERE d.user_id = ?
      ORDER BY d.created_at DESC
      LIMIT 5
    ''', [userId]);
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    final db = await instance.database;
    await db.update(
      'users',
      userData,
    );
  }

  Future<void> insertNotification(Map<String, dynamic> notification) async {
    final db = await instance.database;
    await db.insert('notifications', notification, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final db = await instance.database;
    await _ensureTablesAndSeed(db);
    final results = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    
    if (results.isEmpty) {
      final now = DateTime.now();
      final notifications = [
        {
          'id': 'welcome-1',
          'user_id': userId,
          'type': 'review',
          'title': 'Bienvenue sur KALAN ! 🎉',
          'message': 'Commence par importer un cours en PDF ou photo pour générer tes premières fiches.',
          'is_read': 0,
          'created_at': now.subtract(const Duration(minutes: 5)).toIso8601String(),
        },
        {
          'id': 'welcome-2',
          'user_id': userId,
          'type': 'badge',
          'title': 'Objectif Champion ! 🏆',
          'message': 'Révise chaque jour pour débloquer de nouveaux badges africains prestigieux.',
          'is_read': 0,
          'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        }
      ];
      for (var n in notifications) {
        await db.insert('notifications', n, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return await db.query(
        'notifications',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    }
    return results;
  }

  Future<void> markNotificationsAsRead(String userId) async {
    final db = await instance.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> markNotificationAsRead(String id) async {
    final db = await instance.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

