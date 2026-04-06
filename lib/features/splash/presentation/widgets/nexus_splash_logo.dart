import 'package:flutter/material.dart';

/// Fallback logo mark for splash when proprietary branding assets are missing.
class NexusSplashLogo extends StatelessWidget {
  const NexusSplashLogo({
    super.key,
    required this.isDark,
    this.width = 320,
    this.height = 120,
  });

  final bool isDark;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;

    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(
          'NEXUS',
          style: TextStyle(
            color: fg,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
