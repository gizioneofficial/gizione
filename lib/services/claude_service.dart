// lib/services/claude_service.dart
//
// GiziOne — Core Claude API Integration Service
// Plain Dart version — no freezed, no code generation needed.
//
// pubspec.yaml deps:
//   http: ^1.2.1
//   flutter_dotenv: ^5.1.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/nutrition_model.dart';
import '../models/recommendation_model.dart';
import '../models/education_article_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exceptions — each has a user-friendly Indonesian message for the UI
// ─────────────────────────────────────────────────────────────────────────────

class ClaudeServiceException implements Exception {
  final String userMessage;
  final String technicalMessage;
  const ClaudeServiceException(this.userMessage, {this.technicalMessage = ''});
  @override
  String toString() => 'ClaudeServiceException: $technicalMessage';
}

class NoInternetException extends ClaudeServiceException {
  NoInternetException()
      : super('Tidak ada koneksi internet. Periksa jaringan dan coba lagi.',
            technicalMessage: 'No internet');
}

class ApiTimeoutException extends ClaudeServiceException {
  ApiTimeoutException()
      : super('Permintaan terlalu lama. Coba lagi.',
            technicalMessage: 'Timeout after 15s');
}

class ParseException extends ClaudeServiceException {
  ParseException(String d)
      : super('Terjadi kesalahan memproses data. Coba lagi.',
            technicalMessage: 'Parse error: $d');
}

// ─────────────────────────────────────────────────────────────────────────────
// ClaudeService — singleton
// ─────────────────────────────────────────────────────────────────────────────

class ClaudeService {
  static final ClaudeService _instance = ClaudeService._internal();
  factory ClaudeService() => _instance;
  ClaudeService._internal();

  String get _apiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';
  String get _model => dotenv.env['CLAUDE_MODEL'] ?? 'claude-sonnet-4-20250514';
  int get _maxTok => int.tryParse(dotenv.env['MAX_TOKENS'] ?? '1024') ?? 1024;

  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _timeout = Duration(seconds: 15); // Spec 1 & 6

  // ── Text-only API call ─────────────────────────────────────────────────

