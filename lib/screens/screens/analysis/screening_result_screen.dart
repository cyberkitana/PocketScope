import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../services/python_analysis_service.dart';
import '../reports/clinical_report_screen.dart';

/// Displays the results produced by the Python blood-smear analysis.
class ScreeningResultScreen extends StatefulWidget {
  final String patientName;
  final String patientId;
  final String specimen;
  final String collectedDate;
  final String doctorName;
  final String registrationNumber;
  final String sampleId;
  final String facilityName;

  /// Results returned by predict_image.py.
  final BloodAnalysisResult analysis;

  /// Optional clinician note.
  final String clinicianNote;

  const ScreeningResultScreen({
    super.key,
    required this.patientName,
    required this.patientId,
    required this.specimen,
    required this.collectedDate,
    required this.doctorName,
    required this.registrationNumber,
    required this.sampleId,
    required this.facilityName,
    required this.analysis,
    this.clinicianNote = '',
  });

  @override
  State<ScreeningResultScreen> createState() =>
      _ScreeningResultScreenState();
}

class _ScreeningResultScreenState
    extends State<ScreeningResultScreen> {
  late String _clinicianNote;

  @override
  void initState() {
    super.initState();

    _clinicianNote = widget.clinicianNote;
  }

  /// Converts model confidence into a percentage.
  String get confidenceText {
    final percentage =
        (widget.analysis.modelConfidence * 100)
            .clamp(0, 100)
            .round();

    return '$percentage%';
  }

  /// Displays the mean RBC diameter in pixels.
  ///
  /// The prototype does not have microscope calibration,
  /// so this must not be presented as a micrometre measurement.
  String get meanRbcDiameterText {
    if (widget.analysis.meanRbcDiameterPx <= 0) {
      return 'Not available';
    }

    return '${widget.analysis.meanRbcDiameterPx.toStringAsFixed(1)} px';
  }

  /// Displays the RBC size variation.
  String get sizeVariationText {
    if (widget.analysis.sizeVariationPercent <= 0) {
      return 'Not available';
    }

    return '${widget.analysis.sizeVariationPercent.toStringAsFixed(1)}%';
  }

  /// Allows the clinician to add or edit a note.
  Future<void> editClinicianNote() async {
    final controller = TextEditingController(
      text: _clinicianNote,
    );

    final updatedNote =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clinician note',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Add a note about this sample',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (updatedNote == null || !mounted) {
      return;
    }

    setState(() {
      _clinicianNote = updatedNote;
    });
  }

  /// Opens the clinical report using the computer analysis results.
  Future<void> createReport() async {
    final measurements = [
      'Cells assessed: ${widget.analysis.cellsAssessed}',
      'RBCs: ${widget.analysis.rbcCount}',
      'WBCs: ${widget.analysis.wbcCount}',
      'Platelets: ${widget.analysis.plateletCount}',
      'Mean RBC diameter: $meanRbcDiameterText',
      'Size variation: $sizeVariationText',
    ].join(' • ');

    final interpretation =
        _clinicianNote.trim().isNotEmpty
            ? _clinicianNote.trim()
            : widget.analysis.screeningMotivation;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicalReportScreen(
          patientName: widget.patientName,
          patientId: widget.patientId,
          specimen: widget.specimen,
          collectedDate: widget.collectedDate,
          doctorName: widget.doctorName,
          registrationNumber: widget.registrationNumber,
          sampleId: widget.sampleId,
          facilityName: widget.facilityName,
          imagePath: widget.analysis.annotatedImagePath,
          screeningResult: widget.analysis.screeningName,
          measurements: measurements,
          confidenceLevel: confidenceText,
          interpretation: interpretation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildImageCard(),

                    const SizedBox(height: 14),

                    _buildScreeningResult(),

                    const SizedBox(height: 14),

                    _buildMeasurements(),

                    if (widget.analysis.additionalFindings
                        .isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildAdditionalFindings(),
                    ],

                    const SizedBox(height: 14),

                    _buildClinicianNote(),

                    const SizedBox(height: 18),

                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the page header.
  Widget _buildTopBar() {
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/images/chevron-left.svg',
                  width: 20,
                  height: 20,
                  colorFilter:
                      const ColorFilter.mode(
                    Color(0xFF172121),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample analysis',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF172121),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Computer analysis results',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF6D7979),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the annotated image produced by Python.
  Widget _buildImageCard() {
    final imagePath =
        widget.analysis.annotatedImagePath;

    final imageFile = File(imagePath);

    return Container(
      width: double.infinity,
      height: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath.isNotEmpty &&
              imageFile.existsSync()
          ? Image.file(
              imageFile,
              fit: BoxFit.contain,
            )
          : const Center(
              child: Text(
                'Annotated image could not be displayed.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF6D7979),
                  fontSize: 12,
                ),
              ),
            ),
    );
  }

  /// Displays the main automated screening result.
  Widget _buildScreeningResult() {
    final isFlagged =
        widget.analysis.screeningStatus ==
            'flagged';

    final backgroundColour =
        isFlagged
            ? const Color(0xFFFFF4D6)
            : const Color(0xFFE5F5EF);

    final textColour =
        isFlagged
            ? const Color(0xFF8A6500)
            : const Color(0xFF087A59);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColour,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            isFlagged
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: textColour,
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.analysis.screeningName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textColour,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.analysis.screeningMotivation,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textColour,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Model confidence: $confidenceText',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textColour,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays measurements returned by the Python analysis.
  Widget _buildMeasurements() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Measurements',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF172121),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 9),

        Row(
          children: [
            Expanded(
              child: _buildMeasurementCard(
                title: 'Cells assessed',
                value:
                    widget.analysis.cellsAssessed
                        .toString(),
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: _buildMeasurementCard(
                title: 'Mean RBC diameter',
                value: meanRbcDiameterText,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: _buildMeasurementCard(
                title: 'Size variation',
                value: sizeVariationText,
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        Row(
          children: [
            Expanded(
              child: _buildMeasurementCard(
                title: 'RBCs',
                value:
                    widget.analysis.rbcCount
                        .toString(),
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: _buildMeasurementCard(
                title: 'WBCs',
                value:
                    widget.analysis.wbcCount
                        .toString(),
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: _buildMeasurementCard(
                title: 'Platelets',
                value:
                    widget.analysis.plateletCount
                        .toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds an individual measurement card.
  Widget _buildMeasurementCard({
    required String title,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 78,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF6D7979),
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF172121),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the findings returned by the model.
  Widget _buildAdditionalFindings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional findings',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF172121),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          ...widget.analysis.additionalFindings.map(
            (finding) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 7,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 5,
                        right: 8,
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: Color(0xFF6D7979),
                      ),
                    ),

                    Expanded(
                      child: Text(
                        finding,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF4F5A5A),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Displays the clinician note.
  Widget _buildClinicianNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Clinician note',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF172121),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              IconButton(
                onPressed: editClinicianNote,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                ),
                tooltip: 'Edit clinician note',
              ),
            ],
          ),

          if (_clinicianNote.trim().isNotEmpty)
            Text(
              _clinicianNote,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF4F5A5A),
                fontSize: 11,
                height: 1.4,
              ),
            )
          else
            const Text(
              'No clinician note added.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF8A9494),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the final action buttons.
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Draft saved for this session.',
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                46,
              ),
              side: const BorderSide(
                color: Color(0xFFB9C3C3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Save draft',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF172121),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton(
            onPressed: createReport,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                46,
              ),
              backgroundColor:
                  const Color(0xFF0D8B83),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Create report',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}