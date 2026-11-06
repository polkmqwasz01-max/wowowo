import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color card;
  final Color elevated;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color bearish;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.elevated,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.bearish,
  });

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? elevated,
    Color? border,
    Color? primaryText,
    Color? secondaryText,
    Color? accent,
    Color? bearish,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      accent: accent ?? this.accent,
      bearish: bearish ?? this.bearish,
    );
  }

  @override
  AppThemeColors lerp(
    covariant ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText:
          Color.lerp(secondaryText, other.secondaryText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      bearish: Color.lerp(bearish, other.bearish, t)!,
    );
  }
}
