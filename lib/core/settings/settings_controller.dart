import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;

  bool get notificationsEnabled => _notificationsEnabled;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();
  }

  void setDarkMode(bool enabled) {
    setThemeMode(
      enabled ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void setNotificationsEnabled(bool enabled) {
    if (_notificationsEnabled == enabled) return;

    _notificationsEnabled = enabled;
    notifyListeners();
  }
}
