// lib/shared/widgets/gizione_logo.dart

import 'package:flutter/material.dart';

class GiziOneLogo extends StatelessWidget {
  final double scale;
  const GiziOneLogo({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Gizi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 42 * scale,
                color: const Color(0xFF5B8A3C),
                height: 1.0,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 8 * scale),
              child: Text('🍎', style: TextStyle(fontSize: 20 * scale)),
            ),
            Text(
              'One',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 42 * scale,
                color: const Color(0xFFE8963A),
                height: 1.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 2 * scale),
        Text(
          'Yuk mulai hidup sehat hari ini!',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: 13 * scale,
            color: const Color(0xFF5B8A3C),
          ),
        ),
      ],
    );
  }
}
