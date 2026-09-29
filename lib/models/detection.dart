/// Represents one feature detected within a sample image.
///
/// The coordinates describe the bounding box drawn around
/// the detected feature.
class Detection {
  final String imageId;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final double? confidence;

  Detection({
    required this.imageId,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence,
  });
}