/// Result produced by the sample analysis pipeline.
class AnalysisResult {
  final String sampleId;
  final DateTime analysisDateTime;
  final String analysisStatus;
  final List<String> detectedFeatures;
  final String screeningResult;
  final double? confidence;

  AnalysisResult({
    required this.sampleId,
    required this.analysisDateTime,
    required this.analysisStatus,
    required this.detectedFeatures,
    required this.screeningResult,
    this.confidence,
  });
}