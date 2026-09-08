import 'dart:math' as math;
import 'package:flutter/material.dart';

class SuperSaiyanAura extends StatefulWidget {
  final double size;
  final Color color;
  final bool isActive;

  const SuperSaiyanAura({
    super.key,
    required this.size,
    required this.color,
    required this.isActive,
  });

  @override
  State<SuperSaiyanAura> createState() => _SuperSaiyanAuraState();
}

class _SuperSaiyanAuraState extends State<SuperSaiyanAura> with SingleTickerProviderStateMixin {
  late AnimationController _controller; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // very fast pulse for DBZ feel
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SuperSaiyanAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.animateTo(0.0, duration: const Duration(milliseconds: 500));
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AuraPainter(
            color: widget.color,
            progress: _controller.value,
            isActive: widget.isActive || _controller.value > 0,
          ),
        );
      },
    );
  }
}

class _AuraPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isActive;

  _AuraPainter({
    required this.color,
    required this.progress,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive && progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.0;
    
    // Draw glowing backdrop
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.3 + (0.3 * progress))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);
    canvas.drawCircle(center, maxRadius * 0.7 + (progress * 15), bgPaint);

    // We use the progress to drive a smooth sine wave for the spikes
    final time = progress * 2 * math.pi * 3; // 3 full cycles per animation loop
    final numSpikes = 32;
    
    // Outer Aura
    final path = Path();
    for (int i = 0; i < numSpikes; i++) {
      final angle = (i * 2 * math.pi) / numSpikes;
      
      // Undulate smoothly based on time and spike index
      final undulation = math.sin(time + i * 1.5) * 0.5 + 0.5; // 0.0 to 1.0
      
      final spikeLength = maxRadius * 0.6 + (maxRadius * 0.4) * (0.5 + undulation * 0.5);
      final jitter = math.cos(time * 1.5 + i) * 0.1;
      final finalAngle = angle + jitter;
      
      final point = Offset(
        center.dx + math.cos(finalAngle) * spikeLength,
        center.dy + math.sin(finalAngle) * spikeLength,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final paint = Paint()
      ..color = color.withValues(alpha: 0.7 + (math.sin(time) * 0.1))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    canvas.drawPath(path, paint);

    // Inner Aura
    final innerPath = Path();
    for (int i = 0; i < numSpikes; i++) {
      final angle = (i * 2 * math.pi) / numSpikes;
      
      // Inner undulation is slightly offset
      final undulation = math.sin(time * 1.2 + i * 1.3) * 0.5 + 0.5;
      
      final spikeLength = maxRadius * 0.5 + (maxRadius * 0.2) * (0.6 + undulation * 0.4);
      final jitter = math.sin(time * 1.2 + i) * 0.1;
      final finalAngle = angle + jitter;
      
      final point = Offset(
        center.dx + math.cos(finalAngle) * spikeLength,
        center.dy + math.sin(finalAngle) * spikeLength,
      );

      if (i == 0) {
        innerPath.moveTo(point.dx, point.dy);
      } else {
        innerPath.lineTo(point.dx, point.dy);
      }
    }
    innerPath.close();

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 + 0.4 * progress)
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.isActive != isActive;
  }
}
