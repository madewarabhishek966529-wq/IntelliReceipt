import 'package:flutter/material.dart';

/// Brand palette. Kept separate from [ThemeData] so widgets can reference
/// semantic colors (e.g. price-up red) that Material's ColorScheme doesn't
/// model directly.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF5B5BF6);
  static const Color primaryDark = Color(0xFF4340C4);
  static const Color secondary = Color(0xFF00C9A7);
  static const Color accent = Color(0xFFFFB020);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF7F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0F0F17);
  static const Color darkSurface = Color(0xFF1A1A26);
  static const Color darkCard = Color(0xFF20202E);

  // Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFEF4444);
  static const Color priceUp = Color(0xFFEF4444);
  static const Color priceDown = Color(0xFF2ECC71);
  static const Color priceStable = Color(0xFF9CA3AF);

  // Category badge colors
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF7A59),
    'Groceries': Color(0xFF2ECC71),
    'Medicine': Color(0xFF5B5BF6),
    'Electronics': Color(0xFF3B82F6),
    'Personal Care': Color(0xFFEC4899),
    'Others': Color(0xFF9CA3AF),
  };

  // Glassmorphism gradient
  static const List<Color> glassGradient = [
    Color(0x33FFFFFF),
    Color(0x0DFFFFFF),
  ];

  static const List<Color> primaryGradient = [
    Color(0xFF5B5BF6),
    Color(0xFF8B7CF6),
  ];
}
