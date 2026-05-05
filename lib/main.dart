// lib/main.dart
//
// GiziOne app entry point.
// Loads .env → runs the app.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/home/screens/home_screen.dart';
import 'features/scan/screens/scan_screen.dart';
import 'features/scan/screens/scan_result_screen.dart';
import 'features/recommend/screens/recommend_screen.dart';
import 'features/recommend/screens/recommend_result_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file — CLAUDE_API_KEY lives here
  await dotenv.load(fileName: '.env');

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B8A3C)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/scan': (_) => const ScanScreen(),
        '/recommend': (_) => const RecommendScreen(),
      },
    );
  }
}
