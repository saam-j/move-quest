import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AdventureBackdrop extends StatelessWidget {
  const AdventureBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _ForestPainter()),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB8071812),
                Color(0x33102419),
                Color(0xCC071812),
              ],
              stops: [0, 0.52, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ForestPainter extends CustomPainter {
  const _ForestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF173D2C), AppTheme.forest, AppTheme.background],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.teal.withValues(alpha: 0.15),
          AppTheme.teal.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.32),
          radius: size.width * 0.31,
        ),
      );
    canvas.drawRect(rect, glow);

    final moonPaint = Paint()..color = AppTheme.lime.withValues(alpha: 0.7);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.27),
      size.shortestSide * 0.065,
      moonPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.27),
      size.shortestSide * 0.095,
      Paint()..color = AppTheme.lime.withValues(alpha: 0.06),
    );

    _drawRidge(
      canvas,
      size,
      size.height * 0.62,
      const Color(0xFF153527),
      0.025,
      0.055,
    );
    _drawRidge(
      canvas,
      size,
      size.height * 0.72,
      const Color(0xFF102A20),
      0.04,
      0.035,
    );

    final treeColor = Paint()..color = const Color(0xFF0B2118);
    for (var i = 0; i < 13; i++) {
      final x = size.width * i / 12;
      final variation = (i % 3) * size.height * 0.035;
      _drawPine(
        canvas,
        Offset(x, size.height * 0.87 + variation),
        size.height * (0.26 + (i % 2) * 0.08),
        treeColor,
      );
    }
  }

  void _drawRidge(
    Canvas canvas,
    Size size,
    double baseline,
    Color color,
    double firstPeak,
    double secondPeak,
  ) {
    final path = Path()
      ..moveTo(0, baseline)
      ..cubicTo(
        size.width * 0.16,
        baseline - size.height * firstPeak,
        size.width * 0.2,
        baseline + size.height * secondPeak,
        size.width * 0.38,
        baseline - size.height * 0.02,
      )
      ..cubicTo(
        size.width * 0.61,
        baseline - size.height * 0.12,
        size.width * 0.72,
        baseline + size.height * 0.04,
        size.width,
        baseline - size.height * 0.055,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawPine(Canvas canvas, Offset base, double height, Paint paint) {
    final trunk = Paint()..color = paint.color;
    final path = Path()
      ..moveTo(base.dx, base.dy - height)
      ..lineTo(base.dx - height * 0.34, base.dy - height * 0.34)
      ..lineTo(base.dx - height * 0.16, base.dy - height * 0.34)
      ..lineTo(base.dx - height * 0.44, base.dy - height * 0.04)
      ..lineTo(base.dx + height * 0.44, base.dy - height * 0.04)
      ..lineTo(base.dx + height * 0.16, base.dy - height * 0.34)
      ..lineTo(base.dx + height * 0.34, base.dy - height * 0.34)
      ..close();
    canvas.drawPath(path, trunk);
  }

  @override
  bool shouldRepaint(covariant _ForestPainter oldDelegate) => false;
}
