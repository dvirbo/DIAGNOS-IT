import 'dart:ui' show Offset;

class CanvasPoint {
  final Offset? offset;
  final double tiltX;
  final double tiltY;

  CanvasPoint({
    required this.offset,
    required this.tiltX,
    required this.tiltY,
  });
}
