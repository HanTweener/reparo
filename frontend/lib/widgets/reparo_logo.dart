import 'package:flutter/material.dart';
import '../theme/reparo_theme.dart';

/// Pixel-perfect native vector logo for Reparo (Concept 1: Precision Monogram R).
/// Zero asset bundle dependencies, crisp on high-DPI screens.
class ReparoLogo extends StatelessWidget {
  final double size;
  final bool showPlate;
  final bool darkPlate;

  const ReparoLogo({
    super.key,
    this.size = 24.0,
    this.showPlate = true,
    this.darkPlate = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ReparoLogoPainter(
          showPlate: showPlate,
          darkPlate: darkPlate,
        ),
      ),
    );
  }
}

class _ReparoLogoPainter extends CustomPainter {
  final bool showPlate;
  final bool darkPlate;

  _ReparoLogoPainter({
    required this.showPlate,
    required this.darkPlate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double scale = s / 512.0;

    // 1. Base Plate
    if (showPlate) {
      final plateRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(16 * scale, 16 * scale, 480 * scale, 480 * scale),
        Radius.circular(112 * scale),
      );

      final bgPaint = Paint()
        ..color = darkPlate ? ReparoTheme.actionPrimary : ReparoTheme.frame
        ..style = PaintingStyle.fill;
      canvas.drawRRect(plateRect, bgPaint);

      final borderPaint = Paint()
        ..color = darkPlate ? ReparoTheme.textMuted : ReparoTheme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale;
      canvas.drawRRect(plateRect, borderPaint);
    }

    final Color glyphColor = darkPlate ? Colors.white : ReparoTheme.textPrimary;
    const Color accentColor = ReparoTheme.accent;

    // 2. R Spine (Vertical Bar)
    final spineRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(120 * scale, 110 * scale, 60 * scale, 292 * scale),
      Radius.circular(16 * scale),
    );
    final spinePaint = Paint()
      ..color = glyphColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(spineRect, spinePaint);

    // 3. Upper Loop (Stroked Arch)
    final loopPath = Path()
      ..moveTo(170 * scale, 110 * scale)
      ..lineTo(270 * scale, 110 * scale)
      ..arcToPoint(
        Offset(270 * scale, 300 * scale),
        radius: Radius.circular(95 * scale),
        clockwise: true,
      )
      ..lineTo(170 * scale, 300 * scale);

    final loopPaint = Paint()
      ..color = glyphColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(loopPath, loopPaint);

    // 4. Precision Diagonal Leg (Deep Teal Accent)
    final legPath = Path()
      ..moveTo(230 * scale, 260 * scale)
      ..lineTo(320 * scale, 260 * scale)
      ..lineTo(400 * scale, 402 * scale)
      ..lineTo(325 * scale, 402 * scale)
      ..close();

    final legPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(legPath, legPaint);

    // 5. Calibration Aperture Dot (Micro-point)
    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(270 * scale, 205 * scale), 20 * scale, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ReparoLogoPainter oldDelegate) {
    return oldDelegate.showPlate != showPlate || oldDelegate.darkPlate != darkPlate;
  }
}
