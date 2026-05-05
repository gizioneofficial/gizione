// lib/features/home/screens/home_screen.dart
//
// Screen 1 — Home
// Shows the GiziOne logo + two large feature cards:
//   • Identifikasi Gizi Makanan  → navigates to ScanScreen
//   • Rekomendasi Makanan        → navigates to RecommendScreen

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/gizione_logo.dart';
// import '../../scan/screens/scan_screen.dart';
// import '../../recommend/screens/recommend_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // ── Logo ──────────────────────────────────────
              const GiziOneLogo(),

              const SizedBox(height: 48),

              // ── Card 1: Identifikasi Gizi Makanan ─────────
              _FeatureCard(
                emoji:
                    '🥧', // pie-chart feel — swap for an Image.asset if you have one
                label: 'Identifikasi\nGizi Makanan',
                onTap: () {
                  Navigator.pushNamed(context, '/scan');
                  // or with GoRouter: context.push('/scan');
                },
              ),

              const SizedBox(height: 24),

              // ── Card 2: Rekomendasi Makanan ────────────────
              _FeatureCard(
                emoji: '🍽️',
                label: 'Rekomendasi\nMakanan',
                onTap: () {
                  Navigator.pushNamed(context, '/recommend');
                  // or with GoRouter: context.push('/recommend');
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable large feature card ────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon area ────────────────────────────────────
            // Replace with Image.asset('assets/icons/xxx.png') once you
            // have the actual PNG assets from your design.
            Text(emoji, style: const TextStyle(fontSize: 72)),

            const SizedBox(height: 16),

            // ── Label ─────────────────────────────────────────
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
          ],
        ),
      ),
    );
  }
}
