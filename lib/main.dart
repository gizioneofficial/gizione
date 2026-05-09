// lib/main.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';

import 'features/splash/splash_screen.dart';

List<CameraDescription> globalCameras = [];

// Pre-initialized video controller — ready before app renders
VideoPlayerController? globalSplashController;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Load .env
  await dotenv.load(fileName: '.env');

  // Initialize cameras
  try {
    globalCameras = await availableCameras();
  } catch (_) {
    globalCameras = [];
  }

  // ── Preload splash video BEFORE runApp ───────────────────
  // This ensures the animation plays immediately with no delay
  try {
    globalSplashController = VideoPlayerController.asset(
      'assets/images/gizione_intro.mov',
    );
    await globalSplashController!.initialize();
    await globalSplashController!.setVolume(1.0); // enable sound
    await globalSplashController!.setLooping(false);
  } catch (_) {
    globalSplashController = null;
  }

  runApp(const GiziOneApp());
}

class GiziOneApp extends StatelessWidget {
  const GiziOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GiziOne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B8A3C),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
