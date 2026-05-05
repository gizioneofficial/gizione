// lib/features/recommend/screens/recommend_screen.dart
//
// Screen 4a — Rekomendasi Makanan (Input)
// User fills in situation / mood / budget → calls Claude → shows results.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/gizione_logo.dart';
import '../../../services/claude_service.dart';
import 'recommend_result_screen.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final _situationCtrl = TextEditingController();
  final _moodCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  bool _isLoading = false;
  final _claude = ClaudeService();

  // Quick-select chips for common situations
  static const _situations = [
    'Sibuk kuliah',
    'Habis olahraga',
    'Makan siang',
    'Makan malam',
    'Lagi diet',
    'Sarapan',
  ];

  String? _selectedSituation;

  @override
  void dispose() {
    _situationCtrl.dispose();
    _moodCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    final situation = _selectedSituation ?? _situationCtrl.text.trim();
    if (situation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih atau isi situasimu dulu ya!'),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── Claude API call (Spec 5: ≥3 results, Spec 6: ≤15 s) ───
      final results = await _claude.getRecommendations(
        situation: situation,
        mood: _moodCtrl.text.trim().isEmpty ? null : _moodCtrl.text.trim(),
        budget: _budgetCtrl.text.trim().isEmpty
            ? null
            : _budgetCtrl.text.trim(),
        language: 'id',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendResultScreen(
            recommendations: results,
            situation: situation,
          ),
        ),
      );
    } on ClaudeServiceException catch (e) {
      _showError(e.userMessage);
    } catch (_) {
      _showError('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
              Center(child: const GiziOneLogo(scale: 0.65)),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  'Rekomendasi\nMakanan',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle,
                ),
              ),

              const SizedBox(height: 24),

              // ── Situation quick chips ──────────────────────
              Text('Situasi kamu sekarang:', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _situations.map((s) {
                  final selected = _selectedSituation == s;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selectedSituation = selected ? null : s,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryGreen
                            : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryGreen
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        s,
                        style: AppTextStyles.chipLabel.copyWith(
                          color: selected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Or type it ─────────────────────────────────
              _InputField(
                controller: _situationCtrl,
                label: 'Atau tulis sendiri…',
                hint: 'cth: lagi di kantin, mau makan siang',
              ),

              const SizedBox(height: 16),

              // ── Mood / craving ─────────────────────────────
              _InputField(
                controller: _moodCtrl,
                label: 'Mood / keinginan (opsional)',
                hint: 'cth: pengen yang segar, lagi diet',
              ),

              const SizedBox(height: 16),

              // ── Budget ─────────────────────────────────────
              _InputField(
                controller: _budgetCtrl,
                label: 'Budget (opsional)',
                hint: 'cth: Rp10.000 - Rp20.000',
                keyboardType: TextInputType.text,
              ),

              const SizedBox(height: 32),

              // ── Submit button ──────────────────────────────
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
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _isLoading ? null : _getRecommendations,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Cari Rekomendasi 🔍'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable text input field ─────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyBold),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.body.copyWith(color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hint,
            filled: true,
            fillColor: AppColors.cardWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryGreen,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
