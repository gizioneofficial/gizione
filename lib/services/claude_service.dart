// lib/services/claude_service.dart
//
// GiziOne — Core Claude API Integration Service
// All AI calls live here: food scan (vision), nutrition lookup,
// smart recommendations, and education feed generation.
//
// pubspec.yaml dependencies required:
//   http: ^1.2.1
//   flutter_dotenv: ^5.1.0
//   connectivity_plus: ^6.0.3

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/nutrition_model.dart';
import '../models/recommendation_model.dart';
import '../models/education_article_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Custom exceptions  (shown as user-friendly messages in UI snackbars)
// ─────────────────────────────────────────────────────────────────────────────

class ClaudeServiceException implements Exception {
  final String userMessage; // displayed to user (ID or EN)
  final String technicalMessage; // for logging only — never show to user
  const ClaudeServiceException(this.userMessage, {this.technicalMessage = ''});
  @override
  String toString() => 'ClaudeServiceException: $technicalMessage';
}

class NoInternetException extends ClaudeServiceException {
  NoInternetException()
      : super(
          'Tidak ada koneksi internet. Periksa jaringan dan coba lagi.',
          technicalMessage: 'No internet connection',
        );
}

class ApiTimeoutException extends ClaudeServiceException {
  ApiTimeoutException()
      : super(
          'Permintaan memakan waktu terlalu lama. Coba lagi.',
          technicalMessage: 'Claude API timed out (15 s)',
        );
}

