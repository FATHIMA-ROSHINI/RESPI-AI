import 'dart:math' as math;
import 'package:flutter/material.dart';

class MedicalGauge extends StatelessWidget {
  final double score; // 0-10
  final String classification;
  const MedicalGauge({
    super.key,
    required this.score,
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 140,
          child: AspectRatio(
            aspectRatio: 2,
            child: CustomPaint(painter: _GaugePainter(score: score)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
            letterSpacing: -2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          classification.toUpperCase(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _getRiskColor(score),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'RESPIRATORY RISK SCORE (0-10)',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(double score) {
    if (score >= 7) return const Color(0xFFEF4444); // Red 500
    if (score >= 4) return const Color(0xFFF59E0B); // Amber 500
    return const Color(0xFF10B981); // Emerald 500
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  _GaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2, size.height);
    final center = Offset(size.width / 2, size.height);
    final rect = Rect.fromCircle(center: center, radius: radius - 12);

    // 1. Draw Subtle Background Arc (Segmented)
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    // 2. Draw Risk Zone Indicator (Segments)
    _drawSegments(canvas, rect);

    // 3. Draw Main Progress Gradient Arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = (math.pi * (math.min(score, 10.0) / 10));
    canvas.drawArc(rect, math.pi, sweepAngle, false, progressPaint);

    // 4. Draw Needle / Pointer
    _drawNeedle(canvas, center, radius, sweepAngle);

    // 5. Draw Hub
    final hubPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 6, hubPaint);
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF0F172A));
  }

  void _drawSegments(Canvas canvas, Rect rect) {
    final segmentPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const int segments = 10;
    for (int i = 1; i < segments; i++) {
      final double angle = math.pi + (math.pi * i / segments);
      final double x1 =
          rect.center.dx + (rect.width / 2 - 16) * math.cos(angle);
      final double y1 =
          rect.center.dy + (rect.width / 2 - 16) * math.sin(angle);
      final double x2 = rect.center.dx + (rect.width / 2 + 4) * math.cos(angle);
      final double y2 = rect.center.dy + (rect.width / 2 + 4) * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), segmentPaint);
    }
  }

  void _drawNeedle(
    Canvas canvas,
    Offset center,
    double radius,
    double sweepAngle,
  ) {
    final double angle = math.pi + sweepAngle;
    final double needleLen = radius - 20;

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final Offset needleTip = Offset(
      center.dx + needleLen * math.cos(angle),
      center.dy + needleLen * math.sin(angle),
    );

    canvas.drawLine(center, needleTip, needlePaint);

    // Needle Tip Point
    canvas.drawCircle(needleTip, 4, Paint()..color = Colors.white);
    canvas.drawCircle(needleTip, 2, Paint()..color = const Color(0xFF3B82F6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
