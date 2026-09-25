import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CyberBladeWingsLogo extends StatefulWidget {
  final double size;
  final bool animateStartupScan;
  final Duration animationDuration;

  const CyberBladeWingsLogo({
    super.key,
    this.size = 120.0,
    this.animateStartupScan = false,
    this.animationDuration = const Duration(milliseconds: 2200),
  });

  @override
  State<CyberBladeWingsLogo> createState() => _CyberBladeWingsLogoState();
}

class _CyberBladeWingsLogoState extends State<CyberBladeWingsLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    if (widget.animateStartupScan) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant CyberBladeWingsLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateStartupScan != oldWidget.animateStartupScan) {
      if (widget.animateStartupScan) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: CyberBladeWingsPainter(
            progress: progress,
            isScanning: widget.animateStartupScan && progress < 1.0,
          ),
        );
      },
    );
  }
}

class CyberBladeWingsPainter extends CustomPainter {
  final double progress;
  final bool isScanning;

  CyberBladeWingsPainter({required this.progress, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    const cyberpunkGrey = Color(0xFF8A99AD);

    final ringPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.3 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, width * 0.44, ringPaint);

    final topWingOffsetY = -height * 0.35 * (1.0 - math.min(progress * 1.5, 1.0));

    final topWingPath = Path()
      ..moveTo(width * 0.12, height * 0.35 + topWingOffsetY)
      ..lineTo(width * 0.40, height * 0.50 + topWingOffsetY)
      ..lineTo(width * 0.50, height * 0.18 + topWingOffsetY)
      ..lineTo(width * 0.60, height * 0.50 + topWingOffsetY)
      ..lineTo(width * 0.88, height * 0.35 + topWingOffsetY)
      ..lineTo(width * 0.50, height * 0.38 + topWingOffsetY)
      ..close();

    final topWingPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          isScanning ? cyberpunkGrey : AppTheme.primary,
          AppTheme.accent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(topWingPath, topWingPaint);

    final bottomWingOffsetY = height * 0.35 * (1.0 - math.min(progress * 1.5, 1.0));

    final bottomWingPath = Path()
      ..moveTo(width * 0.20, height * 0.65 + bottomWingOffsetY)
      ..lineTo(width * 0.40, height * 0.50 + bottomWingOffsetY)
      ..lineTo(width * 0.50, height * 0.82 + bottomWingOffsetY)
      ..lineTo(width * 0.60, height * 0.50 + bottomWingOffsetY)
      ..lineTo(width * 0.80, height * 0.65 + bottomWingOffsetY)
      ..lineTo(width * 0.50, height * 0.62 + bottomWingOffsetY)
      ..close();

    final bottomWingPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primary,
          isScanning ? cyberpunkGrey : AppTheme.accent,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(bottomWingPath, bottomWingPaint);

    final diamondPath = Path()
      ..moveTo(width * 0.50, height * 0.30)
      ..lineTo(width * 0.60, height * 0.50)
      ..lineTo(width * 0.50, height * 0.70)
      ..lineTo(width * 0.40, height * 0.50)
      ..close();

    final diamondFill = Paint()..color = AppTheme.accent;
    final diamondStroke = Paint()
      ..color = isScanning ? cyberpunkGrey : AppTheme.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(diamondPath, diamondFill);
    canvas.drawPath(diamondPath, diamondStroke);

    if (isScanning) {
      final scanY = height * 0.20 + (progress * height * 0.60);

      final scanBeamPaint = Paint()
        ..color = cyberpunkGrey
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5);

      canvas.drawLine(
        Offset(width * 0.25, scanY),
        Offset(width * 0.75, scanY),
        scanBeamPaint,
      );
    }

    final corePaint = Paint()..color = AppTheme.background;
    canvas.drawCircle(center, width * 0.05, corePaint);
  }

  @override
  bool shouldRepaint(covariant CyberBladeWingsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isScanning != isScanning;
  }
}
