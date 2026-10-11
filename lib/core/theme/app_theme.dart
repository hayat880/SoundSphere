import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  /// The design uses the Outfit font. If the font files are not added to the
  /// project (see the build guide), Flutter simply uses the default font.
  static const String fontFamily = 'Outfit';

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: AppColors.cream,
        text: AppColors.forest,
        surface: AppColors.card,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: AppColors.darkBg,
        text: AppColors.cream,
        surface: AppColors.darkCard,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color text,
    required Color surface,
  }) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: fontFamily,
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.terracotta,
        brightness: brightness,
      ).copyWith(
        primary: AppColors.terracotta,
        onPrimary: AppColors.forest,
        surface: surface,
        onSurface: text,
      ),
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.forest,
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          side: BorderSide(color: text.withAlpha(90)),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.terracotta,
        thumbColor: AppColors.terracotta,
      ),
    );
  }
}
