// lib/core/constants/app_colors.dart
// Extracted from the GiziOne design mockups

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF5B8A3C); // "Gizi" text green
  static const Color primaryOrange = Color(0xFFE8963A); // "One" text orange
  static const Color accentRed = Color(0xFFD94F3D); // tomato on logo

  // ── Background ────────────────────────────────────────────
  static const Color background = Color(0xFFF2F2F2); // light grey bg
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFFFB3B3); // pinkish border on cards

  // ── Text ──────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF666666);
  static const Color textGreen = Color(0xFF5B8A3C); // section titles

  // ── Nutrient chip colours (from scan result screen) ───────
  static const Color chipCalorie = Color(0xFFB5D99C); // green
  static const Color chipFat = Color(0xFFE8C07A); // orange/amber
  static const Color chipSugar = Color(0xFFD4AADC); // purple/lavender
  static const Color chipProtein = Color(0xFFADD8E6); // light blue
  static const Color chipSalt = Color(0xFFFFF176); // yellow

  // ── Recommendation chip colours ───────────────────────────
  static const Color recChip = Color(0xFFD4EDBA); // soft green

  // ── Misc ──────────────────────────────────────────────────
  static const Color scanOverlay = Color(0x55000000);
  static const Color captureBtn = Color(0xFF5B8A3C);
  static const Color filterChip = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFE0E0E0);
}
