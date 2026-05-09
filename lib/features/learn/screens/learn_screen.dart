// lib/features/learn/screens/learn_screen.dart
//
// Education feed — Claude-generated nutrition tip cards.
// Tapping a card opens ArticleDetailScreen.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/education_article_model.dart';
import '../../../services/claude_service.dart';
import '../../../shared/widgets/gizione_logo.dart';
import 'article_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _claude = ClaudeService();
  List<EducationArticleModel> _articles = [];
  bool _isLoading = true;
  String? _error;

  // Topic filter chips
  static const _topics = [
    'Semua',
    'Protein',
    'Gula',
    'Lemak',
    'Garam',
    'Sarapan'
  ];
  String _selectedTopic = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final topic = _selectedTopic == 'Semua' ? null : _selectedTopic;
      final articles = await _claude.getEducationFeed(
        count: 6,
        topic: topic,
        language: 'id',
      );
      if (mounted)
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
    } on ClaudeServiceException catch (e) {
      if (mounted)
        setState(() {
          _error = e.userMessage;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Gagal memuat artikel. Coba lagi.';
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(child: GiziOneLogo(scale: 0.65)),
            const SizedBox(height: 16),

            // ── Header ───────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Pelajari Gizi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: AppColors.textDark,
                  )),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Artikel singkat untuk hidup lebih sehat',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textGrey,
                  )),
            ),

            const SizedBox(height: 16),

            // ── Topic filter chips ────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = _topics[i] == _selectedTopic;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedTopic = _topics[i]);
                      _loadArticles();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
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
                        _topics[i],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Article list ──────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen))
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: _loadArticles)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          itemCount: _articles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _ArticleCard(
                            article: _articles[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ArticleDetailScreen(article: _articles[i]),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Article card ───────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final EducationArticleModel article;
  final VoidCallback onTap;
  const _ArticleCard({required this.article, required this.onTap});

  Color _categoryColor() {
    switch (article.category) {
      case ArticleCategory.tips:
        return const Color(0xFFB5D99C);
      case ArticleCategory.fakta:
        return const Color(0xFFADD8E6);
      case ArticleCategory.resep:
        return const Color(0xFFE8C07A);
      case ArticleCategory.mitos:
        return const Color(0xFFD4AADC);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Emoji circle ────────────────────────────────
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _categoryColor().withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child:
                    Text(article.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Category badge ───────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _categoryColor(),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.category.label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(article.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textDark,
                      )),
                  const SizedBox(height: 4),
                  Text(article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textGrey,
                        height: 1.4,
                      )),
                  const SizedBox(height: 6),
                  Text(article.readTimeLabel,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins', color: AppColors.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white),
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
