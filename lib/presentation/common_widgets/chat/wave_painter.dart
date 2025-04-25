import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final waveHeight = size.height * 0.2 * animationValue;
    final waveWidth = size.width / 2;

    path.moveTo(0, size.height / 2);
    for (double i = 0; i <= size.width; i += waveWidth) {
      path.quadraticBezierTo(
        i + waveWidth / 4,
        size.height / 2 - waveHeight,
        i + waveWidth / 2,
        size.height / 2,
      );
      path.quadraticBezierTo(
        i + waveWidth * 3 / 4,
        size.height / 2 + waveHeight,
        i + waveWidth,
        size.height / 2,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
