// lib/features/onboarding/screens/onboarding_screen.dart
//
// 3-slide onboarding shown only on first app launch.
// Spec 3: completable in ≤10 minutes without help.
// Uses SharedPreferences to remember if onboarding was done.
//
// pubspec.yaml dep needed:
//   shared_preferences: ^2.2.3

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/gizione_logo.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      emoji: '🥗',
      title: 'Selamat datang di GiziOne!',
      subtitle:
          'Aplikasi edukasi gizi untuk membantu kamu memilih makanan sehat setiap hari.',
      bgColor: Color(0xFFEDF7E6),
    ),
    _OnboardingSlide(
      emoji: '📷',
      title: 'Scan makananmu',
      subtitle:
          'Arahkan kamera ke makanan, dan AI kami akan langsung menganalisis kandungan gizinya dalam hitungan detik.',
      bgColor: Color(0xFFFFF4E6),
    ),
    _OnboardingSlide(
      emoji: '💡',
      title: 'Dapat rekomendasi sehat',
      subtitle:
          'Bingung mau makan apa? Ceritakan situasimu dan dapatkan minimal 3 pilihan makanan sehat yang terjangkau.',
      bgColor: Color(0xFFE6F0FF),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Mark onboarding as complete so it never shows again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: GiziOneLogo(scale: 0.7),
            ),

            // ── Slides ────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // ── Dot indicators ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primaryGreen
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Next / Mulai button ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _next,
                  child: Text(
                    _currentPage == _slides.length - 1
                        ? 'Mulai Sekarang 🚀'
                        : 'Lanjut →',
                  ),
                ),
              ),
            ),

            // ── Skip ──────────────────────────────────────────
            if (_currentPage < _slides.length - 1)
              TextButton(
                onPressed: _finish,
                child: const Text(
                  'Lewati',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              )
            else
              const SizedBox(height: 44),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Single slide ───────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Emoji in coloured circle ──────────────────────
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: slide.bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(slide.emoji, style: const TextStyle(fontSize: 72)),
            ),
          ),

          const SizedBox(height: 40),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: AppColors.textGrey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
  });
}
