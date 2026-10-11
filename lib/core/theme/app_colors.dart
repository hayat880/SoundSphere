import 'package:flutter/material.dart';

/// Palette taken from the SoundSphere logo.
class AppColors {
  // Light screens
  static const Color cream = Color(0xFFF5EDDC);
  static const Color card = Color(0xFFFBF6EA);
  static const Color forest = Color(0xFF1A2D20);
  static const Color moss = Color(0xFF56604A);
  static const Color border = Color(0xFFD6C9AA);
  static const Color chip = Color(0xFFE8DDC3);

  // Dark screens
  static const Color darkBg = Color(0xFF17261C);
  static const Color darkCard = Color(0xFF1F3326);
  static const Color darkCard2 = Color(0xFF284030);
  static const Color darkBorder = Color(0xFF2C4232);
  static const Color sage = Color(0xFFB5BCA4);

  // Accents
  static const Color terracotta = Color(0xFFCE7B4A);
  static const Color olive = Color(0xFF6B8F47);

  static const List<Color> _art = [
    Color(0xFF2B4A32),
    Color(0xFF4F7A4C),
    Color(0xFFB8683E),
    Color(0xFF6B8F47),
    Color(0xFFC9A24A),
    Color(0xFF7A5A3E),
    Color(0xFF4C7A6A),
  ];

  /// Picks a stable album-art colour from a song title.
  static Color artFor(String key) {
    final sum = key.codeUnits.fold<int>(0, (a, b) => a + b);
    return _art[sum % _art.length];
  }
}
