import 'package:flutter/material.dart';

import '../controllers/notification_controller.dart';
import '../core/settings/app_settings.dart';
import 'market_overview_screen.dart';
import 'news_feed_screen.dart';
import 'notification_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
final AppSettings appSettings;

const MainScreen({
super.key,
required this.appSettings,
});

@override
State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
final NotificationController _notificationController =
NotificationController();

int _currentIndex = 0;
int _unreadNotificationCount = 0;

@override
void initState() {
super.initState();
_loadUnreadNotificationCount();
}

List<Widget> _buildPages() {
return [
NewsFeedScreen(onTabSelected: _onTabTapped,),
const SearchScreen(),
const MarketOverviewScreen(),
SettingsScreen(
appSettings: widget.appSettings,
),
];
}

Future<void> _loadUnreadNotificationCount() async {
try {
final state = await _notificationController.load();

  if (!mounted) {
    return;
  }

  if (_unreadNotificationCount == state.unreadCount) {
    return;
  }

  setState(() {
    _unreadNotificationCount = state.unreadCount;
  });
} catch (_) {
  // Notification badge must never block the main application.
}

}

void _onUnreadCountChanged(int count) {
if (!mounted) {
return;
}

if (_unreadNotificationCount == count) {
  return;
}

setState(() {
  _unreadNotificationCount = count;
});

}

Future<void> _openNotifications() async {
await Navigator.of(context).push(
MaterialPageRoute<void>(
builder: (context) {
return NotificationScreen(
onUnreadCountChanged: _onUnreadCountChanged,
);
},
),
);

if (!mounted) {
  return;
}

await _loadUnreadNotificationCount();

}

Widget _buildNotificationIcon(BuildContext context) {
final colorScheme = Theme.of(context).colorScheme;

final icon = Icon(
  _unreadNotificationCount > 0
      ? Icons.notifications_rounded
      : Icons.notifications_none_rounded,
  color: colorScheme.onSurfaceVariant,
);

if (_unreadNotificationCount <= 0) {
  return icon;
}

return Badge(
  backgroundColor: colorScheme.error,
  textColor: colorScheme.onError,
  alignment: AlignmentDirectional.topEnd,
  offset: const Offset(3, -3),
  padding: const EdgeInsets.symmetric(
    horizontal: 5,
    vertical: 2,
  ),
  label: Text(
    _unreadNotificationCount > 99
        ? '99+'
        : _unreadNotificationCount.toString(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
  ),
  child: icon,
);

}

void _onTabTapped(int index) {
if (_currentIndex == index) {
return;
}

setState(() {
  _currentIndex = index;
});

}

@override
Widget build(BuildContext context) {
return LayoutBuilder(
builder: (context, constraints) {
final isDesktop = constraints.maxWidth >= 900;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }

    return _buildMobileLayout(context);
  },
);

}

Widget _buildDesktopLayout(BuildContext context) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

final backgroundColor = theme.scaffoldBackgroundColor;
final surfaceColor = colorScheme.surface;
final secondaryTextColor = colorScheme.onSurfaceVariant;

return Scaffold(
  backgroundColor: backgroundColor,
  body: Column(
    children: [
      Container(
        height: 68,
        decoration: BoxDecoration(
          color: surfaceColor,
        ),
        child: Row(
          children: [
            const SizedBox(width: 28),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            Row(
              children: [
                Text(
                  'CRIP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'CHECK',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: colorScheme.primary,
                      size: 5,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'INTELLIGENCE HUB',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 48),

            _buildDesktopNavItem(
              context: context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              index: 0,
            ),

            _buildDesktopNavItem(
              context: context,
              icon: Icons.search_outlined,
              activeIcon: Icons.search,
              label: 'Search',
              index: 1,
            ),

            _buildDesktopNavItem(
              context: context,
              icon: Icons.show_chart_outlined,
              activeIcon: Icons.show_chart,
              label: 'Market',
              index: 2,
            ),

            _buildDesktopNavItem(
              context: context,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Setting',
              index: 3,
            ),

            const Spacer(),

            IconButton(
              tooltip: 'Notifications',
              onPressed: _openNotifications,
              icon: _buildNotificationIcon(context),
            ),

            const SizedBox(width: 10),

            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.download,
                color: secondaryTextColor,
                size: 19,
              ),
            ),

            const SizedBox(width: 28),
          ],
        ),
      ),

      Expanded(
        child: IndexedStack(
          index: _currentIndex,
          children: _buildPages(),
        ),
      ),
    ],
  ),
);

}

Widget _buildDesktopNavItem({
required BuildContext context,
required IconData icon,
required IconData activeIcon,
required String label,
required int index,
}) {
final colorScheme = Theme.of(context).colorScheme;
final selected = _currentIndex == index;

return Padding(
  padding: const EdgeInsets.only(right: 8),
  child: InkWell(
    onTap: () => _onTabTapped(index),
    borderRadius: BorderRadius.circular(10),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? activeIcon : icon,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ),
);

}

Widget _buildMobileLayout(BuildContext context) {
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

return Scaffold(
  backgroundColor: theme.scaffoldBackgroundColor,
  body: IndexedStack(
    index: _currentIndex,
    children: _buildPages(),
  ),
  bottomNavigationBar: Container(
    decoration: BoxDecoration(
      color: colorScheme.surface,
    ),
    child: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart_outlined),
          activeIcon: Icon(Icons.show_chart),
          label: 'Market',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Setting',
        ),
      ],
    ),
  ),
);

}
}