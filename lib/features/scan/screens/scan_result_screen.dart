// lib/features/scan/screens/scan_result_screen.dart
//
// Screen 3 — Klasifikasi Gizi
// Shows scanned food name + 5 coloured nutrient chips + overall health rating.
// Spec 4: displayed on ONE screen, max 1 transition from scan_screen.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/gizione_logo.dart';
import '../../../models/nutrition_model.dart';

class ScanResultScreen extends StatelessWidget {
  final NutritionModel nutrition;
  final Uint8List? imageBytes; // thumbnail of the scanned food

  const ScanResultScreen({super.key, required this.nutrition, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Logo ────────────────────────────────────────
              Center(child: const GiziOneLogo(scale: 0.65)),

              const SizedBox(height: 20),

              // ── Page title ──────────────────────────────────
              Center(
                child: Text('Klasifikasi Gizi', style: AppTextStyles.pageTitle),
              ),

              const SizedBox(height: 20),

              // ── Food name card ──────────────────────────────
              _FoodNameCard(
                foodName: nutrition.foodName,
                imageBytes: imageBytes,
              ),

              const SizedBox(height: 24),

              // ── Section: Ringkasan Gizi ─────────────────────
              Text('Ringkasan Gizi', style: AppTextStyles.sectionLabel),

              const SizedBox(height: 12),

              // ── 5-nutrient chip grid ─────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _NutrientGrid(nutrition: nutrition),
              ),

              const SizedBox(height: 24),

              // ── Section: Klasifikasi Keseluruhan ─────────────
              Text(
                'Klasifikasi Keseluruhan',
                style: AppTextStyles.sectionLabel,
              ),

              const SizedBox(height: 12),

              // ── Health rating card ───────────────────────────
              _HealthRatingCard(nutrition: nutrition),

              const SizedBox(height: 32),

              // ── Back button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: AppTextStyles.bodyBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Scan Makanan Lain'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Food name card (top banner with optional thumbnail) ───────────────────

class _FoodNameCard extends StatelessWidget {
  final String foodName;
  final Uint8List? imageBytes;

  const _FoodNameCard({required this.foodName, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          // ── Thumbnail ────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageBytes != null
                ? Image.memory(
                    imageBytes!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: AppColors.background,
                    child: const Center(
                      child: Text('🍽️', style: TextStyle(fontSize: 28)),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // ── Food name ────────────────────────────────────────
          Expanded(child: Text(foodName, style: AppTextStyles.cardTitle)),
        ],
      ),
    );
  }
}

// ── Grid of 5 nutrient chips (3 top row, 2 bottom row centred) ────────────

class _NutrientGrid extends StatelessWidget {
  final NutritionModel nutrition;
  const _NutrientGrid({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final n = nutrition.nutrients;

    // Build level label based on rough thresholds
    String calorieLevel = _level(n.calories.value, 300, 500);
    String fatLevel = _level(n.fat.value, 10, 20);
    String sugarLevel = _level(n.sugar.value, 10, 25);
    String proteinLevel = _level(n.protein.value, 15, 30, reversed: true);
    String saltLevel = _level(n.salt.value, 600, 1200);

    return Column(
      children: [
        // Top row — 3 chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NutrientChip(
              label: 'Kalori',
              value: '${n.calories.value.toStringAsFixed(0)}',
              unit: n.calories.unit,
              level: calorieLevel,
              color: AppColors.chipCalorie,
            ),
            _NutrientChip(
              label: 'Lemak',
              value: '${n.fat.value.toStringAsFixed(0)}',
              unit: n.fat.unit,
              level: fatLevel,
              color: AppColors.chipFat,
            ),
            _NutrientChip(
              label: 'Gula',
              value: '${n.sugar.value.toStringAsFixed(0)}',
              unit: n.sugar.unit,
              level: sugarLevel,
              color: AppColors.chipSugar,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row — 2 chips, centred
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NutrientChip(
              label: 'Protein',
              value: '${n.protein.value.toStringAsFixed(0)}',
              unit: n.protein.unit,
              level: proteinLevel,
              color: AppColors.chipProtein,
            ),
            const SizedBox(width: 16),
            _NutrientChip(
              label: 'Garam',
              value: _formatSalt(n.salt.value),
              unit: n.salt.unit == 'mg' ? 'g' : n.salt.unit,
              level: saltLevel,
              color: AppColors.chipSalt,
            ),
          ],
        ),
      ],
    );
  }

  // Convert mg → g for display (e.g. 1100 mg → "1,1 g")
  String _formatSalt(double mg) {
    final g = mg / 1000;
    return g.toStringAsFixed(1).replaceAll('.', ',');
  }

  // Low / Sedang / Tinggi classification
  String _level(double v, double low, double high, {bool reversed = false}) {
    if (reversed) {
      if (v >= high) return 'Tinggi';
      if (v >= low) return 'Sedang';
      return 'Rendah';
    }
    if (v <= low) return 'Rendah';
    if (v <= high) return 'Sedang';
    return 'Tinggi';
  }
}

// ── Single nutrient chip (pill shape) ─────────────────────────────────────

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String level;
  final Color color;

  const _NutrientChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.chipLabel),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.chipValue),
          Text(unit, style: AppTextStyles.chipUnit),
          const SizedBox(height: 4),
          Text(level, style: AppTextStyles.chipLevel),
        ],
      ),
    );
  }
}

// ── Overall health rating card ────────────────────────────────────────────

class _HealthRatingCard extends StatelessWidget {
  final NutritionModel nutrition;
  const _HealthRatingCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nutrition.healthLabel, // extension from NutritionModel
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 6),
          Text(nutrition.healthierNote, style: AppTextStyles.body),
          const SizedBox(height: 12),
          // ── Star rating ────────────────────────────────────
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < nutrition.healthRating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: AppColors.primaryOrange,
                size: 22,
              );
            }),
          ),
        ],
      ),
    );
  }
}
