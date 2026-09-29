/// One sample linked to a patient.
class Sample {
  final String id;
  final String patientId;
  final String specimenType;
  final String reasonForVisit;
  final DateTime collectionDateTime;
  final DateTime? analysisDateTime;
  final String analysisStatus;

  Sample({
    required this.id,
    required this.patientId,
    required this.specimenType,
    required this.reasonForVisit,
    required this.collectionDateTime,
    this.analysisDateTime,
    required this.analysisStatus,
  });
}