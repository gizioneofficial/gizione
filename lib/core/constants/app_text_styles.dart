// lib/core/constants/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Logo ──────────────────────────────────────────────────
  static const TextStyle logoGizi = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w800,
    fontSize: 42,
    color: AppColors.primaryGreen,
    height: 1.0,
  );
  static const TextStyle logoOne = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w800,
    fontSize: 42,
    color: AppColors.primaryOrange,
    height: 1.0,
  );
  static const TextStyle logoTagline = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: AppColors.primaryGreen,
  );

  // ── Page titles ───────────────────────────────────────────
  static const TextStyle pageTitle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w800,
    fontSize: 26,
    color: AppColors.textDark,
  );

  // ── Section labels ────────────────────────────────────────
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textGreen,
  );

  // ── Card title ────────────────────────────────────────────
  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
    fontSize: 20,
    color: AppColors.textDark,
  );

  // ── Body ──────────────────────────────────────────────────
  static const TextStyle body = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textGrey,
  );
  static const TextStyle bodyBold = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.textDark,
  );

  // ── Nutrient chip ─────────────────────────────────────────
  static const TextStyle chipLabel = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: AppColors.textDark,
  );
  static const TextStyle chipValue = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w800,
    fontSize: 22,
    color: AppColors.textDark,
  );
  static const TextStyle chipUnit = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w800,
    fontSize: 13,
    color: AppColors.textDark,
  );
  static const TextStyle chipLevel = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    color: AppColors.textDark,
  );

  // ── Recommendation card ───────────────────────────────────
  static const TextStyle recFoodName = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: AppColors.textDark,
  );
  static const TextStyle recChipLabel = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    fontSize: 11,
    color: AppColors.textDark,
  );
  static const TextStyle recChipValue = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
    fontSize: 13,
    color: AppColors.textDark,
  );

  // ── Hint / caption ────────────────────────────────────────
  static const TextStyle hint = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: AppColors.textGrey,
  );
}
