import 'package:flutter/material.dart';

class AppColors {
  // Brand Emerald Palette
  static const Color primary = Color(0xFF0B5D45); // Deep emerald brand
  static const Color primaryLight = Color(0xFF157B5D);
  static const Color primaryDark = Color(0xFF073D2D);
  static const Color primaryContainer = Color(0xFFD6EDE4);
  static const Color onPrimaryContainer = Color(0xFF063A2B);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF5F9F7); // Premium mint-tinted off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFECF3F0);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Text & Content
  static const Color textPrimary = Color(0xFF0D1D17);
  static const Color textSecondary = Color(0xFF4A6359);
  static const Color textTertiary = Color(0xFF7A948A);

  // Accents & Habit Feedback
  static const Color streakOrange = Color(0xFFF97316); // Streak fire
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFDEE9E4);
  static const Color divider = Color(0xFFE8F0EC);

  // Gradients
  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B5D45),
      Color(0xFF167F5F),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF7FAF8),
    ],
  );

  static const LinearGradient streakGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF97316),
      Color(0xFFFB923C),
    ],
  );
}
