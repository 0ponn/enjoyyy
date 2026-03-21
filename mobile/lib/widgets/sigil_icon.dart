import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/witch_colors.dart';

class SigilIcon extends StatelessWidget {
  final Sigil sigil;
  final double size;
  final Color? color;

  const SigilIcon({
    super.key,
    required this.sigil,
    this.size = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SigilPainter(
        sigil: sigil,
        color: color ?? WitchColors.plum400,
      ),
    );
  }
}

class _SigilPainter extends CustomPainter {
  final Sigil sigil;
  final Color color;

  _SigilPainter({required this.sigil, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    switch (sigil) {
      case Sigil.spiral:
        _drawSpiral(canvas, center, radius, paint);
        break;
      case Sigil.eye:
        _drawEye(canvas, center, radius, paint);
        break;
      case Sigil.triangle:
        _drawTriangle(canvas, center, radius, paint);
        break;
      case Sigil.cross:
        _drawCross(canvas, center, radius, paint);
        break;
      case Sigil.diamond:
        _drawDiamond(canvas, center, radius, paint);
        break;
    }
  }

  void _drawSpiral(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const turns = 2.5;
    const steps = 50;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = t * turns * 2 * 3.14159;
      final r = t * radius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawEye(Canvas canvas, Offset center, double radius, Paint paint) {
    // Outer almond shape
    final path = Path();
    path.moveTo(center.dx - radius, center.dy);
    path.quadraticBezierTo(
      center.dx,
      center.dy - radius * 0.8,
      center.dx + radius,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy + radius * 0.8,
      center.dx - radius,
      center.dy,
    );
    canvas.drawPath(path, paint);

    // Inner circle (pupil)
    canvas.drawCircle(center, radius * 0.35, paint);
  }

  void _drawTriangle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius * 0.866, center.dy + radius * 0.5);
    path.lineTo(center.dx - radius * 0.866, center.dy + radius * 0.5);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCross(Canvas canvas, Offset center, double radius, Paint paint) {
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
  }

  void _drawDiamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius, center.dy);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SigilPainter oldDelegate) {
    return sigil != oldDelegate.sigil || color != oldDelegate.color;
  }
}
