import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';

import 'core/theme/app_theme_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

final appSettings = AppSettings();

await appSettings.load();

runApp(
  CripCheckApp(
    appSettings: appSettings,
  ),
);

}

class CripCheckApp extends StatelessWidget {
  final AppSettings appSettings;

  const CripCheckApp({
    super.key,
    required this.appSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        return MaterialApp(
  title: 'CripCheck',
  debugShowCheckedModeBanner: false,
  themeMode: appSettings.themeMode,
  locale: appSettings.locale,
  theme: _buildLightTheme(),
  darkTheme: _buildDarkTheme(),
  initialRoute: AppRouter.splash,
  onGenerateRoute: (settings) {
    return AppRouter.onGenerateRoute(
      settings,
      appSettings,
    );
  },
);
      },
    );
  }

ThemeData _buildDarkTheme() {
  const background = Color(0xFF0D0F12);
  const surface = Color(0xFF15181D);
  const card = Color(0xFF1B1F25);
  const elevated = Color(0xFF20252C);
  const border = Color(0xFF2A3038);
  const secondaryText = Color(0xFF9AA3AE);

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    cardColor: card,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E676),
      secondary: Color(0xFF00E676),
      surface: surface,
      error: Color(0xFFFF5252),
      onPrimary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    dividerColor: border,
    extensions: const [
      AppThemeColors(
        background: background,
        surface: surface,
        card: card,
        elevated: elevated,
        border: border,
        primaryText: Colors.white,
        secondaryText: secondaryText,
        accent: Color(0xFF00E676),
        bearish: Color(0xFFFF5252),
      ),
    ],
  );
}

ThemeData _buildLightTheme() {
  const background = Color(0xFFF5F7FA);
  const surface = Colors.white;
  const card = Colors.white;
  const elevated = Color(0xFFEFF2F5);
  const border = Color(0xFFD9DEE5);
  const primaryText = Color(0xFF15181D);
  const secondaryText = Color(0xFF66707C);

  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    cardColor: card,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00A95C),
      secondary: Color(0xFF00A95C),
      surface: surface,
      error: Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSurface: primaryText,
      onError: Colors.white,
    ),
    dividerColor: border,
    extensions: const [
      AppThemeColors(
        background: background,
        surface: surface,
        card: card,
        elevated: elevated,
        border: border,
        primaryText: primaryText,
        secondaryText: secondaryText,
        accent: Color(0xFF00A95C),
        bearish: Color(0xFFD32F2F),
      ),
    ],
  );
}
}
