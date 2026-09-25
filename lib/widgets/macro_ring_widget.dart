import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MacroRingWidget extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  final double size;

  const MacroRingWidget({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    final over = value > goal;

    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [

                CustomPaint(
                  size: Size(size, size),
                  painter: _RingPainter(
                    progress: pct,
                    color: color,
                    trackColor: color.withValues(alpha: 0.12),
                    strokeWidth: size * 0.09,
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${value.toStringAsFixed(0)}g',
                      style: TextStyle(
                        color: over ? color : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.19,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/ ${goal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: size * 0.13,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}
