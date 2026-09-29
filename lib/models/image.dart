/// An image associated with a sample.
class SampleImage {
  final String id;
  final String sampleId;
  final String filePath;
  final DateTime capturedAt;
  final String status;

  SampleImage({
    required this.id,
    required this.sampleId,
    required this.filePath,
    required this.capturedAt,
    required this.status,
  });
}