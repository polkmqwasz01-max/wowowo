import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../screens/main_screen.dart';
// 1. Import file splash screen yang udah dibuat sebelumnya
// (Sesuaikan path import-nya kalau foldernya beda)
import '../../screens/splash_screen.dart'; 

class AppRouter {
  AppRouter._();

  // 2. Tambahkan konstanta rute untuk splash screen
  static const String splash = '/splash';
  static const String mainScreen = '/';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AppSettings appSettings,
  ) {
    switch (settings.name) {
      // 3. Tambahkan case untuk rute splash dan atur sebagai halaman awal
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case mainScreen:
        return MaterialPageRoute(
          builder: (_) => MainScreen(
            appSettings: appSettings,
          ),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => MainScreen(
            appSettings: appSettings,
          ),
          settings: const RouteSettings(
            name: mainScreen,
          ),
        );
    }
  }
}