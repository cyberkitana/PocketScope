import 'package:flutter/material.dart';

import '../../services/database_service.dart';
import '../samples/new_sample_screen.dart';
import '../samples/sample_record_screen.dart';

/// Displays the complete record for one patient.
class IndividualPatientRecord extends StatefulWidget {
  final String patientId;

  const IndividualPatientRecord({
    super.key,
    required this.patientId,
  });

  @override
  State<IndividualPatientRecord> createState() =>
      _IndividualPatientRecordState();
}

class _IndividualPatientRecordState
    extends State<IndividualPatientRecord> {
  Map<String, dynamic>? patient;
  List<Map<String, dynamic>> samples = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPatientRecord();
  }

  Future<void> loadPatientRecord() async {
    try {
      final loadedPatient =
          await DatabaseService.getPatient(
        widget.patientId,
      );

      final loadedSamples =
          await DatabaseService.getSamplesForPatient(
        widget.patientId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        patient = loadedPatient;
        samples = loadedSamples;
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
            'Unable to load patient record: $error',
          ),
        ),
      );
    }
  }

  String patientName() {
    if (patient == null) {
      return 'Patient';
    }

    return '${patient!['first_name']} '
        '${patient!['surname']}';
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not recorded';
    }

    final date = DateTime.tryParse(dateString);

    if (date == null) {
      return 'Not recorded';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not recorded';
    }

    final date = DateTime.tryParse(dateString);

    if (date == null) {
      return 'Not recorded';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }

  Future<void> openNewSample() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NewSampleScreen(
          patientId: widget.patientId,
        ),
      ),
    );

    await loadPatientRecord();
  }

  Future<void> openSample(
    Map<String, dynamic> sample,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SampleRecordScreen(
          sampleId: sample['id'] as String,
          specimenType:
              sample['specimen_type'] as String,
          imageCount: 0,
        ),
      ),
    );

    await loadPatientRecord();
  }

  Widget buildPatientDetails() {
    if (patient == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(
              'Patient ID',
              patient!['id']?.toString() ??
                  'Not recorded',
            ),
            _detailRow(
              'Name',
              patientName(),
            ),
            _detailRow(
              'Date of Birth',
              formatDate(
                patient!['date_of_birth']
                    ?.toString(),
              ),
            ),
            _detailRow(
              'Sex at Birth',
              patient!['sex_at_birth']
                      ?.toString() ??
                  'Not recorded',
            ),
            _detailRow(
              'Gender',
              patient!['gender']?.toString() ??
                  'Not recorded',
            ),
            if (patient!['gender_description'] !=
                    null &&
                patient!['gender_description']
                    .toString()
                    .isNotEmpty)
              _detailRow(
                'Gender Description',
                patient![
                        'gender_description']
                    .toString(),
              ),
            _detailRow(
              'Phone',
              patient!['phone_number']
                      ?.toString() ??
                  'Not recorded',
            ),
            if (patient!['email'] != null &&
                patient!['email']
                    .toString()
                    .isNotEmpty)
              _detailRow(
                'Email',
                patient!['email'].toString(),
              ),
            _detailRow(
              'Address',
              patient!['address']?.toString() ??
                  'Not recorded',
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSampleCard(
    Map<String, dynamic> sample,
  ) {
    final specimen =
        sample['specimen_type']?.toString() ??
            'Unknown';

    final status =
        sample['analysis_status']?.toString() ??
            'Pending';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: () => openSample(sample),
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                child: Icon(
                  specimen == 'Blood'
                      ? Icons.bloodtype_outlined
                      : Icons
                          .water_drop_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample['id']?.toString() ??
                          'Unknown sample',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specimen,
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sample[
                              'reason_for_visit']
                          ?.toString() ??
                          'No reason recorded',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Collected: '
                      '${formatDateTime(
                        sample[
                            'collection_date_time'],
                      )}',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _statusChip(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLoading
              ? 'Patient Record'
              : patientName(),
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : patient == null
              ? const Center(
                  child: Text(
                    'Patient record could not be found.',
                  ),
                )
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh:
                        loadPatientRecord,
                    child:
                        SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            patientName(),
                            style:
                                const TextStyle(
                              fontSize: 26,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Patient ID: '
                            '${patient!['id']}',
                            style: TextStyle(
                              color: Colors
                                  .grey.shade600,
                            ),
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          buildPatientDetails(),

                          const SizedBox(
                            height: 28,
                          ),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              const Text(
                                'Sample Records',
                                style:
                                    TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              FilledButton.icon(
                                onPressed:
                                    openNewSample,
                                icon:
                                    const Icon(
                                  Icons
                                      .add,
                                ),
                                label:
                                    const Text(
                                  'New Sample',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          if (samples.isEmpty)
                            Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .all(
                                24,
                              ),
                              decoration:
                                  BoxDecoration(
                                border: Border.all(
                                  color: Colors
                                      .grey
                                      .shade300,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons
                                        .science_outlined,
                                    size: 40,
                                    color: Colors
                                        .grey
                                        .shade500,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    'No samples recorded yet.',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    'Create a new sample '
                                    'to begin an analysis.',
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .grey
                                          .shade600,
                                    ),
                                    textAlign:
                                        TextAlign
                                            .center,
                                  ),
                                ],
                              ),
                            )
                          else
                            ...samples.map(
                              buildSampleCard,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}