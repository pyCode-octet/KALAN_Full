import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String userId;
  const LoadNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddNotificationEvent extends NotificationEvent {
  final String userId;
  final String type;
  final String title;
  final String message;

  const AddNotificationEvent({
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
  });

  @override
  List<Object?> get props => [userId, type, title, message];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  final String userId;
  const MarkAllNotificationsAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MarkSingleNotificationAsRead extends NotificationEvent {
  final String notificationId;
  final String userId;
  const MarkSingleNotificationAsRead({required this.notificationId, required this.userId});

  @override
  List<Object?> get props => [notificationId, userId];
}
