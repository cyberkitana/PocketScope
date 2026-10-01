import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../services/database_service.dart';
import '../samples/new_sample_screen.dart';
import '../screens/images/upload_images_screen.dart';
import 'patient_record_dialogs.dart';
import 'patient_record_widgets.dart';
import 'patient_records_screen.dart';

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

  final Map<String, String?> _sampleImagePaths = {};

  bool isLoading = true;

  String _clinicalNote = '';

  @override
  void initState() {
    super.initState();
    loadPatientRecord();
  }

  Future<void> loadPatientRecord() async {
    try {
      final loadedPatient = await DatabaseService.getPatient(
        widget.patientId,
      );

      final loadedSamples =
          await DatabaseService.getSamplesForPatient(
        widget.patientId,
      );

      final imagePaths = <String, String?>{};

      for (final sample in loadedSamples) {
        final sampleId = sample['id']?.toString();

        if (sampleId == null || sampleId.isEmpty) {
          continue;
        }

        final images =
            await DatabaseService.getImagesForSample(sampleId);

        if (images.isNotEmpty) {
          imagePaths[sampleId] =
              images.first['file_path']?.toString();
        } else {
          imagePaths[sampleId] = null;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        patient = loadedPatient;
        samples = loadedSamples;

        _sampleImagePaths
          ..clear()
          ..addAll(imagePaths);

        _clinicalNote =
            loadedPatient?['clinical_note']?.toString() ?? '';

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

    final firstName =
        patient!['first_name']?.toString().trim() ?? '';

    final surname =
        patient!['surname']?.toString().trim() ?? '';

    return '$firstName $surname'.trim();
  }

  String getPatientName() {
    return patientName();
  }

  int calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) {
      return 0;
    }

    final parsedDate = DateTime.tryParse(dateOfBirth);

    if (parsedDate == null) {
      return 0;
    }

    final today = DateTime.now();

    int age = today.year - parsedDate.year;

    if (today.month < parsedDate.month ||
        (today.month == parsedDate.month &&
            today.day < parsedDate.day)) {
      age--;
    }

    return age;
  }

  String getDateOfBirth() {
    final dateOfBirth =
        patient?['date_of_birth']?.toString().trim() ?? '';

    return formatShortDate(dateOfBirth);
  }

  int getAge() {
    final dateOfBirth =
        patient?['date_of_birth']?.toString().trim() ?? '';

    return calculateAge(dateOfBirth);
  }

  String formatShortDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not recorded';
    }

    final date = DateTime.tryParse(dateString);

    if (date == null) {
      return 'Not recorded';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String formatConsentDate(String? dateString) {
    return formatShortDate(dateString);
  }

  String formatConsentExpiry(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not recorded';
    }

    final signedDate = DateTime.tryParse(dateString);

    if (signedDate == null) {
      return 'Not recorded';
    }

    final expiryDate = DateTime(
      signedDate.year + 1,
      signedDate.month,
      signedDate.day,
    );

    return formatShortDate(
      expiryDate.toIso8601String(),
    );
  }

  String formatSampleDate(String? dateString) {
    return formatShortDate(dateString);
  }

  String formatSampleTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '--';
    }

    final date = DateTime.tryParse(dateString);

    if (date == null) {
      return '--';
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String getSexDisplay(String? sex) {
    final value = (sex ?? '').trim().toLowerCase();

    if (value == 'male' || value == 'm') {
      return 'Male';
    }

    if (value == 'female' || value == 'f') {
      return 'Female';
    }

    if (value == 'intersex' || value == 'i') {
      return 'Intersex';
    }

    if (value.isEmpty) {
      return 'Not recorded';
    }

    return sex!.trim();
  }

  String getSex() {
    return getSexDisplay(
      patient?['sex_at_birth']?.toString(),
    );
  }

  String getGenderDisplay() {
    final gender =
        patient?['gender']?.toString().trim() ?? '';

    if (gender.isEmpty) {
      return 'Not recorded';
    }

    return gender;
  }

  String getGenderDescription() {
    return patient?['gender_description']
            ?.toString()
            .trim() ??
        '';
  }

  String getClinicName() {
    final clinicName =
        patient?['clinic_name']?.toString().trim() ?? '';

    if (clinicName.isEmpty) {
      return 'Not recorded';
    }

    return clinicName;
  }

  String getDoctorGpName() {
    final doctorGpName =
        patient?['doctor_gp_name']?.toString().trim() ?? '';

    if (doctorGpName.isEmpty) {
      return 'Not recorded';
    }

    return doctorGpName;
  }

  String getPhone() {
    return getFormattedPhone();
  }

  String getInitials() {
    if (patient == null) {
      return '?';
    }

    final firstName =
        patient!['first_name']?.toString().trim() ?? '';

    final surname =
        patient!['surname']?.toString().trim() ?? '';

    if (firstName.isNotEmpty && surname.isNotEmpty) {
      return '${firstName[0]}${surname[0]}'.toUpperCase();
    }

    if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }

    if (surname.isNotEmpty) {
      return surname[0].toUpperCase();
    }

    return '?';
  }

  List<Color> getAvatarColours() {
    if (samples.isEmpty) {
      return [
        PatientRecordColors.newPatientBackground,
        PatientRecordColors.newPatientText,
      ];
    }

    final latestSample = samples.first;

    final status =
        latestSample['analysis_status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status == 'complete' || status == 'completed') {
      return [
        PatientRecordColors.completeBackground,
        PatientRecordColors.completeText,
      ];
    }

    return [
      PatientRecordColors.analysisDueBackground,
      PatientRecordColors.analysisDueText,
    ];
  }

  String getMedicalRecordNumber() {
    final storedNumber =
        patient?['medical_record_number']?.toString().trim() ?? '';

    if (storedNumber.isNotEmpty) {
      return storedNumber;
    }

    return 'Not assigned';
  }

  String getIdentityNumber() {
    final identityNumber =
        patient?['identity_number']?.toString().trim() ?? '';

    if (identityNumber.isEmpty) {
      return 'Not recorded';
    }

    return identityNumber;
  }

  String getPatientType() {
    if (samples.isEmpty) {
      return 'New patient';
    }

    return 'Established patient';
  }

  String getFormattedPhone() {
    final phone =
        patient?['phone_number']?.toString().trim() ?? '';

    if (phone.isEmpty) {
      return 'Not recorded';
    }

    if (phone.startsWith('+27')) {
      return phone;
    }

    if (phone.startsWith('0')) {
      return '(+27) ${phone.substring(1)}';
    }

    return '(+27) $phone';
  }

  String getSampleTypeName(String? specimenType) {
    final type =
        (specimenType ?? '').trim().toLowerCase();

    if (type == 'urine') {
      return 'Urine sediment';
    }

    if (type == 'blood') {
      return 'Blood smear';
    }

    return specimenType?.trim().isNotEmpty == true
        ? specimenType!.trim()
        : 'Unknown sample';
  }

  List<Color> getSampleStatusColours(String? status) {
    final normalised =
        (status ?? '').trim().toLowerCase();

    if (normalised == 'complete' ||
        normalised == 'completed') {
      return [
        PatientRecordColors.completeBackground,
        PatientRecordColors.completeText,
      ];
    }

    return [
      PatientRecordColors.analysisDueBackground,
      PatientRecordColors.analysisDueText,
    ];
  }

  String getSampleStatus(String? status) {
    final normalised =
        (status ?? '').trim().toLowerCase();

    if (normalised == 'complete' ||
        normalised == 'completed') {
      return 'Complete';
    }

    return 'Needs review';
  }

  bool getConsentObtained() {
    final signaturePath =
        patient?['imaging_consent_signature_path']
                ?.toString()
                .trim() ??
            '';

    final signedDate =
        patient?['imaging_consent_date']
                ?.toString()
                .trim() ??
            '';

    return signaturePath.isNotEmpty &&
        signedDate.isNotEmpty &&
        File(signaturePath).existsSync();
  }

  bool hasImagingConsent() {
    return getConsentObtained();
  }

  Future<void> editClinicalNote() async {
    final controller = TextEditingController(
      text: _clinicalNote,
    );

    final updatedNote = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clinical note',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Add or update the clinical note for this patient.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: PatientRecordColors.secondaryText,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 5,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Enter clinical note',
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: PatientRecordColors.tertiaryText,
                      ),
                      filled: true,
                      fillColor:
                          PatientRecordColors.pageBackground,
                      contentPadding:
                          const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFD8E2E5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: PatientRecordColors.teal,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color:
                                PatientRecordColors.secondaryText,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              PatientRecordColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(
                            controller.text.trim(),
                          );
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();

    if (updatedNote == null) {
      return;
    }

    try {
      final saved =
          await DatabaseService.updatePatientClinicalNote(
        patientId: widget.patientId,
        clinicalNote: updatedNote,
      );

      if (!mounted) {
        return;
      }

      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The clinical note could not be saved.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _clinicalNote = updatedNote;

        if (patient != null) {
          patient!['clinical_note'] = updatedNote;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clinical note saved.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save clinical note: $error',
          ),
        ),
      );
    }
  }

  Future<void> openConsentDialog() async {
    final signedDate = await showImagingConsentDialog(
      context: context,
      patientId: widget.patientId,
    );

    if (signedDate == null || !mounted) {
      return;
    }

    await loadPatientRecord();
  }

  void editPatient() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Patient profile editing will be available here.',
        ),
      ),
    );
  }

  void viewConsent() {
    final signaturePath =
        patient?['imaging_consent_signature_path']
                ?.toString()
                .trim() ??
            '';

    if (signaturePath.isEmpty) {
      return;
    }

    if (!File(signaturePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The saved consent signature could not be found.',
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Imaging consent',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: Image.file(
              File(signaturePath),
              fit: BoxFit.contain,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> openNewSample() async {
    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewSampleScreen(
          patientId: widget.patientId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await loadPatientRecord();
  }

/// Opens the upload page for an existing sample.
///
/// Pending samples should continue through the analysis workflow
/// rather than opening the sample record screen.
Future<void> openSample(
  Map<String, dynamic> sample,
) async {
  if (!mounted) {
    return;
  }

  final sampleId = sample['id']?.toString();
  final specimenType = sample['specimen_type']?.toString();

  if (sampleId == null ||
      sampleId.isEmpty ||
      specimenType == null ||
      specimenType.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This sample is missing the information needed to continue.',
        ),
      ),
    );
    return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => UploadImagesScreen(
        sampleId: sampleId,
        specimenType: specimenType,
      ),
    ),
  );

  if (!mounted) {
    return;
  }

  await loadPatientRecord();
}  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientRecordColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PatientRecordColors.teal,
                      ),
                    )
                  : patient == null
                      ? const Center(
                          child: Text(
                            'Patient record could not be found.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color:
                                  PatientRecordColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          PatientRecordBottomNavigation(
        onHome: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        },
        onPatients: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const PatientRecordsScreen(),
            ),
          );
        },
        onCapture: openNewSample,
        onReports: () {},
      ),
    );
  }

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
                  colorFilter: const ColorFilter.mode(
                    PatientRecordColors.primaryText,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient profile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color:
                          PatientRecordColors.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    patient?['id']?.toString() ?? '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color:
                          PatientRecordColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              tooltip: 'More options',
              padding: EdgeInsets.zero,
              offset: const Offset(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/images/more-horizontal.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    PatientRecordColors.primaryText,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              itemBuilder: (context) {
                final hasConsent =
                    getConsentObtained();

                return [
                  const PopupMenuItem<String>(
                    value: 'edit_profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Edit profile',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: hasConsent
                        ? 'view_consent'
                        : null,
                    enabled: hasConsent,
                    child: Row(
                      children: [
                        Icon(
                          Icons.draw_outlined,
                          size: 18,
                          color: hasConsent
                              ? null
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'View consent',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: hasConsent
                                ? null
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              onSelected: (value) {
                if (value == 'edit_profile') {
                  editPatient();
                }

                if (value == 'view_consent') {
                  viewConsent();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          PatientSummaryCard(
            patient: patient!,
            patientName: getPatientName(),
            initials: getInitials(),
            medicalRecordNumber:
                getMedicalRecordNumber(),
            identityNumber: getIdentityNumber(),
            patientType: getPatientType(),
            dateOfBirth: getDateOfBirth(),
            age: getAge(),
            sex: getSex(),
            gender: getGenderDisplay(),
            genderDescription:
                getGenderDescription(),
            phone: getPhone(),
            clinicName: getClinicName(),
            doctorGpName: getDoctorGpName(),
            avatarColours: getAvatarColours(),
            consentObtained:
                hasImagingConsent(),
          ),

          const SizedBox(height: 12),

          ClinicalNoteSection(
            note: _clinicalNote,
            onEdit: editClinicalNote,
          ),

          const SizedBox(height: 10),

          ImagingConsentCard(
            consentObtained:
                getConsentObtained(),
            signedDate: patient?[
                'imaging_consent_date']?.toString(),
            formatDate: formatConsentDate,
            formatExpiry:
                formatConsentExpiry,
            onTap: openConsentDialog,
          ),

          const SizedBox(height: 14),

          Expanded(
            child: SampleHistorySection(
              samples: samples,
              imagePaths: _sampleImagePaths,
              getSampleTypeName:
                  getSampleTypeName,
              formatSampleDate:
                  formatSampleDate,
              formatSampleTime:
                  formatSampleTime,
              getSampleStatusColours:
                  getSampleStatusColours,
              getSampleStatus:
                  getSampleStatus,
              onSampleTap: openSample,
            ),
          ),

          const SizedBox(height: 10),

          CaptureNewSampleButton(
            onTap: openNewSample,
          ),
        ],
      ),
    );
  }
}