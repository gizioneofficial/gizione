// lib/features/learn/screens/article_detail_screen.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/education_article_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  final EducationArticleModel article;
  const ArticleDetailScreen({super.key, required this.article});

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Artikel',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textDark,
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero emoji ──────────────────────────────────
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _categoryColor().withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      Text(article.emoji, style: const TextStyle(fontSize: 52)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Category + read time ─────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _categoryColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    article.category.label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(article.readTimeLabel,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textGrey,
                    )),
              ],
            ),

            const SizedBox(height: 16),

            // ── Title ────────────────────────────────────────
            Text(article.title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.textDark,
                  height: 1.3,
                )),

            const SizedBox(height: 20),

            // ── Divider ──────────────────────────────────────
            Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 20),

            // ── Body / summary ───────────────────────────────
            // Claude currently returns a 2-3 sentence summary.
            // In a full version you could call Claude again to
            // expand the article — for now show summary with
            // generous line spacing to fill the screen nicely.
            Text(article.summary,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: AppColors.textDark,
                  height: 1.8,
                )),

            const SizedBox(height: 32),

            // ── Tip box ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.chipCalorie.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Terapkan tips ini dalam kehidupan sehari-harimu untuk mendapatkan manfaat gizi yang optimal!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
