import 'package:flutter/material.dart';

class TreeEvolution extends StatelessWidget {
  final int stage;
  final double size;

  const TreeEvolution({
    super.key,
    required this.stage,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TreePainter(stage: stage),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  final int stage;

  _TreePainter({required this.stage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()..color = const Color(0xFFEAF3DE);
    canvas.drawCircle(center, radius, bgPaint);

    final trunkPaint = Paint()..color = const Color(0xFF854F0B);
    final leafPaint = Paint()..color = const Color(0xFF2D6A2D);
    final darkLeafPaint = Paint()..color = const Color(0xFF3B6D11);
    final fruitPaint = Paint()..color = const Color(0xFFFAC775);

    switch (stage) {
      case 1: // Graine
        canvas.drawCircle(Offset(center.dx, center.dy + 5), 3, trunkPaint);
        break;
      case 2: // Jeune Pousse
        canvas.drawRect(Rect.fromLTWH(center.dx - 1.5, center.dy + 2, 3, 8), trunkPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx - 4, center.dy - 6, 8, 10), leafPaint);
        break;
      case 3: // Arbrisseau
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - 2, center.dy + 5, 4, 12), const Radius.circular(1)), trunkPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx - 10, center.dy - 10, 20, 18), leafPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx - 14, center.dy - 2, 12, 10), darkLeafPaint);
        break;
      case 4: // Arbre Majeur
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - 3, center.dy + 10, 6, 12), const Radius.circular(2)), trunkPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx - 15, center.dy - 15, 30, 26), leafPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx - 22, center.dy - 2, 16, 14), darkLeafPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx + 6, center.dy - 2, 16, 14), darkLeafPaint);
        break;
      case 5: // Baobab Sacré
      default:
        // Tronçon massif
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - 6, center.dy + 8, 12, 15), const Radius.circular(3)), trunkPaint);
        // Couronne dense
        canvas.drawOval(Rect.fromLTWH(center.dx - 20, center.dy - 22, 40, 32), leafPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx - 28, center.dy - 8, 20, 18), darkLeafPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx + 8, center.dy - 8, 20, 18), darkLeafPaint);
        canvas.drawOval(Rect.fromLTWH(center.dx - 12, center.dy + 2, 24, 16), leafPaint);
        
        // Quelques "fruits" ou fleurs (jaune)
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - 25)
            ..lineTo(center.dx + 3, center.dy - 20)
            ..lineTo(center.dx - 3, center.dy - 20)
            ..close(),
          fruitPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
