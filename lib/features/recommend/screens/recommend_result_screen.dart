// lib/features/recommend/screens/recommend_result_screen.dart
//
// Screen 4 — Rekomendasi Makanan (Results)
// Shows the header banner + ≥3 recommendation cards, each with
// food name, image placeholder, and 4 nutrient mini-chips.
// Spec 5: ≥3 options  |  Spec 6: already handled by ClaudeService timeout.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/gizione_logo.dart';
import '../../../models/recommendation_model.dart';
import '../../../services/claude_service.dart';

class RecommendResultScreen extends StatefulWidget {
  final List<RecommendationModel> recommendations;
  final String situation;

  const RecommendResultScreen({
    super.key,
    required this.recommendations,
    required this.situation,
  });

  @override
  State<RecommendResultScreen> createState() => _RecommendResultScreenState();
}

class _RecommendResultScreenState extends State<RecommendResultScreen> {
  late List<RecommendationModel> _items;
  bool _isRefreshing = false;
  final _claude = ClaudeService();

  @override
  void initState() {
    super.initState();
    _items = widget.recommendations;
  }

  // Refresh: call Claude again with same situation
  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      final fresh = await _claude.getRecommendations(
        situation: widget.situation,
        language: 'id',
      );
      if (mounted) setState(() => _items = fresh);
    } on ClaudeServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Fixed header ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const GiziOneLogo(scale: 0.65),
                    const SizedBox(height: 20),
                    Text(
                      'Rekomendasi\nMakanan',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 20),

                    // ── Context banner ───────────────────────
                    _ContextBanner(situation: widget.situation),

                    const SizedBox(height: 16),

                    // ── Filter row ───────────────────────────
                    Row(
                      children: [
                        _FilterChip(
                          onTap: _isRefreshing ? null : _refresh,
                          isLoading: _isRefreshing,
                        ),
                        const Spacer(),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Count label ──────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_items.length} Rekomendasi untukmu',
                        style: AppTextStyles.sectionLabel,
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Recommendation cards list ────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _items.length) {
                      return const SizedBox(height: 32);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RecommendationCard(item: _items[index]),
                    );
                  },
                  childCount: _items.length + 1, // +1 for bottom padding
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Context banner (top pink card) ────────────────────────────────────────

class _ContextBanner extends StatelessWidget {
  final String situation;
  const _ContextBanner({required this.situation});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilihan makanan sehat lain',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Berdasarkan kebutuhan dan gizi\ndan preferensi kamu',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('🥗', style: TextStyle(fontSize: 44)),
        ],
      ),
    );
  }
}

// ── Filter chip with refresh ───────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  const _FilterChip({this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.filterChip,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              )
            else
              const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.textDark,
              ),
            const SizedBox(width: 6),
            Text('Filter', style: AppTextStyles.chipLabel),
          ],
        ),
      ),
    );
  }
}

// ── Single recommendation card ────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final RecommendationModel item;
  const _RecommendationCard({required this.item});

  // Food emoji map — replace with Image.asset when you have icons
  String _emojiFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('salad')) return '🥗';
    if (lower.contains('ayam')) return '🍗';
    if (lower.contains('nasi')) return '🍚';
    if (lower.contains('tempe')) return '🫘';
    if (lower.contains('tahu')) return '🟨';
    if (lower.contains('gado')) return '🥜';
    if (lower.contains('sup')) return '🍲';
    if (lower.contains('buah')) return '🍉';
    if (lower.contains('capcai')) return '🥦';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    // We show 4 mini nutrient chips: Kalori, Lemak, Protein, Garam
    // For recommendations we only have estimated_calories from Claude.
    // The other 3 show placeholder dashes unless you extend the schema.
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Food image / emoji ──────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _emojiFor(item.foodName),
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ── Name + nutrient chips ───────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.foodName, style: AppTextStyles.recFoodName),
                const SizedBox(height: 6),

                // Availability badge
                Row(
                  children: [
                    Text(
                      item.availability.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.availability.label} · ${item.priceRange}',
                      style: AppTextStyles.hint.copyWith(fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── 4 mini nutrient chips ─────────────────────
                Row(
                  children: [
                    _MiniChip(
                      label: 'Kalori',
                      value: '${item.estimatedCalories}',
                      unit: 'kkal',
                    ),
                    const SizedBox(width: 6),
                    // The recommendation schema from Claude has
                    // estimated_calories only. Extend the schema in
                    // ClaudeService.getRecommendations() to also get
                    // fat/protein/salt if needed.
                    _MiniChip(label: 'Lemak', value: '–', unit: 'g'),
                    const SizedBox(width: 6),
                    _MiniChip(label: 'Protein', value: '–', unit: 'g'),
                    const SizedBox(width: 6),
                    _MiniChip(label: 'Garam', value: '–', unit: 'g'),
                  ],
                ),

                const SizedBox(height: 8),

                // Why healthier note
                Text(
                  item.whyHealthier,
                  style: AppTextStyles.hint.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini nutrient chip on recommendation cards ────────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MiniChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.recChip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.recChipLabel),
          Text(
            value == '–' ? '–' : '$value\n$unit',
            style: AppTextStyles.recChipValue,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
