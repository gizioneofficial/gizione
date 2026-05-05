// lib/features/scan/screens/scan_screen.dart
//
// Screen 2 — Scan Dulu
// Camera viewfinder with corner brackets overlay + capture button.
// On capture → calls ClaudeService.scanFood() → navigates to ScanResultScreen.
//
// pubspec.yaml deps needed:
//   image_picker: ^1.1.2   (pick from gallery OR camera)
//   camera: ^0.10.5+9      (live viewfinder — optional, image_picker is simpler)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/gizione_logo.dart';
import '../../../services/claude_service.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isLoading = false;
  final _picker = ImagePicker();
  final _claude = ClaudeService();

  // ── Pick image from camera or gallery, then call Claude ──────────────────

  Future<void> _captureAndScan() async {
    // Ask user: camera or gallery
    final source = await _showSourceDialog();
    if (source == null) return;

    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _isLoading = true);

    try {
      final Uint8List bytes = await file.readAsBytes();

      // Determine mime type from extension
      final ext = file.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      // ── Claude Vision API call (Spec 1: ≤15 s) ─────────────────
      final nutrition = await _claude.scanFood(
        imageBytes: bytes,
        mimeType: mime,
        language: 'id',
      );

      if (!mounted) return;

      // Spec 4: max 1 screen transition → push ScanResultScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ScanResultScreen(nutrition: nutrition, imageBytes: bytes),
        ),
      );
    } on ClaudeServiceException catch (e) {
      _showError(e.userMessage);
    } catch (e) {
      _showError('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primaryGreen,
                ),
                title: const Text('Ambil Foto', style: AppTextStyles.bodyBold),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primaryGreen,
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: AppTextStyles.bodyBold,
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Logo ──────────────────────────────────────────
            const GiziOneLogo(scale: 0.75),

            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────
            const Text('Scan dulu', style: AppTextStyles.pageTitle),

            const SizedBox(height: 20),

            // ── Viewfinder box ────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _ViewfinderBox(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Hint text ─────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.filterChip,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Letakkan masakan di dalam area dan\npastikan pencahayaan cukup',
                textAlign: TextAlign.center,
                style: AppTextStyles.hint,
              ),
            ),

            const SizedBox(height: 24),

            // ── Capture button ────────────────────────────────
            GestureDetector(
              onTap: _isLoading ? null : _captureAndScan,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.captureBtn,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.captureBtn.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Viewfinder widget with corner bracket overlays ────────────────────────

class _ViewfinderBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ── Placeholder / camera preview goes here ────────
            // Replace with a real CameraPreview widget if you integrate
            // the `camera` package for live viewfinder.
            Container(
              color: AppColors.background,
              child: const Center(
                child: Text('📷', style: TextStyle(fontSize: 80)),
              ),
            ),

            // ── Corner bracket overlay ─────────────────────────
            Positioned.fill(
              child: CustomPaint(painter: _CornerBracketPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Draws the 4 corner brackets like a camera viewfinder ──────────────────

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const margin = 20.0;
    const len = 28.0;

    // Top-left
    canvas.drawLine(
      Offset(margin, margin + len),
      Offset(margin, margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + len, margin),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - margin - len, margin),
      Offset(size.width - margin, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + len),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(margin, size.height - margin - len),
      Offset(margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + len, size.height - margin),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - margin - len, size.height - margin),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin - len),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
