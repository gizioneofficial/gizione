// lib/features/splash/splash_screen.dart
//
// Uses the pre-initialized controller from main.dart
// so the animation starts IMMEDIATELY — no loading delay.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../../main.dart'; // for globalSplashController

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _startVideo();
  }

  void _startVideo() {
    // Use the pre-loaded controller from main.dart
    if (globalSplashController != null &&
        globalSplashController!.value.isInitialized) {
      _controller = globalSplashController;
      _controller!.addListener(_onVideoUpdate);

      setState(() => _videoReady = true);

      // Play immediately — no waiting
      _controller!.play();
    } else {
      // Fallback: video failed to preload, navigate after delay
      Future.delayed(const Duration(seconds: 2), _navigate);
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;

    final pos = _controller!.value.position;
    final duration = _controller!.value.duration;
    final playing = _controller!.value.isPlaying;

    // Video finished playing
    if (duration > Duration.zero && pos >= duration && !playing) {
      _controller!.removeListener(_onVideoUpdate);
      _navigate();
    }
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            onboardingDone ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    // Don't dispose here — main.dart owns it
    // globalSplashController will be disposed by the OS
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _videoReady ? _buildVideo() : _buildFallback(),
    );
  }

  Widget _buildVideo() {
    return SizedBox.expand(
      child: FittedBox(
        // Cover fills the portrait screen edge to edge
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  // Only shows if video failed to preload — very rare
  Widget _buildFallback() {
    return Center(
      child: Image.asset(
        'assets/images/GiziOne_Logo.png',
        width: 200,
      ),
    );
  }
}
