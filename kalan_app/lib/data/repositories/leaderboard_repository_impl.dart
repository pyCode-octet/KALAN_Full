import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../local/database_helper.dart';
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
        final response = await SupabaseService.client.rpc(
          'get_leaderboard',
          params: {'scope_name': scope},
        );

        final List<LeaderboardEntry> entries = [];
        int index = 1;
        
        await db.delete('leaderboard_entries', where: 'scope = ?', whereArgs: [scope]);

        for (var item in (response as List)) {
          final entry = LeaderboardEntry(
            userId: item['user_uuid'],
            pseudo: item['pseudo'],
            points: item['total_points'],
            position: index++,
            scope: scope,
            lastUpdated: DateTime.now(),
            avatar: item['avatar_url'],
          );
          
          entries.add(entry);
          
          await db.insert('leaderboard_entries', {
            'user_id': entry.userId,
            'points': entry.points,
            'scope': scope,
            'pseudo': entry.pseudo,
            'avatar': entry.avatar,
            'last_updated': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return entries;
      } catch (e) {
        debugPrint("Erreur RPC Leaderboard : $e");
      }
    }

    // Fallback local
    final maps = await db.query('leaderboard_entries', 
        where: 'scope = ?', whereArgs: [scope], orderBy: 'points DESC');
    
    int index = 1;
    return maps.map((m) {
      return LeaderboardEntry(
        userId: m['user_id'] as String,
        pseudo: m['pseudo'] as String? ?? 'Anonyme',
        points: m['points'] as int? ?? 0,
        position: index++,
        scope: m['scope'] as String? ?? scope,
        lastUpdated: DateTime.parse(m['last_updated'] as String? ?? DateTime.now().toIso8601String()),
        avatar: m['avatar'] as String?,
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
