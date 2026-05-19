import 'package:flutter/material.dart';
import 'dart:math' as math;

class ConfettiWidget extends StatefulWidget {
  const ConfettiWidget({super.key});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      })..forward();

    for (int i = 0; i < 80; i++) {
      _particles.add(_ConfettiParticle(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConfettiPainter(particles: _particles),
      size: Size.infinite,
    );
  }
}

class _ConfettiParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double size;
  late Color color;
  late double rotation;
  late double rotationSpeed;

  final List<Color> colors = [
    Colors.red, Colors.blue, Colors.green, Colors.yellow, 
    Colors.orange, Colors.purple, Colors.pink, Colors.cyan
  ];

  _ConfettiParticle(math.Random random) {
    x = random.nextDouble() * 400; // Approximate width
    y = -random.nextDouble() * 200;
    vx = (random.nextDouble() - 0.5) * 5;
    vy = random.nextDouble() * 8 + 4;
    size = random.nextDouble() * 8 + 4;
    color = colors[random.nextInt(colors.length)];
    rotation = random.nextDouble() * math.pi * 2;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.2;
  }

  void update() {
    x += vx;
    y += vy;
    rotation += rotationSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.y > size.height) continue;
      
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(p.x % size.width, p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(Rect.fromLTWH(-p.size / 2, -p.size / 2, p.size, p.size), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
