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

  Future<String?> _getLocalUserId() async {
    final db = await _dbHelper.database;
    final profiles = await db.query('user_profile', limit: 1);
    if (profiles.isNotEmpty) {
      return profiles.first['uuid'] as String?;
    }
    return null;
  }

  @override
  Future<List<UserBadge>> getUserBadges() async {
    final db = await _dbHelper.database;
    final userId = SupabaseService.currentUser?.id ?? await _getLocalUserId();
    if (userId == null) return [];

    if (await _connectivity.isOnline() && SupabaseService.currentUser != null) {
      try {
        final response = await SupabaseService.client
            .from('user_badges')
            .select()
            .eq('user_id', userId);
        
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

    final maps = await db.query('user_badges', where: 'user_id = ?', whereArgs: [userId]);
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
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    return await _dbHelper.getAllBadges();
  }

  @override
  Future<void> unlockBadge(String badgeKey) async {
    final db = await _dbHelper.database;
    final userId = SupabaseService.currentUser?.id ?? await _getLocalUserId();
    if (userId == null) return;

    final model = UserBadgeModel(
      userId: userId,
      badgeKey: badgeKey,
      unlockedAt: DateTime.now(),
    );

    // 1. Local
    await db.insert('user_badges', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // 2. Supabase
    if (await _connectivity.isOnline() && SupabaseService.currentUser != null) {
      try {
        await SupabaseService.client.from('user_badges').insert(model.toSupabaseJson());
      } catch (e) {
        await _addToSyncQueue('UNLOCK_BADGE', model.toSupabaseJson());
      }
    } else {
      await _addToSyncQueue('UNLOCK_BADGE', model.toSupabaseJson());
    }
  }

  @override
  Future<List<String>> checkAndAwardBadges() async {
    final userId = SupabaseService.currentUser?.id ?? await _getLocalUserId();
    if (userId == null) return [];
    return await _dbHelper.checkAndAwardBadges(userId);
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
