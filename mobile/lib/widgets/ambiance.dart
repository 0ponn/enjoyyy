import 'dart:math' as math;
import 'package:flutter/material.dart';

class Ambiance extends StatefulWidget {
  const Ambiance({super.key});

  @override
  State<Ambiance> createState() => _AmbianceState();
}

class _AmbianceState extends State<Ambiance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _particles = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initParticles();
  }

  void _initParticles() {
    final size = MediaQuery.of(context).size;
    final count = (size.width * size.height / 25000).round().clamp(5, 30);

    _particles = List.generate(count, (_) => _Particle(
      x: _random.nextDouble() * size.width,
      y: _random.nextDouble() * size.height,
      size: 0.5 + _random.nextDouble() * 1.5,
      opacity: 0.05 + _random.nextDouble() * 0.15,
      speedY: 0.1 + _random.nextDouble() * 0.3,
      wanderPhase: _random.nextDouble() * math.pi * 2,
      wanderSpeed: 0.5 + _random.nextDouble() * 1.0,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _AmbiancePainter(
              particles: _particles,
              time: _controller.value * 20,
              screenHeight: MediaQuery.of(context).size.height,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double opacity;
  final double speedY;
  final double wanderPhase;
  final double wanderSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedY,
    required this.wanderPhase,
    required this.wanderSpeed,
  });
}

class _AmbiancePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final double screenHeight;

  _AmbiancePainter({
    required this.particles,
    required this.time,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update position (slow upward drift)
      particle.y -= particle.speedY;

      // Wrap around
      if (particle.y < -10) {
        particle.y = size.height + 10;
      }

      // Horizontal wander
      final wander = math.sin(time * particle.wanderSpeed + particle.wanderPhase) * 0.5;
      final currentX = particle.x + wander * 10;

      // Draw particle
      final paint = Paint()
        ..color = Color.fromRGBO(200, 195, 180, particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(currentX, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbiancePainter oldDelegate) {
    return true; // Always repaint for animation
  }
}
