import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/routes.dart';

/// Displays the clinical microscopy report for a patient sample.
///
/// The report information is passed into this screen so that the same
/// screen can be reused for different patients and samples.
class ClinicalReportScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String facilityName;
  final String sampleId;
  final String specimen;
  final String collectedDate;
  final String screeningResult;
  final String measurements;
  final String confidenceLevel;
  final String interpretation;
  final String doctorName;
  final String registrationNumber;

  /// Optional path to the analysed microscopy image.
  final String? imagePath;

  /// Optional callback for saving the completed report.
  ///
  /// The patient/sample information can be saved by the screen that
  /// opened this report page.
  final Future<void> Function()? onCompleteAndExport;

  const ClinicalReportScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.facilityName,
    required this.sampleId,
    required this.specimen,
    required this.collectedDate,
    required this.screeningResult,
    required this.measurements,
    required this.confidenceLevel,
    required this.interpretation,
    required this.doctorName,
    required this.registrationNumber,
    this.imagePath,
    this.onCompleteAndExport,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F5),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              _buildTopBar(context),

              Expanded(
                child: _buildReportArea(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 62,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF102A32),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clinical report',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Draft · $patientId',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF60747B),
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

  // ---------------------------------------------------------------------------
  // MAIN REPORT AREA
  // ---------------------------------------------------------------------------

  Widget _buildReportArea(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          14,
          20,
          14,
        ),
        child: Column(
          children: [
            _buildReportCard(),

            const SizedBox(height: 12),

            _buildActionButtons(),

            const SizedBox(height: 12),

            _buildCompleteButton(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPORT CARD
  // ---------------------------------------------------------------------------

  Widget _buildReportCard() {
    return Container(
      width: 350,
      constraints: const BoxConstraints(
        minHeight: 448,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5ECEE),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportHeader(),

          const SizedBox(height: 13),

          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFD8E2E5),
          ),

          const SizedBox(height: 14),

          const Text(
            'Microscopy examination report',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Report $sampleId · $collectedDate',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: Color(0xFF60747B),
            ),
          ),

          const SizedBox(height: 12),

          _buildPatientInformation(),

          const SizedBox(height: 14),

          _buildFindingsSection(),

          const SizedBox(height: 13),

          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFD8E2E5),
          ),

          const SizedBox(height: 13),

          _buildInterpretationSection(),

          const SizedBox(height: 13),

          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFD8E2E5),
          ),

          const SizedBox(height: 12),

          _buildDoctorSection(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPORT HEADER
  // ---------------------------------------------------------------------------

  Widget _buildReportHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF2C8C8C),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/images/microscope.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PocketScope',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                facilityName.isEmpty
                    ? 'Facility not recorded'
                    : facilityName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 7,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF60747B),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        _buildStatusBadge(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STATUS BADGE
  // ---------------------------------------------------------------------------

  Widget _buildStatusBadge() {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4B82D9),
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 5),

          const Text(
            'Draft',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: Color(0xFF386CB4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PATIENT INFORMATION
  // ---------------------------------------------------------------------------

  Widget _buildPatientInformation() {
    return Container(
      width: double.infinity,
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F9),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoLabel(
                  'Patient',
                ),

                const SizedBox(height: 4),

                _buildInfoLabel(
                  'Specimen',
                ),

                const SizedBox(height: 4),

                _buildInfoLabel(
                  'Collected',
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildInfoValue(
                patientName,
              ),

              const SizedBox(height: 4),

              _buildInfoValue(
                specimen,
              ),

              const SizedBox(height: 4),

              _buildInfoValue(
                collectedDate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 9,
        fontWeight: FontWeight.w400,
        color: Color(0xFF60747B),
      ),
    );
  }

  Widget _buildInfoValue(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: Color(0xFF102A32),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FINDINGS
  // ---------------------------------------------------------------------------

  Widget _buildFindingsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePreview(),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FINDINGS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                screeningResult,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF60747B),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                measurements,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8A999E),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 7),

              _buildConfidenceTag(),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE PREVIEW
  // ---------------------------------------------------------------------------

  Widget _buildImagePreview() {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD8E2E5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (imagePath != null &&
        imagePath!.trim().isNotEmpty &&
        File(imagePath!).existsSync()) {
      return Image.file(
        File(imagePath!),
        width: 104,
        height: 104,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      'assets/images/Blood Smear_1.png',
      width: 104,
      height: 104,
      fit: BoxFit.cover,
    );
  }

  // ---------------------------------------------------------------------------
  // CONFIDENCE TAG
  // ---------------------------------------------------------------------------

  Widget _buildConfidenceTag() {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1C7),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        confidenceLevel,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 7,
          fontWeight: FontWeight.w500,
          color: Color(0xFF856404),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERPRETATION
  // ---------------------------------------------------------------------------

  Widget _buildInterpretationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INTERPRETATION',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          interpretation,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w300,
            color: Color(0xFF60747B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DOCTOR
  // ---------------------------------------------------------------------------

  Widget _buildDoctorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          doctorName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          registrationNumber,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 7,
            fontWeight: FontWeight.w400,
            color: Color(0xFF60747B),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION BUTTONS
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons() {
    return SizedBox(
      width: 350,
      child: Row(
        children: [
          Expanded(
            child: _buildSmallActionButton(
              iconPath: 'assets/images/file-text.svg',
              label: 'PDF',
              onTap: () {
                _showComingSoonMessage(
                  'PDF export',
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildSmallActionButton(
              iconPath: 'assets/images/share-2.svg',
              label: 'Secure Link',
              onTap: () {
                _showComingSoonMessage(
                  'Secure link',
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildSmallActionButton(
              iconPath: 'assets/images/printer.svg',
              label: 'Print',
              onTap: () {
                _showComingSoonMessage(
                  'Print',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFD8E2E5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 12,
              height: 12,
              colorFilter: const ColorFilter.mode(
                Color(0xFF102A32),
                BlendMode.srcIn,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPLETE AND EXPORT
  // ---------------------------------------------------------------------------

  Widget _buildCompleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (onCompleteAndExport != null) {
          await onCompleteAndExport!();
        }

        if (!context.mounted) {
          return;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      },
      child: Container(
        width: 350,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF2C8C8C),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/lock-keyhole.svg',
              width: 15,
              height: 15,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),

            const SizedBox(width: 7),

            const Text(
              'Complete and Export',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TEMPORARY ACTION MESSAGE
  // ---------------------------------------------------------------------------

  void _showComingSoonMessage(String action) {
    // This is intentionally only a descriptor for the three secondary
    // buttons while the core report workflow is being completed.
    debugPrint(
      '$action action selected for report $sampleId.',
    );
  }
}