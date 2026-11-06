import 'package:flutter/material.dart';

import '../controllers/notification_controller.dart';
import '../models/notification.dart';

class NotificationScreen extends StatefulWidget {
final ValueChanged<int>? onUnreadCountChanged;

const NotificationScreen({
super.key,
this.onUnreadCountChanged,
});

@override
State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
final NotificationController _controller = NotificationController();

NotificationState? _state;
Object? _error;
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadNotifications();
}

Future<void> _loadNotifications() async {
setState(() {
_isLoading = true;
_error = null;
});

try {
  final state = await _controller.load();

  if (!mounted) {
    return;
  }

  setState(() {
    _state = state;
    _isLoading = false;
  });

  widget.onUnreadCountChanged?.call(state.unreadCount);
} catch (error) {
  if (!mounted) {
    return;
  }

  setState(() {
    _error = error;
    _isLoading = false;
  });
}

}

Future<void> _markAsRead(AppNotification notification) async {
final currentState = _state;

if (currentState == null || currentState.isRead(notification.id)) {
  return;
}

try {
  final updatedState = await _controller.markAsRead(
    currentState,
    notification.id,
  );

  if (!mounted) {
    return;
  }

  setState(() {
    _state = updatedState;
  });

  widget.onUnreadCountChanged?.call(updatedState.unreadCount);
} catch (error) {
  _showError(error);
}

}

Future<void> _markAllAsRead() async {
final currentState = _state;

if (currentState == null || currentState.unreadCount == 0) {
  return;
}

try {
  final updatedState = await _controller.markAllAsRead(
    currentState,
  );

  if (!mounted) {
    return;
  }

  setState(() {
    _state = updatedState;
  });

  widget.onUnreadCountChanged?.call(updatedState.unreadCount);
} catch (error) {
  _showError(error);
}

}

void _showError(Object error) {
if (!mounted) {
return;
}

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      error.toString(),
    ),
  ),
);

}

@override
Widget build(BuildContext context) {
final state = _state;

return Scaffold(
  appBar: AppBar(
    title: const Text('Notifications'),
    actions: [
      if ((state?.unreadCount ?? 0) > 0)
        TextButton(
          onPressed: _markAllAsRead,
          child: const Text('Mark all as read'),
        ),
    ],
  ),
  body: _buildBody(),
);

}

Widget _buildBody() {
if (_isLoading) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (_error != null) {
  return _buildErrorState();
}

final state = _state;

if (state == null || state.notifications.isEmpty) {
  return _buildEmptyState();
}

return RefreshIndicator(
  onRefresh: _loadNotifications,
  child: ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: state.notifications.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final notification = state.notifications[index];

      return _NotificationCard(
        notification: notification,
        isRead: state.isRead(notification.id),
        onTap: () => _markAsRead(notification),
      );
    },
  ),
);

}

Widget _buildEmptyState() {
return const Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.notifications_none_rounded,
size: 48,
),
SizedBox(height: 12),
Text(
'No notifications yet',
),
],
),
);
}

Widget _buildErrorState() {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline_rounded,
size: 48,
),
const SizedBox(height: 12),
const Text(
'Unable to load notifications.',
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
Text(
_error.toString(),
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
ElevatedButton(
onPressed: _loadNotifications,
child: const Text('Retry'),
),
],
),
),
);
}
}

class _NotificationCard extends StatelessWidget {
final AppNotification notification;
final bool isRead;
final VoidCallback onTap;

const _NotificationCard({
required this.notification,
required this.isRead,
required this.onTap,
});

IconData get _icon {
switch (notification.type) {
case 'market_alert':
return Icons.trending_up_rounded;
case 'news':
return Icons.article_outlined;
case 'system':
return Icons.info_outline_rounded;
default:
return Icons.notifications_none_rounded;
}
}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

return Card(
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  notification.createdAt.toLocal().toString(),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

}
}