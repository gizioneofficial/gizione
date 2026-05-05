// lib/models/education_article_model.dart

enum ArticleCategory { tips, fakta, resep, mitos }

class EducationArticleModel {
  final String id;
  final String title;
  final String summary;
  final ArticleCategory category;
  final String emoji;
  final int readTimeSeconds;

  const EducationArticleModel({
    this.id = '',
    this.title = '',
    this.summary = '',
    this.category = ArticleCategory.tips,
    this.emoji = '📖',
    this.readTimeSeconds = 60,
  });

  factory EducationArticleModel.fromJson(Map<String, dynamic> json) {
    ArticleCategory cat = ArticleCategory.tips;
    switch (json['category'] as String? ?? '') {
      case 'fakta':
        cat = ArticleCategory.fakta;
        break;
      case 'resep':
        cat = ArticleCategory.resep;
        break;
      case 'mitos':
        cat = ArticleCategory.mitos;
        break;
    }
    return EducationArticleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      category: cat,
      emoji: json['emoji'] as String? ?? '📖',
      readTimeSeconds: (json['read_time_seconds'] as num?)?.toInt() ?? 60,
    );
  }

  String get readTimeLabel {
    final mins = (readTimeSeconds / 60).ceil();
    return '$mins menit baca';
  }
}
