import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification.dart';

class NotificationRepository {
final SupabaseClient _supabase;

NotificationRepository({SupabaseClient? supabase})
: _supabase = supabase ?? Supabase.instance.client;

Future<List<AppNotification>> getNotifications() async {
debugPrint('NOTIFICATION: starting query');

final response = await _supabase
    .from('notifications')
    .select()
    .order('created_at', ascending: false);

debugPrint(
  'NOTIFICATION: response type = ${response.runtimeType}',
);

final rows = List<Map<String, dynamic>>.from(
  response.map(
    (row) => Map<String, dynamic>.from(row as Map),
  ),
);

debugPrint(
  'NOTIFICATION: row count = ${rows.length}',
);

for (final row in rows) {
  debugPrint(
    'NOTIFICATION ROW: '
    '${row['id']} | '
    '${row['title']} | '
    '${row['type']}',
  );
}

final notifications = rows
    .map(AppNotification.fromMap)
    .toList();

debugPrint(
  'NOTIFICATION: model count = ${notifications.length}',
);

return notifications;

}
}