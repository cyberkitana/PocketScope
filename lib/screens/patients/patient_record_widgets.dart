import 'dart:io';

import 'package:flutter/material.dart';

class PatientRecordColors {
  static const Color pageBackground = Color(0xFFEEF3F5);
  static const Color cardBackground = Colors.white;
  static const Color primaryText = Color(0xFF111111);
  static const Color secondaryText = Color(0xFF60747B);
  static const Color tertiaryText = Color(0xFF9AA8AD);
  static const Color teal = Color(0xFF087E78);

  static const Color completeBackground = Color(0xFFE2F3E8);
  static const Color completeText = Color(0xFF287A46);

  static const Color analysisDueBackground = Color(0xFFFFF1D9);
  static const Color analysisDueText = Color(0xFF9A6500);

  static const Color newPatientBackground = Color(0xFFE8EEF1);
  static const Color newPatientText = Color(0xFF53676E);
}


// -----------------------------------------------------------------------------
// PATIENT SUMMARY CARD
// -----------------------------------------------------------------------------

class PatientSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? patient;
  final String patientName;
  final String initials;
  final String medicalRecordNumber;
  final String identityNumber;
  final String patientType;
  final String dateOfBirth;
  final int age;
  final String sex;
  final String gender;
  final String genderDescription;
  final String phone;
  final String clinicName;
  final String doctorGpName;
  final List<Color> avatarColours;
  final bool consentObtained;

  const PatientSummaryCard({
    super.key,
    required this.patient,
    required this.patientName,
    required this.initials,
    required this.medicalRecordNumber,
    required this.identityNumber,
    required this.patientType,
    required this.dateOfBirth,
    required this.age,
    required this.sex,
    required this.gender,
    required this.genderDescription,
    required this.phone,
    required this.clinicName,
    required this.doctorGpName,
    required this.avatarColours,
    required this.consentObtained,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PatientRecordColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 30,
                decoration: BoxDecoration(
                  color: avatarColours.first,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: avatarColours.last,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName.isEmpty ? 'Patient' : patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: PatientRecordColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      medicalRecordNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: PatientRecordColors.secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Text(
                patientType,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: PatientRecordColors.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(
            height: 1,
            color: Color(0xFFE5EAEC),
          ),

          const SizedBox(height: 18),

          // -----------------------------------------------------------------
          // PATIENT DETAILS
          // -----------------------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryDetail(
                      label: 'Date of birth',
                      value: dateOfBirth,
                    ),

                    const SizedBox(height: 8),

                    _SummaryDetail(
                      label: 'Sex',
                      value: sex,
                    ),

                    const SizedBox(height: 8),

                    _SummaryDetail(
                      label: 'Contact',
                      value: phone,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryDetail(
                      label: 'ID / Passport',
                      value: identityNumber,
                    ),

                    const SizedBox(height: 8),

                    _SummaryDetail(
                      label: 'Gender',
                      value: gender,
                    ),

                    if (genderDescription.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),

                      _SummaryDetail(
                        label: 'Gender details',
                        value: genderDescription,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// SUMMARY DETAIL
// -----------------------------------------------------------------------------

class _SummaryDetail extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: PatientRecordColors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value.isEmpty ? 'Not recorded' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: PatientRecordColors.primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


// -----------------------------------------------------------------------------
// CLINICAL NOTE
// -----------------------------------------------------------------------------

class ClinicalNoteSection extends StatelessWidget {
  final String note;
  final VoidCallback onEdit;

  const ClinicalNoteSection({
    super.key,
    required this.note,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasNote = note.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PatientRecordColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Clinical note',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: PatientRecordColors.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: PatientRecordColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            hasNote ? note : 'No clinical note recorded.',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              color: hasNote
                  ? PatientRecordColors.primaryText
                  : PatientRecordColors.tertiaryText,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// IMAGING CONSENT CARD
// -----------------------------------------------------------------------------

class ImagingConsentCard extends StatelessWidget {
  final bool consentObtained;
  final String? signedDate;
  final String Function(String?) formatDate;
  final String Function(String?) formatExpiry;
  final VoidCallback onTap;

  const ImagingConsentCard({
    super.key,
    required this.consentObtained,
    required this.signedDate,
    required this.formatDate,
    required this.formatExpiry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PatientRecordColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: consentObtained
                  ? PatientRecordColors.completeBackground
                  : PatientRecordColors.analysisDueBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              consentObtained
                  ? Icons.check_circle_outline
                  : Icons.draw_outlined,
              size: 20,
              color: consentObtained
                  ? PatientRecordColors.completeText
                  : PatientRecordColors.analysisDueText,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Imaging consent',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: PatientRecordColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                if (consentObtained)
                  Text(
                    'Signed ${formatDate(signedDate)} • Expires ${formatExpiry(signedDate)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: PatientRecordColors.secondaryText,
                      fontSize: 10,
                    ),
                  )
                else
                  const Text(
                    'Imaging consent has not been signed.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: PatientRecordColors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              consentObtained ? 'Update' : 'Sign',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: PatientRecordColors.teal,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// SAMPLE HISTORY
// -----------------------------------------------------------------------------

class SampleHistorySection extends StatelessWidget {
  final List<Map<String, dynamic>> samples;
  final Map<String, String?> imagePaths;
  final String Function(String?) getSampleTypeName;
  final String Function(String?) formatSampleDate;
  final String Function(String?) formatSampleTime;
  final List<Color> Function(String?) getSampleStatusColours;
  final String Function(String?) getSampleStatus;
  final Future<void> Function(Map<String, dynamic>) onSampleTap;

  const SampleHistorySection({
    super.key,
    required this.samples,
    required this.imagePaths,
    required this.getSampleTypeName,
    required this.formatSampleDate,
    required this.formatSampleTime,
    required this.getSampleStatusColours,
    required this.getSampleStatus,
    required this.onSampleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sample history',
          style: TextStyle(
            fontFamily: 'Inter',
            color: PatientRecordColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        if (samples.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PatientRecordColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'No samples recorded for this patient.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: PatientRecordColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: samples.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 8);
              },
              itemBuilder: (context, index) {
                final sample = samples[index];

                return SampleHistoryCard(
                  sample: sample,
                  imagePath:
                      imagePaths[sample['id']?.toString()],
                  specimenName: getSampleTypeName(
                    sample['specimen_type']?.toString(),
                  ),
                  sampleDate: formatSampleDate(
                    sample['collection_date_time']?.toString(),
                  ),
                  sampleTime: formatSampleTime(
                    sample['collection_date_time']?.toString(),
                  ),
                  statusColours: getSampleStatusColours(
                    sample['analysis_status']?.toString(),
                  ),
                  status: getSampleStatus(
                    sample['analysis_status']?.toString(),
                  ),
                  onTap: () => onSampleTap(sample),
                );
              },
            ),
          ),
      ],
    );
  }
}


// -----------------------------------------------------------------------------
// SAMPLE HISTORY CARD
// -----------------------------------------------------------------------------

class SampleHistoryCard extends StatelessWidget {
  final Map<String, dynamic> sample;
  final String? imagePath;
  final String specimenName;
  final String sampleDate;
  final String sampleTime;
  final List<Color> statusColours;
  final String status;
  final VoidCallback onTap;

  const SampleHistoryCard({
    super.key,
    required this.sample,
    required this.imagePath,
    required this.specimenName,
    required this.sampleDate,
    required this.sampleTime,
    required this.statusColours,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: PatientRecordColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SampleImagePreview(
                imagePath: imagePath,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specimenName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: PatientRecordColors.primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$sampleDate • $sampleTime',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: PatientRecordColors.secondaryText,
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      sample['id']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: PatientRecordColors.tertiaryText,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              SampleStatusTag(
                text: status,
                backgroundColor: statusColours.first,
                textColor: statusColours.last,
              ),

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right,
                size: 18,
                color: PatientRecordColors.tertiaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// SAMPLE IMAGE PREVIEW
// -----------------------------------------------------------------------------

class SampleImagePreview extends StatelessWidget {
  final String? imagePath;

  const SampleImagePreview({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imagePath != null &&
        imagePath!.trim().isNotEmpty &&
        File(imagePath!).existsSync();

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: PatientRecordColors.pageBackground,
        borderRadius: BorderRadius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
            )
          : const Icon(
              Icons.image_outlined,
              size: 22,
              color: PatientRecordColors.tertiaryText,
            ),
    );
  }
}


// -----------------------------------------------------------------------------
// SAMPLE STATUS TAG
// -----------------------------------------------------------------------------

class SampleStatusTag extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const SampleStatusTag({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// CAPTURE NEW SAMPLE BUTTON
// -----------------------------------------------------------------------------

class CaptureNewSampleButton extends StatelessWidget {
  final VoidCallback onTap;

  const CaptureNewSampleButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.add,
          size: 18,
        ),
        label: const Text(
          'Capture new sample',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: PatientRecordColors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// PATIENT RECORD BOTTOM NAVIGATION
// -----------------------------------------------------------------------------

class PatientRecordBottomNavigation extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onPatients;
  final VoidCallback onCapture;
  final VoidCallback onReports;

  const PatientRecordBottomNavigation({
    super.key,
    required this.onHome,
    required this.onPatients,
    required this.onCapture,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom;

    return Container(
      height: 68 + bottomPadding,
      padding: EdgeInsets.only(
        bottom: bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8EA),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: false,
              onTap: onHome,
            ),
          ),

          Expanded(
            child: _NavigationItem(
              icon: Icons.people_outline,
              label: 'Patients',
              selected: true,
              onTap: onPatients,
            ),
          ),

          Expanded(
            child: _NavigationItem(
              icon: Icons.add_a_photo_outlined,
              label: 'Capture',
              selected: false,
              onTap: onCapture,
            ),
          ),

          Expanded(
            child: _NavigationItem(
              icon: Icons.description_outlined,
              label: 'Reports',
              selected: false,
              onTap: onReports,
            ),
          ),
        ],
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// NAVIGATION ITEM
// -----------------------------------------------------------------------------

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? PatientRecordColors.teal
        : PatientRecordColors.secondaryText;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: color,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: color,
                fontSize: 9,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),

            const SizedBox(height: 5),

            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: selected
                    ? PatientRecordColors.teal
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}