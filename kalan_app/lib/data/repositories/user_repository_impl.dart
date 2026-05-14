import 'package:supabase_flutter/supabase_flutter.dart';
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
    
    // Fetch from local SQLite
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    
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
    
    final Map<String, dynamic> updates = {};
    if (pseudo != null) updates['pseudo'] = pseudo;
    if (className != null) updates['class'] = className;
    if (avatarId != null) updates['avatar_id'] = avatarId;
    if (avatar != null) updates['avatar_url'] = avatar;
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (school != null) updates['school_id'] = int.tryParse(school);

    // 1. Local
    if (updates.isNotEmpty) {
      await db.update('users', updates);
    }

    // 2. Supabase Auth metadata
    if (await _connectivity.isOnline() && user != null) {
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
      } catch (e) {
        // Handle error
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    return await _dbHelper.getUserStats(userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentActivity(String userId) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    return await _dbHelper.getUserBadges(userId);
  }
}
