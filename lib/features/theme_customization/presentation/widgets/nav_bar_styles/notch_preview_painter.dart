import 'package:flutter/material.dart';

/// Paints the notch-shaped preview for the notch style.
class NotchPreviewPainter extends CustomPainter {
  NotchPreviewPainter({required this.color, required this.notchColor});

  final Color color;
  final Color notchColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const notchRadius = 16.0;
    final centerX = size.width / 2;

    path.moveTo(0, 8);
    path.lineTo(centerX - notchRadius - 4, 8);
    path.quadraticBezierTo(
      centerX - notchRadius,
      8,
      centerX - notchRadius + 4,
      4,
    );
    path.arcToPoint(
      Offset(centerX + notchRadius - 4, 4),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      centerX + notchRadius,
      8,
      centerX + notchRadius + 4,
      8,
    );
    path.lineTo(size.width, 8);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
