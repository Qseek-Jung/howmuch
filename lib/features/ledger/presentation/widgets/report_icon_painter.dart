import 'dart:math';
import 'package:flutter/material.dart';

class ReportIconPainter extends CustomPainter {
  final bool isDark;

  ReportIconPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // Segment 1: Primary Green (40%)
    paint.color = const Color(0xFF34C759); // iOS Green
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at top
      2 * pi * 0.4,
      true,
      paint,
    );

    // Segment 2: Blue (30%)
    paint.color = const Color(0xFF007AFF); // iOS Blue
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + (2 * pi * 0.4),
      2 * pi * 0.3,
      true,
      paint,
    );

    // Segment 3: Orange (30%)
    paint.color = const Color(0xFFFF9500); // iOS Orange
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + (2 * pi * 0.7),
      2 * pi * 0.3,
      true,
      paint,
    );

    // Optional: Hole in middle (Donut)
    // paint.color = isDark ? const Color(0xFF1C1C1E) : Colors.white; // Background color
    // canvas.drawCircle(center, radius * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
