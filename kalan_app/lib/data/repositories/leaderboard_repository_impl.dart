import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../local/database_helper.dart';
import '../models/leaderboard_entry_model.dart';
import '../remote/supabase_service.dart';
import '../../services/connectivity_service.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final DatabaseHelper _dbHelper;
  final ConnectivityService _connectivity;

  LeaderboardRepositoryImpl(this._dbHelper, this._connectivity);

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({String scope = 'national'}) async {
    final db = await _dbHelper.database;

    if (await _connectivity.isOnline()) {
      try {
        // En vrai projet, on ferait une vue ou une jointure pour avoir le pseudo
        // Ici on suppose que le pseudo est dans les metadata ou une table profile
        final response = await SupabaseService.client
            .from('leaderboard_entries')
            .select('*, users:user_id(pseudo, avatar_url)') // Supposant une jointure possible
            .eq('scope', scope)
            .order('points', ascending: false)
            .limit(50);

        final List<LeaderboardEntry> entries = [];
        for (var item in (response as List)) {
          final pseudo = item['users']?['pseudo'] ?? 'Anonyme';
          final avatar = item['users']?['avatar_url'];
          
          final model = LeaderboardEntryModel.fromSupabaseJson(item);
          entries.add(LeaderboardEntry(
            userId: model.userId,
            pseudo: pseudo,
            points: model.points,
            position: model.position,
            scope: model.scope,
            lastUpdated: model.lastUpdated,
            avatar: avatar,
          ));
          
          // Cache local
          await db.insert('leaderboard_entries', {
            'user_id': model.userId,
            'points': model.points,
            'scope': model.scope,
            'last_updated': model.lastUpdated.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return entries;
      } catch (e) {
        // Fallback to local
      }
    }

    // Local fallback
    final maps = await db.query('leaderboard_entries', 
        where: 'scope = ?', whereArgs: [scope], orderBy: 'points DESC');
    
    return maps.map((m) {
      final model = LeaderboardEntryModel.fromMap(m);
      return LeaderboardEntry(
        userId: model.userId,
        pseudo: model.pseudo, // Sera 'Anonyme' si pas stocké localement
        points: model.points,
        position: model.position,
        scope: model.scope,
        lastUpdated: model.lastUpdated,
        avatar: model.avatar,
      );
    }).toList();
  }

  @override
  Future<void> updateUserPoints(int points) async {
    final db = await _dbHelper.database;
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final data = {
      'user_id': user.id,
      'points': points,
      'last_updated': DateTime.now().toIso8601String(),
      'scope': 'national',
    };

    // 1. Local
    await db.insert('leaderboard_entries', data, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.update('users', {'points': points}, where: 'uuid = ?', whereArgs: [user.id]);

    // 2. Supabase
    if (await _connectivity.isOnline()) {
      try {
        await SupabaseService.client.from('leaderboard_entries').upsert(data);
      } catch (e) {
        await _addToSyncQueue('UPDATE_LEADERBOARD', data);
      }
    } else {
      await _addToSyncQueue('UPDATE_LEADERBOARD', data);
    }
  }

  Future<void> _addToSyncQueue(String action, Map<String, dynamic> payload) async {
    final db = await _dbHelper.database;
    await db.insert('sync_queue', {
      'action': action,
      'payload': jsonEncode(payload),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
