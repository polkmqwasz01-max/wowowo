import '../models/notification.dart';
import '../repositories/notification_read_state_repository.dart';
import '../repositories/notification_repository.dart';

class NotificationController {
  final NotificationRepository notificationRepository;
  final NotificationReadStateRepository readStateRepository;

  NotificationController({
    NotificationRepository? notificationRepository,
    NotificationReadStateRepository? readStateRepository,
  })  : notificationRepository =
            notificationRepository ?? NotificationRepository(),
        readStateRepository =
            readStateRepository ?? NotificationReadStateRepository();

  Future<NotificationState> load() async {
    final notifications = await notificationRepository.getNotifications();
    final readIds = await readStateRepository.getReadNotificationIds();

    return NotificationState(
      notifications: notifications,
      readNotificationIds: readIds,
    );
  }

  Future<NotificationState> markAsRead(
    NotificationState state,
    String notificationId,
  ) async {
    await readStateRepository.markAsRead(notificationId);

    return state.copyWith(
      readNotificationIds: {
        ...state.readNotificationIds,
        notificationId,
      },
    );
  }

  Future<NotificationState> markAllAsRead(
    NotificationState state,
  ) async {
    final ids = state.notifications.map((notification) => notification.id);

    await readStateRepository.markAllAsRead(ids);

    return state.copyWith(
      readNotificationIds: {
        ...state.readNotificationIds,
        ...ids,
      },
    );
  }
}

class NotificationState {
  final List<AppNotification> notifications;
  final Set<String> readNotificationIds;

  const NotificationState({
    required this.notifications,
    required this.readNotificationIds,
  });

  bool isRead(String notificationId) {
    return readNotificationIds.contains(notificationId);
  }

  int get unreadCount {
    return notifications
        .where((notification) => !isRead(notification.id))
        .length;
  }

  NotificationState copyWith({
    List<AppNotification>? notifications,
    Set<String>? readNotificationIds,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      readNotificationIds:
          readNotificationIds ?? this.readNotificationIds,
    );
  }
}
