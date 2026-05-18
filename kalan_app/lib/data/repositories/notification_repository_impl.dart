import 'package:uuid/uuid.dart';
import '../../domain/repositories/notification_repository.dart';
import '../local/database_helper.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    return await _dbHelper.getNotifications(userId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _dbHelper.markNotificationsAsRead(userId);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _dbHelper.markNotificationAsRead(id);
  }

  @override
  Future<void> addNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) async {
    final notification = {
      'id': _uuid.v4(),
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _dbHelper.insertNotification(notification);
  }
}
