import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SevaLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const SevaLogo({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SevaLogoPainter(
          color: color ?? AppTheme.darkGreen,
        ),
      ),
    );
  }
}

class _SevaLogoPainter extends CustomPainter {
  final Color color;

  _SevaLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Draw the bars (scaled to fit the size)
    final barWidth = size.width * 0.2;
    final spacing = size.width * 0.05;
    final maxHeight = size.height * 0.6;
    
    // First bar
    path.addRect(Rect.fromLTWH(
      0,
      size.height - maxHeight * 0.6,
      barWidth,
      maxHeight * 0.6,
    ));
    
    // Second bar
    path.addRect(Rect.fromLTWH(
      barWidth + spacing,
      size.height - maxHeight * 0.8,
      barWidth,
      maxHeight * 0.8,
    ));
    
    // Third bar
    path.addRect(Rect.fromLTWH(
      (barWidth + spacing) * 2,
      size.height - maxHeight,
      barWidth,
      maxHeight,
    ));

    // Draw the leaf parts
    final leafPath = Path();
    final controlPoint1 = Offset(size.width * 0.7, size.height * 0.3);
    final controlPoint2 = Offset(size.width * 0.9, size.height * 0.5);
    final endPoint = Offset(size.width * 0.8, size.height * 0.7);

    leafPath.moveTo(size.width * 0.6, size.height * 0.4);
    leafPath.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    // Second leaf curve
    final leafPath2 = Path();
    final controlPoint3 = Offset(size.width * 0.8, size.height * 0.2);
    final controlPoint4 = Offset(size.width, size.height * 0.4);
    final endPoint2 = Offset(size.width * 0.9, size.height * 0.6);

    leafPath2.moveTo(size.width * 0.7, size.height * 0.3);
    leafPath2.cubicTo(
      controlPoint3.dx,
      controlPoint3.dy,
      controlPoint4.dx,
      controlPoint4.dy,
      endPoint2.dx,
      endPoint2.dy,
    );

    canvas.drawPath(path, paint);
    canvas.drawPath(leafPath, paint);
    canvas.drawPath(leafPath2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 