  Future<String> _callClaude({
    required String systemPrompt,
    required String userMessage,
  }) async {
    _guard();
    try {
      final res = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers(),
            body: jsonEncode({
              'model': _model,
              'max_tokens': _maxTok,
              'system': systemPrompt,
              'messages': [
                {'role': 'user', 'content': userMessage}
              ],
            }),
          )
          .timeout(_timeout, onTimeout: () => throw ApiTimeoutException());
      return _extract(res);
    } on ClaudeServiceException {
      rethrow;
    } on SocketException {
      throw NoInternetException();
    } catch (e) {
      throw ClaudeServiceException('Terjadi kesalahan. Coba lagi.',
          technicalMessage: e.toString());
    }
  }

  // ── Vision API call (image + text) ────────────────────────────────────

  Future<String> _callClaudeVision({
    required String systemPrompt,
    required String userTextPrompt,
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    _guard();
    final b64 = base64Encode(imageBytes);
    try {
      final res = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers(),
            body: jsonEncode({
              'model': _model,
              'max_tokens': _maxTok,
              'system': systemPrompt,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'image',
                      'source': {
                        'type': 'base64',
                        'media_type': mimeType,
                        'data': b64,
                      },
                    },
                    {'type': 'text', 'text': userTextPrompt},
                  ],
                }
              ],
            }),
          )
          .timeout(_timeout, onTimeout: () => throw ApiTimeoutException());
      return _extract(res);
    } on ClaudeServiceException {
      rethrow;
    } on SocketException {
      throw NoInternetException();
    } catch (e) {
      throw ClaudeServiceException('Gagal memindai makanan. Coba lagi.',
          technicalMessage: e.toString());
    }
  }

  // ── PUBLIC: Scan food from camera image ───────────────────────────────
  // Spec 1: ≤15s | Spec 2: ≥3 nutrients | Spec 4: result on one screen

  Future<NutritionModel> scanFood({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String language = 'id',
  }) async {
    const system = '''
Anda adalah ahli gizi. Identifikasi makanan dalam gambar dan kembalikan data gizi.
Respond ONLY in valid JSON. No markdown, no preamble.
Schema:
{
  "food_name": "string",
  "serving_size": "string",
  "nutrients": {
    "calories": { "value": number, "unit": "kcal" },
    "fat":      { "value": number, "unit": "g" },
    "sugar":    { "value": number, "unit": "g" },
    "protein":  { "value": number, "unit": "g" },
    "salt":     { "value": number, "unit": "mg" }
  },
  "health_rating": 1-5,
  "healthier_note": "satu tips singkat dalam bahasa pengguna"
}
Jika tidak bisa diidentifikasi, gunakan food_name "Tidak dikenali" dengan nilai 0.
''';
    final prompt = language == 'id'
        ? 'Identifikasi makanan ini dan berikan info gizinya.'
        : 'Identify this food and provide nutritional information.';
    final raw = await _callClaudeVision(
        systemPrompt: system,
        userTextPrompt: prompt,
        imageBytes: imageBytes,
        mimeType: mimeType);
    return _parseNutrition(raw);
  }

  // ── PUBLIC: Lookup nutrition by food name ─────────────────────────────

  Future<NutritionModel> lookupNutrition(String foodName,
      {String language = 'id'}) async {
    const system = '''
Anda adalah database gizi makanan Indonesia dan internasional.
Respond ONLY in valid JSON. No markdown, no preamble.
Schema:
{
  "food_name": "string",
  "serving_size": "string",
  "nutrients": {
    "calories": { "value": number, "unit": "kcal" },
    "fat":      { "value": number, "unit": "g" },
    "sugar":    { "value": number, "unit": "g" },
    "protein":  { "value": number, "unit": "g" },
    "salt":     { "value": number, "unit": "mg" }
  },
  "health_rating": 1-5,
  "healthier_note": "satu tips singkat"
}
Berikan nilai tipikal per porsi standar. Selalu berikan estimasi terbaik.
''';
    final prompt = language == 'id'
        ? 'Berikan informasi gizi untuk: $foodName'
        : 'Provide nutritional information for: $foodName';
    final raw = await _callClaude(systemPrompt: system, userMessage: prompt);
    return _parseNutrition(raw);
  }

  // ── PUBLIC: Get food recommendations ─────────────────────────────────
  // Spec 5: ≥3 options | Spec 6: ≤15s

  Future<List<RecommendationModel>> getRecommendations({
    required String situation,
    String? mood,
    String? budget,
    String? avoidance,
    String language = 'id',
  }) async {
    const system = '''
Anda adalah ahli gizi untuk mahasiswa Indonesia. Rekomendasikan makanan sehat & terjangkau.
Respond ONLY in valid JSON. No markdown, no preamble.
Schema:
{
  "recommendations": [
    {
      "food_name": "string",
      "why_healthier": "string",
      "estimated_calories": number,
      "availability": "warung" | "restoran" | "supermarket" | "kantin",
      "price_range": "string (IDR)"
    }
  ]
}
SELALU berikan MINIMAL 3 rekomendasi. Prioritaskan makanan yang umum di sekitar kampus Indonesia.
Budget default di bawah Rp25.000 kecuali disebutkan lain.
''';
    final lines = [
      'Situasi: $situation',
      if (mood != null) 'Mood/keinginan: $mood',
      if (budget != null) 'Budget: $budget',
      if (avoidance != null) 'Hindari: $avoidance',
      'Rekomendasikan minimal 3 makanan sehat.',
    ];
    final raw =
        await _callClaude(systemPrompt: system, userMessage: lines.join('\n'));
    return _parseRecommendations(raw);
  }

  // ── PUBLIC: Get education articles ────────────────────────────────────

  Future<List<EducationArticleModel>> getEducationFeed({
    int count = 5,
    String? topic,
    String language = 'id',
  }) async {
    final topicLine = topic != null ? ' tentang topik: $topic' : '';
    final system = '''
Tulis konten edukasi gizi untuk mahasiswa Gen Z Indonesia.
Respond ONLY in valid JSON. No markdown, no preamble.
Schema:
{
  "articles": [
    {
      "id": "slug-string",
      "title": "max 60 karakter",
      "summary": "2-3 kalimat praktis",
      "category": "tips" | "fakta" | "resep" | "mitos",
      "emoji": "satu emoji",
      "read_time_seconds": number
    }
  ]
}
Buat tepat $count artikel$topicLine. Gunakan bahasa santai untuk usia 18-24 tahun.
''';
    final raw = await _callClaude(
        systemPrompt: system,
        userMessage: 'Buat $count artikel edukasi gizi untuk mahasiswa.');
    return _parseEducationFeed(raw);
  }

  // ── Private helpers ───────────────────────────────────────────────────

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      };

  void _guard() {
    if (_apiKey.isEmpty) {
      throw const ClaudeServiceException(
          'Konfigurasi API bermasalah. Hubungi developer.',
          technicalMessage: 'CLAUDE_API_KEY empty');
    }
  }

  String _extract(http.Response res) {
    switch (res.statusCode) {
      case 401:
        throw const ClaudeServiceException('Autentikasi gagal.',
            technicalMessage: '401 Unauthorized');
      case 429:
        throw const ClaudeServiceException(
            'Terlalu banyak permintaan. Tunggu sebentar.',
            technicalMessage: '429 Rate limited');
      case 200:
        break;
      default:
        throw ClaudeServiceException('Layanan AI bermasalah. Coba lagi nanti.',
            technicalMessage: '${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    if (content.isEmpty) throw ParseException('empty content');
    final text = (content[0] as Map<String, dynamic>)['text'] as String? ?? '';
    if (text.isEmpty) throw ParseException('empty text');
    return text;
  }

  String _clean(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      s = s.replaceFirst(RegExp(r'\n?```$'), '');
    }
    return s.trim();
  }

  NutritionModel _parseNutrition(String raw) {
    try {
      return NutritionModel.fromJson(
          jsonDecode(_clean(raw)) as Map<String, dynamic>);
    } catch (e) {
      throw ParseException('NutritionModel: $e');
    }
  }

  List<RecommendationModel> _parseRecommendations(String raw) {
    try {
      final map = jsonDecode(_clean(raw)) as Map<String, dynamic>;
      final list = map['recommendations'] as List<dynamic>;
      return list
          .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ParseException('RecommendationModel: $e');
    }
  }

  List<EducationArticleModel> _parseEducationFeed(String raw) {
    try {
      final map = jsonDecode(_clean(raw)) as Map<String, dynamic>;
      final list = map['articles'] as List<dynamic>;
      return list
          .map((e) => EducationArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ParseException('EducationArticleModel: $e');
    }
  }
}
