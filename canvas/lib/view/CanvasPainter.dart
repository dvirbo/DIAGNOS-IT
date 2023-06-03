
import 'package:canvas/models/CanvasPoint.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';


class CanvasPainter extends CustomPainter {
  final List<CanvasPoint> points;
  final Paint _paintDetails;
  final ui.Image backgroundImage;

  CanvasPainter({required this.points, required this.backgroundImage})
      : _paintDetails = Paint()
          ..color = Colors.black
          ..isAntiAlias = true
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the background image
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTRB(
        0,
        0,
        backgroundImage.width.toDouble(),
        backgroundImage.height.toDouble(),
      ),
      Rect.fromLTRB(0, 0, size.width, size.height),
      Paint(),
    );

    // Calculate the available space for drawing
    double canvasWidth = size.width;
    double canvasHeight = size.height - backgroundImage.height.toDouble();
    double canvasOffsetX = (size.width - backgroundImage.width.toDouble()) / 2;
    double canvasOffsetY = backgroundImage.height.toDouble();

    // Draw the canvas points
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          Offset(
            points[i].offset!.dx + canvasOffsetX,
            points[i].offset!.dy + canvasOffsetY,
          ),
          Offset(
            points[i + 1].offset!.dx + canvasOffsetX,
            points[i + 1].offset!.dy + canvasOffsetY,
          ),
          _paintDetails,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