class ParseException extends ClaudeServiceException {
  ParseException(String detail)
      : super(
          'Terjadi kesalahan memproses data. Coba lagi.',
          technicalMessage: 'JSON parse error: $detail',
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// ClaudeService  (singleton)
// ─────────────────────────────────────────────────────────────────────────────

class ClaudeService {
  static final ClaudeService _instance = ClaudeService._internal();
  factory ClaudeService() => _instance;
  ClaudeService._internal();

  // ── Config: read from .env — NEVER hardcode API keys ──────────────────────
  String get _apiKey => dotenv.env['CLAUDE_API_KEY'] ?? '';
  String get _model => dotenv.env['CLAUDE_MODEL'] ?? 'claude-sonnet-4-20250514';
  int get _maxTok => int.tryParse(dotenv.env['MAX_TOKENS'] ?? '1024') ?? 1024;

  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';

  // Spec 1 & 6: nutritional info AND recommendations must appear within ≤15 s
  static const Duration _timeout = Duration(seconds: 15);

  // ── LOW-LEVEL: text-only Claude call ──────────────────────────────────────

  Future<String> _callClaude({
    required String systemPrompt,
    required String userMessage,
  }) async {
    _assertApiKey();
    try {
      final res = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _buildHeaders(),
            body: jsonEncode({
              'model': _model,
              'max_tokens': _maxTok,
              'system': systemPrompt,
              'messages': [
                {'role': 'user', 'content': userMessage},
              ],
            }),
          )
          .timeout(_timeout, onTimeout: () => throw ApiTimeoutException());
      return _extractText(res);
    } on ClaudeServiceException {
      rethrow; // already wrapped
    } on SocketException {
      throw NoInternetException();
    } catch (e) {
      throw ClaudeServiceException(
        'Terjadi kesalahan. Silakan coba lagi.',
        technicalMessage: e.toString(),
      );
    }
  }

  // ── LOW-LEVEL: vision call (image bytes + text) ────────────────────────────

  Future<String> _callClaudeVision({
    required String systemPrompt,
    required String userTextPrompt,
    required Uint8List imageBytes,
    required String mimeType, // 'image/jpeg' | 'image/png' | 'image/webp'
  }) async {
    _assertApiKey();
    final b64 = base64Encode(imageBytes); // encode image for API
    try {
      final res = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _buildHeaders(),
            body: jsonEncode({
              'model': _model,
              'max_tokens': _maxTok,
              'system': systemPrompt,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    // Claude vision: image block first, then text prompt
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
                },
              ],
            }),
          )
          .timeout(_timeout, onTimeout: () => throw ApiTimeoutException());
      return _extractText(res);
    } on ClaudeServiceException {
      rethrow;
    } on SocketException {
      throw NoInternetException();
    } catch (e) {
      throw ClaudeServiceException(
        'Gagal memindai makanan. Coba lagi.',
        technicalMessage: e.toString(),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PUBLIC METHODS
  // ─────────────────────────────────────────────────────────────────────────────

  // ── 1. FOOD SCAN  (camera → NutritionModel) ──────────────────────────────
  //    Spec 1: ≤15 s  |  Spec 2: ≥3 nutrients  |  Spec 4: result on one screen
  Future<NutritionModel> scanFood({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String language = 'id', // 'id' = Bahasa Indonesia, 'en' = English
  }) async {
    const systemPrompt = '''
Anda adalah ahli gizi. Identifikasi makanan dalam gambar dan kembalikan data gizi.
You are a nutrition expert. Identify the food in the image and return nutritional data.

Respond ONLY in valid JSON. No markdown, no preamble, no explanation outside JSON.
Use this EXACT schema:
{
  "food_name": "string",
  "serving_size": "string (e.g. '1 porsi / 100 g')",
  "nutrients": {
    "calories": { "value": number, "unit": "kcal" },
    "fat":      { "value": number, "unit": "g" },
    "sugar":    { "value": number, "unit": "g" },
    "protein":  { "value": number, "unit": "g" },
    "salt":     { "value": number, "unit": "mg" }
  },
  "health_rating": integer 1-5,
  "healthier_note": "one short practical tip in the user language"
}
If food cannot be identified, return food_name "Tidak dikenali / Unidentified" with value 0 for all nutrients.
''';

    final userPrompt = language == 'id'
        ? 'Identifikasi makanan dalam gambar ini dan berikan informasi gizinya.'
        : 'Identify the food in this image and provide its nutritional information.';

    final rawJson = await _callClaudeVision(
      systemPrompt: systemPrompt,
      userTextPrompt: userPrompt,
      imageBytes: imageBytes,
      mimeType: mimeType,
    );
    return _parseNutrition(rawJson);
  }

  // ── 2. NUTRITION LOOKUP  (text → NutritionModel) ─────────────────────────
  //    Spec 1: ≤15 s  |  Spec 2: ≥3 nutrients
  Future<NutritionModel> lookupNutrition(
    String foodName, {
    String language = 'id',
  }) async {
    const systemPrompt = '''
Anda adalah database gizi makanan Indonesia dan internasional.
You are an Indonesian and international food nutrition database.

Respond ONLY in valid JSON. No markdown, no preamble.
EXACT schema:
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
  "health_rating": integer 1-5,
  "healthier_note": "one short tip in the user language"
}
Provide typical values per standard serving. Give your best estimate — never refuse or return null.
''';

    final userPrompt = language == 'id'
        ? 'Berikan informasi kandungan gizi untuk: $foodName'
        : 'Provide nutritional information for: $foodName';

    final rawJson = await _callClaude(
      systemPrompt: systemPrompt,
      userMessage: userPrompt,
    );
    return _parseNutrition(rawJson);
  }

  // ── 3. SMART RECOMMENDER  (context → List<RecommendationModel>) ───────────
  //    Spec 5: ≥3 options  |  Spec 6: ≤15 s
  Future<List<RecommendationModel>> getRecommendations({
    required String situation, // e.g. 'sibuk kuliah', 'habis olahraga'
    String? mood, // e.g. 'lapar banget', 'pengen manis'
    String? budget, // e.g. 'Rp5000-Rp15000'
    String? avoidance, // e.g. 'tidak suka pedas'
    String language = 'id',
  }) async {
    const systemPrompt = '''
Anda adalah ahli gizi yang membantu mahasiswa Indonesia memilih makanan sehat & terjangkau.
Respond ONLY in valid JSON. No markdown, no preamble.
EXACT schema:
{
  "recommendations": [
    {
      "food_name": "string",
      "why_healthier": "string (short reason in user language)",
      "estimated_calories": number,
      "availability": "warung" | "restoran" | "supermarket" | "kantin",
      "price_range": "string IDR e.g. Rp5.000 - Rp10.000"
    }
  ]
}
ALWAYS return AT LEAST 3 recommendations. Prioritise foods common near Indonesian campuses.
Keep under Rp25.000 unless budget says otherwise.
''';

    final parts = [
      language == 'id'
          ? 'Situasi saya: $situation'
          : 'My situation: $situation',
      if (mood != null)
        language == 'id' ? 'Mood/keinginan: $mood' : 'Mood/craving: $mood',
      if (budget != null) 'Budget: $budget',
      if (avoidance != null)
        language == 'id' ? 'Hindari: $avoidance' : 'Avoid: $avoidance',
      language == 'id'
          ? 'Rekomendasikan minimal 3 makanan sehat dan terjangkau.'
          : 'Recommend at least 3 healthy and affordable options.',
    ];

    final rawJson = await _callClaude(
      systemPrompt: systemPrompt,
      userMessage: parts.join('\n'),
    );
    return _parseRecommendations(rawJson);
  }

  // ── 4. EDUCATION FEED  (→ List<EducationArticleModel>) ───────────────────
  Future<List<EducationArticleModel>> getEducationFeed({
    int count = 5,
    String? topic, // e.g. 'gula', 'protein', 'sarapan'
    String language = 'id',
  }) async {
    final lang = language == 'id' ? 'Bahasa Indonesia' : 'English';
    final topicLine = topic != null ? ' about the topic: $topic' : '';
    final systemPrompt = '''
Tulis konten edukasi gizi singkat untuk mahasiswa Gen Z Indonesia.
Respond ONLY in valid JSON. No markdown, no preamble.
EXACT schema:
{
  "articles": [
    {
      "id": "short-slug-string",
      "title": "string max 60 chars",
      "summary": "2-3 sentences, practical and relatable",
      "category": "tips" | "fakta" | "resep" | "mitos",
      "emoji": "single emoji",
      "read_time_seconds": number
    }
  ]
}
Write in $lang. Casual, relatable tone for 18-24 year olds. Campus-life focus.
Generate exactly $count articles$topicLine.
''';

    final userPrompt = language == 'id'
        ? 'Buat $count artikel edukasi gizi singkat untuk mahasiswa.'
        : 'Generate $count short nutrition education articles for university students.';

    final rawJson = await _callClaude(
      systemPrompt: systemPrompt,
      userMessage: userPrompt,
    );
    return _parseEducationFeed(rawJson);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────────

  Map<String, String> _buildHeaders() => {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      };

  void _assertApiKey() {
    if (_apiKey.isEmpty) {
      throw const ClaudeServiceException(
        'Konfigurasi aplikasi bermasalah. Hubungi developer.',
        technicalMessage: 'CLAUDE_API_KEY not set in .env',
      );
    }
  }

  /// Parse HTTP response → text string, handle error status codes.
  String _extractText(http.Response res) {
    switch (res.statusCode) {
      case 401:
        throw const ClaudeServiceException(
          'Autentikasi gagal. Hubungi developer.',
          technicalMessage: 'Claude API 401 Unauthorized',
        );
      case 429:
        throw const ClaudeServiceException(
          'Terlalu banyak permintaan. Tunggu sebentar dan coba lagi.',
          technicalMessage: 'Claude API 429 Rate limited',
        );
      case 200:
        break; // OK — continue
      default:
        throw ClaudeServiceException(
          'Layanan AI sedang bermasalah. Coba lagi nanti.',
          technicalMessage: 'Claude API ${res.statusCode}: ${res.body}',
        );
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    if (content.isEmpty) throw ParseException('empty content array');
    final text = (content[0] as Map<String, dynamic>)['text'] as String? ?? '';
    if (text.isEmpty) throw ParseException('empty text block');
    return text;
  }

  /// Strip accidental markdown fences (```json ... ```) from Claude output.
  String _stripFences(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      s = s.replaceFirst(RegExp(r'\n?```$'), '');
    }
    return s.trim();
  }

  NutritionModel _parseNutrition(String raw) {
    try {
      final map = jsonDecode(_stripFences(raw)) as Map<String, dynamic>;
      return NutritionModel.fromJson(map);
    } catch (e) {
      throw ParseException('NutritionModel – $e | raw: $raw');
    }
  }

  List<RecommendationModel> _parseRecommendations(String raw) {
    try {
      final map = jsonDecode(_stripFences(raw)) as Map<String, dynamic>;
      final list = map['recommendations'] as List<dynamic>;
      return list
          .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ParseException('RecommendationModel – $e | raw: $raw');
    }
  }

  List<EducationArticleModel> _parseEducationFeed(String raw) {
    try {
      final map = jsonDecode(_stripFences(raw)) as Map<String, dynamic>;
      final list = map['articles'] as List<dynamic>;
      return list
          .map((e) => EducationArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ParseException('EducationArticleModel – $e | raw: $raw');
    }
  }
}
