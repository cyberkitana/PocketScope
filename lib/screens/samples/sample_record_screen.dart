import 'package:flutter/material.dart';

import '../../services/database_service.dart';

/// Displays the complete record for one sample.
class SampleRecordScreen extends StatefulWidget {
  final String sampleId;
  final String specimenType;
  final int imageCount;

  const SampleRecordScreen({
    super.key,
    required this.sampleId,
    required this.specimenType,
    required this.imageCount,
  });

  @override
  State<SampleRecordScreen> createState() =>
      _SampleRecordScreenState();
}

class _SampleRecordScreenState
    extends State<SampleRecordScreen> {
  Map<String, dynamic>? sample;
  Map<String, dynamic>? patient;
  List<Map<String, dynamic>> images = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSampleRecord();
  }

  Future<void> loadSampleRecord() async {
    try {
      final loadedSample =
          await DatabaseService.getSample(widget.sampleId);

      if (loadedSample == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
        });

        return;
      }

      final patientId =
          loadedSample['patient_id'] as String;

      final loadedPatient =
          await DatabaseService.getPatient(patientId);

      final loadedImages =
          await DatabaseService.getImagesForSample(
        widget.sampleId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        sample = loadedSample;
        patient = loadedPatient;
        images = loadedImages;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load sample record: $error',
          ),
        ),
      );
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not recorded';
    }

    final dateTime = DateTime.tryParse(dateString);

    if (dateTime == null) {
      return 'Not recorded';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not recorded';
    }

    final dateTime = DateTime.tryParse(dateString);

    if (dateTime == null) {
      return 'Not recorded';
    }

    final day =
        dateTime.day.toString().padLeft(2, '0');
    final month =
        dateTime.month.toString().padLeft(2, '0');
    final hour =
        dateTime.hour.toString().padLeft(2, '0');
    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/${dateTime.year} '
        '$hour:$minute';
  }

  String patientName() {
    if (patient == null) {
      return 'Patient not found';
    }

    return '${patient!['first_name']} '
        '${patient!['surname']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Record'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : sample == null
              ? const Center(
                  child: Text(
                    'Sample record could not be found.',
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sample Record',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Patient',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  patientName(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Patient ID: '
                                  '${sample!['patient_id']}',
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Date of Birth: '
                                  '${formatDate(
                                    patient?[
                                        'date_of_birth'],
                                  )}',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sample Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sample ID: '
                                  '${sample!['id']}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Specimen: '
                                  '${sample!['specimen_type']}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Reason for Visit: '
                                  '${sample!['reason_for_visit']}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Collection: '
                                  '${formatDateTime(
                                    sample![
                                        'collection_date_time'],
                                  )}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Analysis: '
                                  '${formatDateTime(
                                    sample![
                                        'analysis_date_time'],
                                  )}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: '
                                  '${sample!['analysis_status']}',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Images',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${images.length} image(s) '
                                  'associated with this sample.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}