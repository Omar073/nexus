import 'package:flutter/material.dart';

import 'notch_preview_painter.dart';

Widget buildRivePreview(
  Color primaryColor,
  Color surfaceColor,
  Color iconColor,
) {
  return Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: surfaceColor.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: surfaceColor.withValues(alpha: 0.3),
          offset: const Offset(0, 4),
          blurRadius: 6,
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 2,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 1),
            Icon(Icons.home, size: 14, color: primaryColor),
          ],
        ),
        Icon(Icons.search, size: 12, color: iconColor.withValues(alpha: 0.5)),
        Icon(Icons.settings, size: 12, color: iconColor.withValues(alpha: 0.5)),
      ],
    ),
  );
}

Widget buildStandardPreview(
  Color primaryColor,
  Color surfaceColor,
  Color iconColor,
) {
  return Container(
    height: 32,
    decoration: BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          width: 24,
          height: 20,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.home, size: 12, color: primaryColor),
        ),
        Icon(Icons.search, size: 12, color: iconColor),
        Icon(Icons.settings, size: 12, color: iconColor),
      ],
    ),
  );
}

Widget buildCurvedPreview(
  Color primaryColor,
  Color surfaceColor,
  Color iconColor,
) {
  return SizedBox(
    height: 36,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.search, size: 10, color: iconColor),
                const SizedBox(width: 24),
                Icon(Icons.settings, size: 10, color: iconColor),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.home, size: 14, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

Widget buildNotchPreview(
  Color primaryColor,
  Color surfaceColor,
  Color iconColor,
) {
  return SizedBox(
    height: 36,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 26),
            painter: NotchPreviewPainter(
              color: surfaceColor,
              notchColor: primaryColor,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home, size: 12, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 6,
          left: 12,
          child: Icon(Icons.search, size: 10, color: iconColor),
        ),
        Positioned(
          bottom: 6,
          right: 12,
          child: Icon(Icons.settings, size: 10, color: iconColor),
        ),
      ],
    ),
  );
}

Widget buildGooglePreview(
  Color primaryColor,
  Color surfaceColor,
  Color iconColor,
) {
  return Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.home, size: 10, color: Colors.white),
              SizedBox(width: 2),
              Text('Home', style: TextStyle(fontSize: 7, color: Colors.white)),
            ],
          ),
        ),
        Icon(Icons.search, size: 12, color: iconColor),
        Icon(Icons.settings, size: 12, color: iconColor),
      ],
    ),
  );
}
