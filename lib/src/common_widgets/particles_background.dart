import 'dart:math';
import 'package:flutter/material.dart';

class ParticlesBackground extends StatefulWidget {
  final Widget child;
  final Color particleColor;
  final Color backgroundColor;
  final Color backgroundColorEnd;
  final int particleCount;

  const ParticlesBackground({
    super.key,
    required this.child,
    this.particleColor = const Color(0xFFFC6E28),
    this.backgroundColor = const Color(0xFF1A1A2E),
    this.backgroundColorEnd = const Color(0xFF16213E),
    this.particleCount = 60,
  });

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  Offset _mousePosition = Offset.zero;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _particles = List.generate(widget.particleCount, (_) => _Particle(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              for (final p in _particles) {
                p.update(_mousePosition, size);
              }
              return CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  bgColor: widget.backgroundColor,
                  bgColorEnd: widget.backgroundColorEnd,
                  particleColor: widget.particleColor,
                ),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}

class _Particle {
  late double x, y;
  late double vx, vy;
  late double radius;
  late double opacity;
  final Random _random;

  _Particle(this._random) {
    _reset();
  }

  void _reset() {
    x = _random.nextDouble();
    y = _random.nextDouble();
    vx = (_random.nextDouble() - 0.5) * 0.0003;
    vy = (_random.nextDouble() - 0.5) * 0.0003;
    radius = _random.nextDouble() * 3 + 1;
    opacity = _random.nextDouble() * 0.5 + 0.1;
  }

  void update(Offset mousePosition, Size screenSize) {
    // Move naturally
    x += vx;
    y += vy;

    // Mouse repulsion
    if (screenSize != Size.zero) {
      final mouseX = mousePosition.dx / screenSize.width;
      final mouseY = mousePosition.dy / screenSize.height;
      final dx = x - mouseX;
      final dy = y - mouseY;
      final dist = sqrt(dx * dx + dy * dy);
      const repelRadius = 0.12;

      if (dist < repelRadius && dist > 0) {
        final force = (repelRadius - dist) / repelRadius;
        // Atração: puxa em direção ao mouse (sinal invertido)
        vx -= (dx / dist) * force * 0.0006;
        vy -= (dy / dist) * force * 0.0006;
      }
    }

    // Speed damping
    vx *= 0.98;
    vy *= 0.98;

    // Wrap around edges
    if (x < 0) x = 1.0;
    if (x > 1) x = 0.0;
    if (y < 0) y = 1.0;
    if (y > 1) y = 0.0;
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color bgColor;
  final Color bgColorEnd;
  final Color particleColor;

  _ParticlesPainter({
    required this.particles,
    required this.bgColor,
    required this.bgColorEnd,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgColor, bgColorEnd],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw lines between close particles
    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        final dx = (p1.x - p2.x) * size.width;
        final dy = (p1.y - p2.y) * size.height;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < 120) {
          final alpha = ((1 - dist / 120) * 100).clamp(0, 100).toInt();
          linePaint.color = particleColor.withAlpha(alpha);
          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            linePaint,
          );
        }
      }
    }

    // Draw particles
    for (final p in particles) {
      final dotPaint = Paint()
        ..color = particleColor.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      // Glow effect
      final glowPaint = Paint()
        ..color = particleColor.withValues(alpha: p.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final offset = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(offset, p.radius * 2.5, glowPaint);
      canvas.drawCircle(offset, p.radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
