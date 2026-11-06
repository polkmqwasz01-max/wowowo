import 'package:shared_preferences/shared_preferences.dart';

class NotificationReadStateRepository {
  static const String _readNotificationsKey =
      'cripcheck_read_notifications';

  Future<Set<String>> getReadNotificationIds() async {
    final preferences = await SharedPreferences.getInstance();

    final ids = preferences.getStringList(_readNotificationsKey) ?? [];

    return ids.toSet();
  }

  Future<bool> isRead(String notificationId) async {
    final readIds = await getReadNotificationIds();

    return readIds.contains(notificationId);
  }

  Future<void> markAsRead(String notificationId) async {
    final preferences = await SharedPreferences.getInstance();

    final ids = preferences.getStringList(_readNotificationsKey) ?? [];

    if (!ids.contains(notificationId)) {
      ids.add(notificationId);

      await preferences.setStringList(
        _readNotificationsKey,
        ids,
      );
    }
  }

  Future<void> markAllAsRead(Iterable<String> notificationIds) async {
    final preferences = await SharedPreferences.getInstance();

    final existingIds =
        preferences.getStringList(_readNotificationsKey) ?? [];

    final ids = existingIds.toSet()..addAll(notificationIds);

    await preferences.setStringList(
      _readNotificationsKey,
      ids.toList(),
    );
  }

  Future<int> getUnreadCount(
    Iterable<String> notificationIds,
  ) async {
    final readIds = await getReadNotificationIds();

    return notificationIds
        .where((id) => !readIds.contains(id))
        .length;
  }

}
