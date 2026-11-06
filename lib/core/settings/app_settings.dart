import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _languageKey = 'language';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _notificationsEnabled = true;
  String _language = 'en';

  SharedPreferences? _preferences;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get notificationsEnabled => _notificationsEnabled;

  String get language => _language;

  Locale get locale => Locale(_language);

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();

    final savedThemeMode = _preferences!.getString(_themeModeKey);

    _themeMode = savedThemeMode == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;

    _notificationsEnabled =
        _preferences!.getBool(_notificationsKey) ?? true;

    final savedLanguage = _preferences!.getString(_languageKey);

    _language = savedLanguage == 'id' ? 'id' : 'en';
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;

    await _preferences?.setString(
      _themeModeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );

    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) {
      return;
    }

    _notificationsEnabled = enabled;

    await _preferences?.setBool(
      _notificationsKey,
      enabled,
    );

    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (language != 'en' && language != 'id') {
      return;
    }

    if (_language == language) {
      return;
    }

    _language = language;

    await _preferences?.setString(
      _languageKey,
      language,
    );

    notifyListeners();
  }
}
