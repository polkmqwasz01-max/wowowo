import 'package:flutter/material.dart';

import '../core/settings/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettings appSettings;

  const SettingsScreen({
    super.key,
    required this.appSettings,
  });

  static const backgroundColor = Color(0xFF0D0F12);
  static const surfaceColor = Color(0xFF15181D);
  static const cardColor = Color(0xFF191D23);
  static const elevatedColor = Color(0xFF20252C);
  static const borderColor = Color(0xFF292F37);

  static const primaryTextColor = Colors.white;
  static const secondaryTextColor = Color(0xFF929BA7);
  static const tertiaryTextColor = Color(0xFF68717D);

  static const accentColor = Color(0xFF00E676);

  static const lightBackgroundColor = Color(0xFFF5F7FA);
  static const lightCardColor = Colors.white;
  static const lightBorderColor = Color(0xFFE1E5EA);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final isDark = appSettings.isDarkMode;

        return Scaffold(
          backgroundColor: isDark
              ? backgroundColor
              : lightBackgroundColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth >= 900 ? 32.0 : 18.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 900,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isDark),
                          const SizedBox(height: 34),
                          _buildSection(
                            title: 'PREFERENCES',
                            subtitle:
                                'Customize your CripCheck experience',
                            isDark: isDark,
                            children: [
                              _buildThemeTile(isDark),
                              _buildDivider(isDark),
                              _buildLanguageTile(isDark),
                              _buildDivider(isDark),
                              _buildNotificationTile(isDark),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildSection(
                            title: 'ABOUT',
                            subtitle:
                                'Application information',
                            isDark: isDark,
                            children: [
                              _buildAboutTile(context, isDark),
                              _buildDivider(isDark),
                              _buildVersionTile(isDark),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildSection(
                            title: 'SUPPORT',
                            subtitle:
                                'Help improve CripCheck',
                            isDark: isDark,
                            children: [
                              _buildFeedbackTile(context, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

Widget _buildHeader(bool isDark) {
  final accent = isDark ? accentColor : const Color(0xFF00A844);
  final primaryText = isDark ? primaryTextColor : const Color(0xFF15181D);

  return Row(
    children: [
      // Branding Icon Badge
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          Icons.tune_rounded,
          color: accent,
          size: 22,
        ),
      ),
      const SizedBox(width: 14),

      // Typography Title & Status
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'SYSTEM ',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: accent,
                  size: 5,
                ),
                const SizedBox(width: 4),
                Text(
                  'CRIPCHECK APPLICATION',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildSection({
  required String title,
  required String subtitle,
  required bool isDark,
  required List<Widget> children,
}) {
  final radius = BorderRadius.circular(16);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: isDark
              ? primaryTextColor
              : const Color(0xFF15181D),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: TextStyle(
          color: isDark
              ? tertiaryTextColor
              : const Color(0xFF68717D),
          fontSize: 10,
        ),
      ),
      const SizedBox(height: 12),
      Material(
        color: isDark ? cardColor : lightCardColor,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: isDark
                  ? borderColor
                  : lightBorderColor,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ),
    ],
  );
}

  Widget _buildThemeTile(bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      leading: _buildIconContainer(
        Icons.palette_outlined,
        isDark,
      ),
      title: _buildTitle(
        'Appearance',
        isDark,
      ),
      subtitle: _buildSubtitle(
        isDark
            ? 'Dark theme is currently active'
            : 'Light theme is currently active',
        isDark,
      ),
      trailing: _buildThemeSelector(isDark),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? surfaceColor
            : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isDark
              ? borderColor
              : lightBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(
            label: 'Dark',
            mode: ThemeMode.dark,
            selected: appSettings.themeMode == ThemeMode.dark,
            isDark: isDark,
          ),
          _buildThemeOption(
            label: 'Light',
            mode: ThemeMode.light,
            selected: appSettings.themeMode == ThemeMode.light,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required ThemeMode mode,
    required bool selected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => appSettings.setThemeMode(mode),
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? isDark
                  ? elevatedColor
                  : Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? isDark
                    ? primaryTextColor
                    : const Color(0xFF15181D)
                : isDark
                    ? secondaryTextColor
                    : const Color(0xFF68717D),
            fontSize: 10,
            fontWeight:
                selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      leading: _buildIconContainer(
        Icons.language_rounded,
        isDark,
      ),
      title: _buildTitle('Language', isDark),
      subtitle: _buildSubtitle(
        appSettings.language == 'id'
            ? 'Bahasa Indonesia'
            : 'English',
        isDark,
      ),
      trailing: _buildLanguageSelector(isDark),
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: appSettings.language,
        dropdownColor:
            isDark ? elevatedColor : Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: isDark
              ? secondaryTextColor
              : const Color(0xFF68717D),
          size: 18,
        ),
        style: TextStyle(
          color: isDark
              ? primaryTextColor
              : const Color(0xFF15181D),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        items: const [
          DropdownMenuItem(
            value: 'en',
            child: Text('English'),
          ),
          DropdownMenuItem(
            value: 'id',
            child: Text('Indonesia'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            appSettings.setLanguage(value);
          }
        },
      ),
    );
  }

  Widget _buildNotificationTile(bool isDark) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      secondary: _buildIconContainer(
        Icons.notifications_none_rounded,
        isDark,
      ),
      title: _buildTitle(
        'Notifications',
        isDark,
      ),
      subtitle: _buildSubtitle(
        'Market and news updates',
        isDark,
      ),
      value: appSettings.notificationsEnabled,
      activeThumbColor: accentColor,
      onChanged: appSettings.setNotificationsEnabled,
    );
  }

Widget _buildAboutTile(
  BuildContext context,
  bool isDark,
) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      leading: _buildIconContainer(
        Icons.info_outline_rounded,
        isDark,
      ),
      title: _buildTitle(
        'About CripCheck',
        isDark,
      ),
      subtitle: _buildSubtitle(
        'Crypto analytics and intelligence',
        isDark,
      ),
      trailing: _buildArrow(isDark),
onTap: () => _showAboutDialog(
  context,
  isDark,
),
    );
  }

  Widget _buildVersionTile(bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      leading: _buildIconContainer(
        Icons.verified_outlined,
        isDark,
      ),
      title: _buildTitle(
        'App Version',
        isDark,
      ),
      trailing: Text(
        'v1.0.0',
        style: TextStyle(
          color: isDark
              ? secondaryTextColor
              : const Color(0xFF68717D),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

Widget _buildFeedbackTile(
  BuildContext context,
  bool isDark,
) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      leading: _buildIconContainer(
        Icons.mail_outline_rounded,
        isDark,
      ),
      title: _buildTitle(
        'Give Feedback',
        isDark,
      ),
      subtitle: _buildSubtitle(
        'Share your thoughts about CripCheck',
        isDark,
      ),
      trailing: _buildArrow(isDark),
      onTap: () => _showFeedbackDialog(
        context,
        isDark),
    );
  }

  Widget _buildIconContainer(
    IconData icon,
    bool isDark,
  ) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? elevatedColor
            : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: isDark
            ? primaryTextColor
            : const Color(0xFF39414A),
        size: 19,
      ),
    );
  }

  Widget _buildTitle(
    String text,
    bool isDark,
  ) {
    return Text(
      text,
      style: TextStyle(
        color: isDark
            ? primaryTextColor
            : const Color(0xFF15181D),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubtitle(
    String text,
    bool isDark,
  ) {
    return Text(
      text,
      style: TextStyle(
        color: isDark
            ? secondaryTextColor
            : const Color(0xFF68717D),
        fontSize: 10,
      ),
    );
  }

  Widget _buildArrow(bool isDark) {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      color: isDark
          ? secondaryTextColor
          : const Color(0xFF68717D),
      size: 13,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? borderColor
          : lightBorderColor,
    );
  }

void _showAboutDialog(
  BuildContext context,
  bool isDark,
) {
  showAboutDialog(
    context: context,
    applicationName: 'CripCheck',
    applicationVersion: 'v1.0.0',
    // Menambahkan catatan hak cipta / legalese (opsional)
    applicationLegalese: '© 2026 CripCheck Inc. All rights reserved.',
    applicationIcon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: const Icon(
        Icons.bolt_rounded,
        color: accentColor,
        size: 32,
      ),
    ),
    children: const [
      SizedBox(height: 12),
      Text(
        'CripCheck is a crypto analytics and news tracking application providing automated market intelligence, news generation, and sentiment analysis.',
        style: TextStyle(fontSize: 13),
      ),
    ],
  );
}

void _showFeedbackDialog(
  BuildContext context,
  bool isDark,
) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? elevatedColor : Colors.white,
          title: Text(
            'Give Feedback',
            style: TextStyle(
              color: isDark
                  ? primaryTextColor
                  : const Color(0xFF15181D),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Feedback submission will be connected to the preferred email service later.',
            style: TextStyle(
              color: isDark
                  ? secondaryTextColor
                  : const Color(0xFF68717D),
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
