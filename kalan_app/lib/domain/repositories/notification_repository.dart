abstract class NotificationRepository {
  Future<List<Map<String, dynamic>>> getNotifications(String userId);
  Future<void> markAllAsRead(String userId);
  Future<void> markAsRead(String id);
  Future<void> addNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  });
}
