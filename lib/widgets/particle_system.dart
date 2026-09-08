import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A particle system for the 3D meal-logged celebration.
/// Emits colored confetti/energy particles that explode outward.
class ParticleSystem extends StatefulWidget {
  final Color baseColor;
  final int count;
  final double size;

  const ParticleSystem({
    super.key,
    required this.baseColor,
    this.count = 30,
    this.size = 300,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.count, (_) => _Particle(_rng, widget.baseColor));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
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
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double radius;
  final Color color;
  final double size;
  final bool isSquare;

  _Particle(math.Random rng, Color baseColor)
      : angle = rng.nextDouble() * 2 * math.pi,
        speed = 0.4 + rng.nextDouble() * 0.6,
        radius = 0.0,
        color = Color.lerp(
          baseColor,
          [Colors.white, Colors.yellow, Colors.orangeAccent, Colors.pinkAccent][rng.nextInt(4)],
          rng.nextDouble() * 0.5,
        )!,
        size = 4 + rng.nextDouble() * 6,
        isSquare = rng.nextBool();
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDist = size.width * 0.5;

    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final eased = Curves.easeOut.transform(t);
      final dist = eased * maxDist;
      final opacity = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      final x = center.dx + math.cos(p.angle) * dist;
      final y = center.dy + math.sin(p.angle) * dist;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (p.isSquare) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * 4 * math.pi * (p.angle > math.pi ? 1 : -1));
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x, y), p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}
