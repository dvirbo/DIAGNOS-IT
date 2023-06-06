import 'package:canvas/models/CanvasPoint.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CanvasPainter extends CustomPainter {
  final List<CanvasPoint> points;
  final Paint _paintDetails;
  final ui.Image backgroundImage;
  final double lineSegmentSize = 3.0; // Set the distance between line segments

  CanvasPainter({required this.points, required this.backgroundImage})
      : _paintDetails = Paint()
          ..color = Colors.black
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage,
        Offset.zero &
            Size(backgroundImage.width.toDouble(),
                backgroundImage.height.toDouble()),
        Offset.zero & size,
        _paintDetails,
      );
    }

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          _paintDetails,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

