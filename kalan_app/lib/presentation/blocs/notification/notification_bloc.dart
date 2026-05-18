import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc(this._repository) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<AddNotificationEvent>(_onAddNotification);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<MarkSingleNotificationAsRead>(_onMarkSingleAsRead);
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      final notifications = await _repository.getNotifications(event.userId);
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(const NotificationError('Erreur chargement des notifications'));
    }
  }

  Future<void> _onAddNotification(AddNotificationEvent event, Emitter<NotificationState> emit) async {
    try {
      await _repository.addNotification(
        userId: event.userId,
        type: event.type,
        title: event.title,
        message: event.message,
      );
      add(LoadNotifications(event.userId));
    } catch (e) {
      emit(const NotificationError('Erreur ajout de notification'));
    }
  }

  Future<void> _onMarkAllAsRead(MarkAllNotificationsAsRead event, Emitter<NotificationState> emit) async {
    try {
      await _repository.markAllAsRead(event.userId);
      add(LoadNotifications(event.userId));
    } catch (e) {
      emit(const NotificationError('Erreur marquage notifications'));
    }
  }

  Future<void> _onMarkSingleAsRead(MarkSingleNotificationAsRead event, Emitter<NotificationState> emit) async {
    try {
      await _repository.markAsRead(event.notificationId);
      add(LoadNotifications(event.userId));
    } catch (e) {
      emit(const NotificationError('Erreur marquage notification'));
    }
  }
}
