import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        
        // Note: Assurez-vous que la fonction RPC 'get_leaderboard' sur Supabase 
        // utilise 'users.uuid' (text) pour la jointure et non 'users.id' (uuid) 
        // pour éviter l'erreur "operator does not exist: uuid = text".
        
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
  Stream<List<LeaderboardEntry>> watchLeaderboard({String scope = 'national'}) {
    // Note: Pour un vrai temps réel avec jointure, on écoute la table leaderboard_entries
    // et on déclenche un rafraîchissement ou on mappe les données.
    // Supabase stream ne supporte pas directement les RPC ou jointures complexes en continu.
    // L'approche simple est d'écouter les changements et de re-fetch.
    
    return SupabaseService.client
        .from('leaderboard_entries')
        .stream(primaryKey: ['id'])
        .eq('scope', scope)
        .order('points', ascending: false)
        .asyncMap((data) async {
          // On enrichit les données avec les pseudos/avatars depuis la table users
          // car le stream ne contient que les données de leaderboard_entries
          final List<LeaderboardEntry> entries = [];
          int index = 1;

          for (var item in data) {
            // On récupère les infos du user pour chaque entrée
            // Idéalement, on pourrait mettre en cache ces infos
            final userRes = await SupabaseService.client
                .from('users')
                .select('pseudo, avatar_url')
                .eq('uuid', item['user_id'].toString())
                .maybeSingle();

            entries.add(LeaderboardEntry(
              userId: item['user_id'],
              pseudo: userRes?['pseudo'] ?? 'Anonyme',
              points: item['points'],
              position: index++,
              scope: scope,
              lastUpdated: DateTime.now(),
              avatar: userRes?['avatar_url'],
            ));
          }
          return entries;
        });
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
