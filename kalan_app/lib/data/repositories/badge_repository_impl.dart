import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/user_badge.dart';
import '../../domain/repositories/badge_repository.dart';
import '../local/database_helper.dart';
import '../models/user_badge_model.dart';
import '../remote/supabase_service.dart';
import '../../services/connectivity_service.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  final DatabaseHelper _dbHelper;
  final ConnectivityService _connectivity;

  BadgeRepositoryImpl(this._dbHelper, this._connectivity);

  @override
  Future<List<UserBadge>> getUserBadges() async {
    final db = await _dbHelper.database;
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    if (await _connectivity.isOnline()) {
      try {
        final response = await SupabaseService.client
            .from('user_badges')
            .select()
            .eq('user_id', user.id);
        
        final List<UserBadge> badges = [];
        for (var item in (response as List)) {
          final model = UserBadgeModel.fromSupabaseJson(item);
          badges.add(UserBadge(
            userId: model.userId,
            badgeKey: model.badgeKey,
            unlockedAt: model.unlockedAt,
          ));
          
          // Cache local
          await db.insert('user_badges', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return badges;
      } catch (e) {
        // Fallback to local
      }
    }

    final maps = await db.query('user_badges', where: 'user_id = ?', whereArgs: [user.id]);
    return maps.map((m) {
      final model = UserBadgeModel.fromMap(m);
      return UserBadge(
        userId: model.userId,
        badgeKey: model.badgeKey,
        unlockedAt: model.unlockedAt,
      );
    }).toList();
  }

  @override
  Future<void> unlockBadge(String badgeKey) async {
    final db = await _dbHelper.database;
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final model = UserBadgeModel(
      userId: user.id,
      badgeKey: badgeKey,
      unlockedAt: DateTime.now(),
    );

    // 1. Local
    await db.insert('user_badges', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // 2. Supabase
    if (await _connectivity.isOnline()) {
      try {
        await SupabaseService.client.from('user_badges').insert(model.toSupabaseJson());
      } catch (e) {
        await _addToSyncQueue('UNLOCK_BADGE', model.toSupabaseJson());
      }
    } else {
      await _addToSyncQueue('UNLOCK_BADGE', model.toSupabaseJson());
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
