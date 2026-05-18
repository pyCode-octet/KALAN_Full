import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/user_repository.dart';
import '../local/database_helper.dart';
import '../remote/supabase_service.dart';
import '../../services/connectivity_service.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseHelper _dbHelper;
  final ConnectivityService _connectivity;

  UserRepositoryImpl(this._dbHelper, this._connectivity);

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('current_user_uuid');
    
    List<Map<String, dynamic>> maps;
    if (currentUserId != null) {
      // Chercher l'utilisateur spécifique
      maps = await db.query('users', where: 'uuid = ?', whereArgs: [currentUserId], limit: 1);
    } else {
      // Fallback au premier utilisateur si aucun n'est marqué (pour la compatibilité)
      maps = await db.query('users', limit: 1);
    }
    
    if (maps.isNotEmpty) {
      return Map<String, dynamic>.from(maps.first);
    }
    
    // Default if nothing in local
    return {
      'pseudo': 'Élève KALAN',
      'points': 0,
      'level': 1,
      'streak': 0,
      'class': 'Non définie',
    };
  }

  @override
  Future<void> updateUserProfile({String? pseudo, String? avatar, int? avatarId, String? school, String? className, String? firstName, String? lastName}) async {
    final db = await _dbHelper.database;
    final user = SupabaseService.currentUser;
    if (user == null) return;
    
    final Map<String, dynamic> updates = {};
    if (pseudo != null) updates['pseudo'] = pseudo;
    if (className != null) updates['class_name'] = className;
    if (avatarId != null) updates['avatar_id'] = avatarId;
    if (avatar != null) updates['avatar_url'] = avatar;
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (school != null) updates['school_name'] = school;
    updates['updated_at'] = DateTime.now().toIso8601String();
    
    final bool isOnline = await _connectivity.isOnline();
    if (isOnline) {
      updates['sync_status'] = 'synced';
    } else {
      updates['sync_status'] = 'pending';
    }

    // 1. Local
    if (updates.isNotEmpty) {
      await db.update('users', updates, where: 'uuid = ?', whereArgs: [user.id]);
    }

    // 2. Supabase
    final Map<String, dynamic> supabasePayload = {
      'uuid': user.id,
      if (pseudo != null) 'pseudo': pseudo,
      if (className != null) 'class_name': className,
      if (avatarId != null) 'avatar_id': avatarId,
      if (avatar != null) 'avatar_url': avatar,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (school != null) 'school_name': school,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (isOnline) {
      try {
        await SupabaseService.client.auth.updateUser(
          UserAttributes(
            data: {
              if (pseudo != null) 'pseudo': pseudo,
              if (className != null) 'class': className,
              if (avatarId != null) 'avatar_id': avatarId,
              if (avatar != null) 'avatar_url': avatar,
              if (firstName != null) 'firstName': firstName,
              if (lastName != null) 'lastName': lastName,
            },
          ),
        );
        await SupabaseService.client.from('users').update(Map.from(supabasePayload)..remove('uuid')).eq('uuid', user.id);
      } catch (e) {
        await _addToSyncQueue('UPDATE_USER', supabasePayload);
      }
    } else {
      await _addToSyncQueue('UPDATE_USER', supabasePayload);
    }
  }

  @override
  Future<void> addPoints(int points) async {
    final db = await _dbHelper.database;
    final profile = await getUserProfile();
    final currentPoints = profile['points'] as int? ?? 0;
    
    // Calcul des nouveaux points (pas moins de 0)
    int newPoints = currentPoints + points;
    if (newPoints < 0) newPoints = 0;
    
    final userId = profile['uuid'];
    if (userId == null) return;

    // Calcul du nouveau niveau simplifié (ex: tous les 100 points)
    // On peut utiliser LevelUtils si disponible, sinon une logique simple
    int newLevel = (newPoints / 100).floor() + 1;
    if (newLevel < 1) newLevel = 1;

    final Map<String, dynamic> updates = {
      'points': newPoints,
      'level': newLevel,
    };

    // 1. Local
    await db.update('users', updates, where: 'uuid = ?', whereArgs: [userId]);

    // 2. Supabase
    final bool isOnline = await _connectivity.isOnline();
    final Map<String, dynamic> syncPayload = {
      'uuid': userId,
      ...updates,
    };

    if (isOnline) {
      try {
        await SupabaseService.client
            .from('users')
            .update(updates)
            .eq('uuid', userId);
        
        await SupabaseService.client
            .from('leaderboard_entries')
            .upsert({
              'user_id': userId,
              'points': newPoints,
              'last_updated': DateTime.now().toIso8601String(),
              'scope': 'national',
            });
      } catch (e) {
        await _addToSyncQueue('UPDATE_USER_POINTS', syncPayload);
      }
    } else {
      await _addToSyncQueue('UPDATE_USER_POINTS', syncPayload);
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    return await _dbHelper.getUserStats(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentActivity(String userId) async {
    return await _dbHelper.getRecentActivity(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    return await _dbHelper.getUserBadges(userId);
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
