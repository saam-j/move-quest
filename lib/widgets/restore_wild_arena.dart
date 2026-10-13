import 'package:flutter/material.dart';

import '../gameplay/restore_wild_engine.dart';
import '../theme/app_theme.dart';

class RestoreWildArena extends StatelessWidget {
  const RestoreWildArena({
    super.key,
    required this.engine,
    required this.modeAccent,
  });

  final RestoreWildEngine engine;
  final Color modeAccent;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _RestoreWildPainter(engine: engine, modeAccent: modeAccent),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RestoreWildPainter extends CustomPainter {
  const _RestoreWildPainter({required this.engine, required this.modeAccent});

  final RestoreWildEngine engine;
  final Color modeAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(24)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF163A2A), Color(0xFF0B2018), Color(0xFF071812)],
        ).createShader(bounds),
    );

    final horizon = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.teal.withValues(alpha: 0.19),
          AppTheme.teal.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.32),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawRect(bounds, horizon);

    final pathLine = Paint()
      ..color = AppTheme.teal.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var lane = 1; lane < 3; lane++) {
      final x = size.width * lane / 3;
      canvas.drawLine(
        Offset(x, size.height * 0.06),
        Offset(x, size.height * 0.95),
        pathLine,
      );
    }

    _drawForest(canvas, size);
    _drawReachLine(canvas, size);
    for (final item in engine.items) {
      final center = Offset(
        size.width * (item.lane + 0.5) / 3,
        size.height * item.y,
      );
      if (item.type == ForestItemType.energy) {
        _drawOrb(canvas, center, size.shortestSide * 0.044, item.id);
      } else {
        _drawThorns(canvas, center, size.shortestSide * 0.052);
      }
    }
    _drawExplorer(
      canvas,
      Offset(size.width * (engine.lane + 0.5) / 3, size.height * 0.83),
      size.shortestSide * 0.08,
      modeAccent,
    );
  }

  void _drawForest(Canvas canvas, Size size) {
    final ground = Path()
      ..moveTo(0, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.56,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      ground,
      Paint()..color = const Color(0x66335532),
    );

    final treePaint = Paint()..color = const Color(0x77203C2A);
    for (var lane = 0; lane < 3; lane++) {
      for (var side = 0; side < 2; side++) {
        final x = size.width * lane / 3 + size.width * (0.08 + side * 0.23);
        final top = size.height * (0.18 + ((lane + side) % 3) * 0.09);
        final tree = Path()
          ..moveTo(x, top)
          ..lineTo(x - size.width * 0.045, top + size.height * 0.16)
          ..lineTo(x - size.width * 0.019, top + size.height * 0.15)
          ..lineTo(x - size.width * 0.065, top + size.height * 0.27)
          ..lineTo(x + size.width * 0.065, top + size.height * 0.27)
          ..lineTo(x + size.width * 0.019, top + size.height * 0.15)
          ..lineTo(x + size.width * 0.045, top + size.height * 0.16)
          ..close();
        canvas.drawPath(tree, treePaint);
      }
    }
  }

  void _drawReachLine(Canvas canvas, Size size) {
    final y = size.height * 0.82;
    final paint = Paint()
      ..color = AppTheme.lime.withValues(alpha: 0.48)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    for (var lane = 0; lane < 3; lane++) {
      final center = size.width * (lane + 0.5) / 3;
      canvas.drawCircle(
        Offset(center, y),
        5,
        Paint()..color = AppTheme.lime.withValues(alpha: 0.82),
      );
    }
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, int id) {
    canvas.drawCircle(
      center,
      radius * 2.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.teal.withValues(alpha: 0.32),
            AppTheme.teal.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [Color(0xFFF2FFE0), AppTheme.lime, AppTheme.teal],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.24, -radius * 0.24),
      radius * 0.13,
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );
    if (id.isEven) {
      final sparkle = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center.translate(radius * 1.45, -radius * 0.6),
        center.translate(radius * 1.45, radius * 0.6),
        sparkle,
      );
      canvas.drawLine(
        center.translate(radius * 1.15, 0),
        center.translate(radius * 1.75, 0),
        sparkle,
      );
    }
  }

  void _drawThorns(Canvas canvas, Offset center, double radius) {
    final shadow = Paint()..color = const Color(0x885D6C43);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.5),
        width: radius * 2.6,
        height: radius * 0.7,
      ),
      shadow,
    );
    final thorns = Path();
    for (var spike = 0; spike < 5; spike++) {
      final x = center.dx - radius + spike * radius * 0.5;
      thorns
        ..moveTo(x, center.dy + radius * 0.5)
        ..lineTo(x + radius * 0.25, center.dy - radius * 0.7)
        ..lineTo(x + radius * 0.58, center.dy + radius * 0.5);
    }
    canvas.drawPath(
      thorns,
      Paint()
        ..color = const Color(0xFFD6AE72)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, radius * 0.3),
          width: radius * 2.3,
          height: radius * 0.7,
        ),
        Radius.circular(radius * 0.3),
      ),
      Paint()..color = const Color(0xFF9E7D52),
    );
  }

  void _drawExplorer(
    Canvas canvas,
    Offset center,
    double radius,
    Color accent,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.92),
        width: radius * 2.5,
        height: radius * 0.6,
      ),
      Paint()..color = accent.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      center.translate(0, -radius * 0.72),
      radius * 0.34,
      Paint()..color = AppTheme.textPrimary,
    );
    final body = Path()
      ..moveTo(center.dx - radius * 0.16, center.dy - radius * 0.3)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radius * 0.48,
        center.dx + radius * 0.16,
        center.dy - radius * 0.3,
      )
      ..lineTo(center.dx + radius * 0.44, center.dy + radius * 0.36)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.62,
        center.dx - radius * 0.44,
        center.dy + radius * 0.36,
      )
      ..close();
    canvas.drawPath(body, Paint()..color = accent);
    final limbs = Paint()
      ..color = accent
      ..strokeWidth = radius * 0.15
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(-radius * 0.1, radius * 0.08),
      center.translate(-radius * 0.6, radius * 0.4),
      limbs,
    );
    canvas.drawLine(
      center.translate(radius * 0.1, radius * 0.08),
      center.translate(radius * 0.6, radius * 0.4),
      limbs,
    );
  }

  @override
  bool shouldRepaint(covariant _RestoreWildPainter oldDelegate) => true;
}
