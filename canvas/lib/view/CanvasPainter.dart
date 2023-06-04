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
// Draw the background image
    Size targetSize = Size(
        size.width,
        size.width *
            backgroundImage.height.toDouble() /
            backgroundImage.width.toDouble());
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTRB(
        0,
        0,
        backgroundImage.width.toDouble(),
        backgroundImage.height.toDouble(),
      ),
      Rect.fromLTWH(
          0, 0, targetSize.width, targetSize.height), // Updated this line
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
        // Calculate the distance between the two points
        double distance = (points[i].offset! - points[i + 1].offset!).distance;

        // Calculate the number of line segments needed
        int numSegments = (distance / lineSegmentSize).ceil();

        // Calculate the increments for x and y directions
        double dxIncrement =
            (points[i + 1].offset!.dx - points[i].offset!.dx) / numSegments;
        double dyIncrement =
            (points[i + 1].offset!.dy - points[i].offset!.dy) / numSegments;

        // Draw multiple smaller line segments to create a smoother line
        for (int j = 0; j < numSegments; j++) {
          Offset startPoint = Offset(
            points[i].offset!.dx + dxIncrement * j + canvasOffsetX,
            points[i].offset!.dy + dyIncrement * j + canvasOffsetY,
          );
          Offset endPoint = Offset(
            points[i].offset!.dx + dxIncrement * (j + 1) + canvasOffsetX,
            points[i].offset!.dy + dyIncrement * (j + 1) + canvasOffsetY,
          );

          canvas.drawLine(startPoint, endPoint, _paintDetails);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
