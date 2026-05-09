// lib/features/scan/screens/scan_screen.dart
//
// Screen 2 — Scan Dulu
// Uses the `camera` package for a LIVE in-app viewfinder.
// No external camera app opens — the preview is shown directly
// inside the GiziOne app, matching the design mockup exactly.
//
// Flow:
//   1. App opens → camera permission requested → live preview shown
//   2. User taps capture button → photo taken in-app
//   3. Image bytes sent to Claude Vision API
//   4. Result shown on ScanResultScreen (Spec 4: max 1 transition)

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/gizione_logo.dart';
import '../../../services/claude_service.dart';
import '../../../main.dart'; // for globalCameras
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  String? _errorMessage;
  final _claude = ClaudeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // Pause/resume camera when app goes to background/foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ── Initialize the back camera ──────────────────────────────────────────

  Future<void> _initCamera() async {
    if (globalCameras.isEmpty) {
      setState(() => _errorMessage = 'Kamera tidak tersedia di perangkat ini.');
      return;
    }

    // Use the first back-facing camera
    final camera = globalCameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => globalCameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isCameraReady = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage =
          'Tidak bisa mengakses kamera. Pastikan izin kamera sudah diberikan.');
    }
  }

  // ── Capture photo & send to Claude ─────────────────────────────────────

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_isCameraReady || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _isProcessing = false;
    });

    try {
      // Take picture — returns a file path
      final XFile photo = await _controller!.takePicture();
      final Uint8List imageBytes = await photo.readAsBytes();

      setState(() => _isProcessing = true);

      // ── Claude Vision API call (Spec 1: ≤15 s timeout) ──────
      final nutrition = await _claude.scanFood(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        language: 'id',
      );

      if (!mounted) return;

      // Spec 4: max 1 screen transition after scan
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            nutrition: nutrition,
            imageBytes: imageBytes,
          ),
        ),
      );
    } on ClaudeServiceException catch (e) {
      _showError(e.userMessage);
    } catch (e) {
      _showError('Gagal memproses gambar. Coba lagi.');
    } finally {
      if (mounted)
        setState(() {
          _isCapturing = false;
          _isProcessing = false;
        });
    }
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

  // ── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Logo ───────────────────────────────────────────
            const GiziOneLogo(scale: 0.7),

            const SizedBox(height: 16),

            // ── Title ──────────────────────────────────────────
            const Text('Scan dulu yuk makanannya',
                style: AppTextStyles.pageTitle),

            const SizedBox(height: 16),

            // ── Camera viewfinder ──────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildViewfinder(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Hint text ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.filterChip,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isProcessing
                    ? 'Sedang menganalisis kandungan gizi...'
                    : 'Letakkan masakan di dalam area dan\npastikan pencahayaan cukup',
                textAlign: TextAlign.center,
                style: AppTextStyles.hint,
              ),
            ),

            const SizedBox(height: 24),

            // ── Capture button ─────────────────────────────────
            _buildCaptureButton(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Live camera preview with corner brackets ───────────────────────────

  Widget _buildViewfinder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera preview or error state ──────────────────
            if (_errorMessage != null)
              _ErrorView(message: _errorMessage!, onRetry: _initCamera)
            else if (!_isCameraReady)
              const _LoadingView()
            else
              // ── LIVE IN-APP CAMERA PREVIEW ──────────────────
              _LivePreview(controller: _controller!),

            // ── Corner bracket overlay ──────────────────────────
            if (_isCameraReady)
              Positioned.fill(
                child: CustomPaint(painter: _CornerBracketPainter()),
              ),

            // ── Processing overlay ──────────────────────────────
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Menganalisis dengan AI...',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Green circular capture button ─────────────────────────────────────

  Widget _buildCaptureButton() {
    final bool busy = _isCapturing || _isProcessing || !_isCameraReady;
    return GestureDetector(
      onTap: busy ? null : _captureAndAnalyze,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: busy ? 65 : 72,
        height: busy ? 65 : 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: busy
              ? AppColors.captureBtn.withValues(alpha: 0.5)
              : AppColors.captureBtn,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: busy
              ? []
              : [
                  BoxShadow(
                    color: AppColors.captureBtn.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: _isCapturing || _isProcessing
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 32),
      ),
    );
  }
}

// ── Live camera preview widget ─────────────────────────────────────────────

class _LivePreview extends StatelessWidget {
  final CameraController controller;
  const _LivePreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    // CameraPreview fills its parent; we clip it with the parent's
    // BorderRadius already applied via ClipRRect above.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 400,
        height: controller.value.previewSize?.width ?? 300,
        child: CameraPreview(controller),
      ),
    );
  }
}

// ── Loading state ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 12),
          Text(
            'Mempersiapkan kamera...',
            style: TextStyle(
                color: Colors.white, fontFamily: 'Poppins', fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Corner bracket overlay painter ────────────────────────────────────────

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const m = 24.0; // margin from edge
    const l = 32.0; // bracket arm length

    // Top-left
    canvas.drawLine(Offset(m, m + l), Offset(m, m), paint);
    canvas.drawLine(Offset(m, m), Offset(m + l, m), paint);
    // Top-right
    canvas.drawLine(
        Offset(size.width - m - l, m), Offset(size.width - m, m), paint);
    canvas.drawLine(
        Offset(size.width - m, m), Offset(size.width - m, m + l), paint);
    // Bottom-left
    canvas.drawLine(
        Offset(m, size.height - m - l), Offset(m, size.height - m), paint);
    canvas.drawLine(
        Offset(m, size.height - m), Offset(m + l, size.height - m), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - m - l, size.height - m),
        Offset(size.width - m, size.height - m), paint);
    canvas.drawLine(Offset(size.width - m, size.height - m - l),
        Offset(size.width - m, size.height - m), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
