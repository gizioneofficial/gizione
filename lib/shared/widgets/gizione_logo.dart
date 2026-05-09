// lib/shared/widgets/gizione_logo.dart
//
// Uses the official GiziOne_Logo.png asset instead of text.

import 'package:flutter/material.dart';

class GiziOneLogo extends StatelessWidget {
  final double scale;
  const GiziOneLogo({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/GiziOne_Logo.png',
      width: 200 * scale,
      fit: BoxFit.contain,
    );
  }
}
