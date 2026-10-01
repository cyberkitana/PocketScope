import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/database_service.dart';
import '../../utils/id_generator.dart';
import '../patients/register_patient_screen.dart';
import '../screens/images/upload_images_screen.dart';

const Color teal = Color(0xFF087E78);
const Color primaryBlack = Color(0xFF111111);
const Color secondaryText = Color(0xFF60747B);
const Color pageBackground = Color(0xFFEEF3F5);
const Color lightGreen = Color(0xFFE2F3F1);
const Color borderColor = Color(0xFFD0D7DA);

class NewSampleScreen extends StatefulWidget {
  final String? patientId;

  const NewSampleScreen({
    super.key,
    this.patientId,
  });

  @override
  State<NewSampleScreen> createState() => _NewSampleScreenState();
}

class _NewSampleScreenState extends State<NewSampleScreen> {
  final TextEditingController patientSearchController =
      TextEditingController();

  final TextEditingController sampleSpecificationController =
      TextEditingController();

  final TextEditingController reasonController =
      TextEditingController();

  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];

  Map<String, dynamic>? selectedPatient;

  String? specimenType;
  String? magnification;
  String sampleId = '';

  DateTime collectionDateTime = DateTime.now();

  bool isLoading = true;
  bool isSaving = false;

  final List<String> magnificationOptions = [
    '4×',
    '10×',
    '40×',
    '100×',
  ];

  @override
  void initState() {
    super.initState();

    patientSearchController.addListener(filterPatients);

    loadPatients();
  }

  @override
  void dispose() {
    patientSearchController.dispose();
    sampleSpecificationController.dispose();
    reasonController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PATIENT DATA
  // ---------------------------------------------------------------------------

  Future<void> loadPatients() async {
    try {
      final loadedPatients = await DatabaseService.getPatients();

      if (!mounted) {
        return;
      }

      final patientList =
          List<Map<String, dynamic>>.from(loadedPatients);

      setState(() {
        patients = patientList;
        filteredPatients = patientList;
        isLoading = false;
      });

      if (widget.patientId != null) {
        selectPatientById(widget.patientId!);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      showError('Unable to load patients: $error');
    }
  }

  void filterPatients() {
    if (!mounted) {
      return;
    }

    final query =
        patientSearchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredPatients =
            List<Map<String, dynamic>>.from(patients);
      });

      return;
    }

    final results = patients.where((patient) {
      final firstName = _patientValue(
        patient,
        [
          'first_name',
          'firstName',
          'name',
        ],
      );

      final lastName = _patientValue(
        patient,
        [
          'last_name',
          'lastName',
          'surname',
        ],
      );

      final patientId = _patientValue(
        patient,
        [
          'id',
          'patient_id',
          'patientId',
        ],
      );

      final medicalRecordNumber = _patientValue(
        patient,
        [
          'medical_record_number',
          'medicalRecordNumber',
          'mrn',
        ],
      );

      final searchableText = [
        firstName,
        lastName,
        patientId,
        medicalRecordNumber,
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();

    setState(() {
      filteredPatients = results;
    });
  }

  String _patientValue(
    Map<String, dynamic> patient,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = patient[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  String patientDisplayName(
    Map<String, dynamic> patient,
  ) {
    final firstName = _patientValue(
      patient,
      [
        'first_name',
        'firstName',
        'name',
      ],
    );

    final lastName = _patientValue(
      patient,
      [
        'last_name',
        'lastName',
        'surname',
      ],
    );

    final fullName = [
      firstName,
      lastName,
    ].where((value) {
      return value.isNotEmpty;
    }).join(' ');

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return _patientValue(
      patient,
      [
        'patient_id',
        'id',
        'patientId',
      ],
    );
  }

  String patientIdentifier(
    Map<String, dynamic> patient,
  ) {
    return _patientValue(
      patient,
      [
        'patient_id',
        'id',
        'patientId',
      ],
    );
  }

  void selectPatientById(String patientId) {
    for (final patient in patients) {
      final currentPatientId = _patientValue(
        patient,
        [
          'id',
          'patient_id',
          'patientId',
        ],
      );

      if (currentPatientId == patientId) {
        selectPatient(patient);
        return;
      }
    }
  }

  void selectPatient(
    Map<String, dynamic> patient,
  ) {
    setState(() {
      selectedPatient = patient;
      patientSearchController.text =
          patientDisplayName(patient);
    });

    if (specimenType != null) {
      generateSampleId();
    }
  }

  // ---------------------------------------------------------------------------
  // SAMPLE DATA
  // ---------------------------------------------------------------------------

  Future<void> selectSpecimen(String value) async {
    setState(() {
      specimenType = value;
      sampleId = '';
    });

    await generateSampleId();
  }

  Future<void> generateSampleId() async {
    if (specimenType == null) {
      return;
    }

    final generatedId =
        await IdGenerator.generateSampleId(specimenType!);

    if (!mounted) {
      return;
    }

    setState(() {
      sampleId = generatedId;
    });
  }

  // ---------------------------------------------------------------------------
  // COLLECTION DATE AND TIME
  // ---------------------------------------------------------------------------

  Future<void> selectCollectionDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: collectionDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      collectionDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        collectionDateTime.hour,
        collectionDateTime.minute,
      );
    });
  }

  Future<void> selectCollectionTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        collectionDateTime,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: primaryBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      collectionDateTime = DateTime(
        collectionDateTime.year,
        collectionDateTime.month,
        collectionDateTime.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // PATIENT REGISTRATION
  // ---------------------------------------------------------------------------

  Future<void> openRegisterPatient() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPatientScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await loadPatients();
  }

  // ---------------------------------------------------------------------------
  // CREATE SAMPLE
  // ---------------------------------------------------------------------------

  Future<void> createSample() async {
    if (selectedPatient == null) {
      showError('Please select a patient.');
      return;
    }

    if (specimenType == null) {
      showError('Please select a specimen type.');
      return;
    }

    if (sampleSpecificationController.text.trim().isEmpty) {
      showError('Please enter a sample specification.');
      return;
    }

    if (magnification == null) {
      showError('Please select a magnification.');
      return;
    }

    if (reasonController.text.trim().isEmpty) {
      showError('Please enter the reason for the visit.');
      return;
    }

    if (sampleId.isEmpty) {
      await generateSampleId();
    }

    if (sampleId.isEmpty) {
      showError('A sample ID could not be generated.');
      return;
    }

    final patientId = patientIdentifier(selectedPatient!);

    if (patientId.isEmpty) {
      showError(
        'The selected patient does not have a valid patient ID.',
      );
      return;
    }

    if (isSaving) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await DatabaseService.saveSample({
        'id': sampleId,
        'patient_id': patientId,
        'specimen_type': specimenType!,
        'sample_specification':
            sampleSpecificationController.text.trim(),
        'magnification': magnification!,
        'reason_for_visit': reasonController.text.trim(),
        'collection_date_time':
            collectionDateTime.toIso8601String(),
        'analysis_date_time': null,
        'analysis_status': 'New Sample',
      });

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UploadImagesScreen(
            sampleId: sampleId,
            specimenType: specimenType!,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      showError('Unable to create the sample: $error');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String formatDate(DateTime dateTime) {
    final day =
        dateTime.day.toString().padLeft(2, '0');

    final month =
        dateTime.month.toString().padLeft(2, '0');

    return '$day/$month/${dateTime.year}';
  }

  String formatTime(DateTime dateTime) {
    final hour =
        dateTime.hour.toString().padLeft(2, '0');

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 900,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildPatientSection(),

                            const SizedBox(height: 18),

                            _buildSampleSection(
                              constraints.maxWidth,
                            ),

                            const SizedBox(height: 18),

                            _buildReasonSection(),

                            const SizedBox(height: 18),

                            _buildCollectionSection(
                              constraints.maxWidth,
                            ),

                            const SizedBox(height: 22),

                            _buildCreateButton(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: pageBackground,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: isSaving
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              borderRadius: BorderRadius.circular(8),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    size: 23,
                    color: primaryBlack,
                  ),
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
                  'New Sample',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primaryBlack,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Create a sample for analysis',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PATIENT SECTION
  // ---------------------------------------------------------------------------

  Widget _buildPatientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Patient'),

        const SizedBox(height: 8),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                children: [
                  TextField(
                    controller: patientSearchController,
                    decoration: _inputDecoration(
                      hintText: 'Search patient name or ID',
                      prefixIcon: Icons.search,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: _buildNewPatientButton(),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: patientSearchController,
                    decoration: _inputDecoration(
                      hintText: 'Search patient name or ID',
                      prefixIcon: Icons.search,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                _buildNewPatientButton(),
              ],
            );
          },
        ),

        const SizedBox(height: 8),

        _buildPatientResults(),
      ],
    );
  }

  Widget _buildNewPatientButton() {
    return OutlinedButton(
      onPressed:
          isSaving ? null : openRegisterPatient,
      style: OutlinedButton.styleFrom(
        foregroundColor: teal,
        disabledForegroundColor: secondaryText,
        side: const BorderSide(
          color: teal,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        minimumSize: const Size(0, 43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      child: const Text(
        'New Patient',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPatientResults() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 12,
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: teal,
            ),
          ),
        ),
      );
    }

    if (filteredPatients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Text(
          'No patients found.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: secondaryText,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 210,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = filteredPatients[index];

          final patientId = patientIdentifier(patient);

          final selectedId =
              selectedPatient == null
                  ? ''
                  : patientIdentifier(selectedPatient!);

          final isSelected =
              patientId.isNotEmpty &&
              patientId == selectedId;

          return Container(
            margin: const EdgeInsets.only(
              bottom: 7,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? lightGreen
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? teal
                    : borderColor,
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 1,
              ),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? teal
                      : pageBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _patientInitials(
                    patientDisplayName(patient),
                  ),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : teal,
                  ),
                ),
              ),
              title: Text(
                patientDisplayName(patient),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryBlack,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(
                  top: 2,
                ),
                child: Text(
                  'Patient ID: $patientId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: secondaryText,
                  ),
                ),
              ),
              trailing: Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.chevron_right,
                size: 19,
                color: isSelected
                    ? teal
                    : secondaryText,
              ),
              onTap: () {
                selectPatient(patient);
              },
            ),
          );
        },
      ),
    );
  }

  String _patientInitials(String name) {
    final parts = name.trim().split(
      RegExp(r'\s+'),
    );

    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // SAMPLE SECTION
  // ---------------------------------------------------------------------------

  Widget _buildSampleSection(double availableWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionDivider(),

        const SizedBox(height: 14),

        _buildSectionTitle('Sample Details'),

        const SizedBox(height: 14),

        if (availableWidth >= 650)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildSpecimenType(),

                    const SizedBox(height: 14),

                    _buildMagnification(),
                  ],
                ),
              ),

              const SizedBox(width: 28),

              Expanded(
                child: _buildSampleId(),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildSpecimenType(),

              const SizedBox(height: 14),

              _buildMagnification(),

              const SizedBox(height: 14),

              _buildSampleId(),
            ],
          ),

        const SizedBox(height: 14),

        _buildSampleSpecification(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SPECIMEN TYPE
  // ---------------------------------------------------------------------------

  Widget _buildSpecimenType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Specimen Type'),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSpecimenCheckbox(
              label: 'Urine',
              value: 'Urine',
              iconPath:
                  'assets/images/urine_specimen.svg',
            ),

            _buildSpecimenCheckbox(
              label: 'Blood',
              value: 'Blood',
              iconPath:
                  'assets/images/blood_specimen.svg',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecimenCheckbox({
    required String label,
    required String value,
    required String iconPath,
  }) {
    final isSelected = specimenType == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          selectSpecimen(value);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 42,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? lightGreen
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? teal
                  : borderColor,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCustomCheckbox(isSelected),

              const SizedBox(width: 8),

              SvgPicture.asset(
                iconPath,
                width: 18,
                height: 18,
              ),

              const SizedBox(width: 6),

              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: primaryBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCheckbox(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isSelected
            ? teal
            : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected
              ? teal
              : const Color(0xFF9AA8AD),
          width: 1.2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 13,
              color: Colors.white,
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // MAGNIFICATION
  // ---------------------------------------------------------------------------

  Widget _buildMagnification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Magnification'),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: magnificationOptions.map((option) {
            return _buildMagnificationCheckbox(option);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMagnificationCheckbox(String value) {
    final isSelected = magnification == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            magnification =
                isSelected ? null : value;
          });
        },
        borderRadius: BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 38,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? lightGreen
                : Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected
                  ? teal
                  : borderColor,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCustomCheckbox(isSelected),

              const SizedBox(width: 7),

              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: isSelected
                      ? teal
                      : primaryBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAMPLE ID
  // ---------------------------------------------------------------------------

  Widget _buildSampleId() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Sample ID'),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 42,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: pageBackground,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.qr_code_2,
                size: 18,
                color: teal,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  sampleId.isEmpty
                      ? 'Select specimen type'
                      : sampleId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sampleId.isEmpty
                        ? secondaryText
                        : primaryBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SAMPLE SPECIFICATION
  // ---------------------------------------------------------------------------

  Widget _buildSampleSpecification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Sample Specification'),

        const SizedBox(height: 7),

        TextField(
          controller: sampleSpecificationController,
          decoration: _inputDecoration(
            hintText:
                'e.g. Midstream urine, whole blood',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REASON SECTION
  // ---------------------------------------------------------------------------

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionDivider(),

        const SizedBox(height: 14),

        _buildSectionTitle('Reason for Visit'),

        const SizedBox(height: 8),

        TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: _inputDecoration(
            hintText:
                'Enter the reason for collecting this sample',
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // COLLECTION SECTION
  // ---------------------------------------------------------------------------

  Widget _buildCollectionSection(double availableWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionDivider(),

        const SizedBox(height: 14),

        _buildSectionTitle('Collection Date & Time'),

        const SizedBox(height: 8),

        if (availableWidth >= 500)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: selectCollectionDate,
                  borderRadius:
                      BorderRadius.circular(7),
                  child: _buildDateTimeField(
                    Icons.calendar_today_outlined,
                    formatDate(collectionDateTime),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: InkWell(
                  onTap: selectCollectionTime,
                  borderRadius:
                      BorderRadius.circular(7),
                  child: _buildDateTimeField(
                    Icons.access_time,
                    formatTime(collectionDateTime),
                  ),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: selectCollectionDate,
                  borderRadius:
                      BorderRadius.circular(7),
                  child: _buildDateTimeField(
                    Icons.calendar_today_outlined,
                    formatDate(collectionDateTime),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: selectCollectionTime,
                  borderRadius:
                      BorderRadius.circular(7),
                  child: _buildDateTimeField(
                    Icons.access_time,
                    formatTime(collectionDateTime),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDateTimeField(
    IconData icon,
    String value,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 42,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: teal,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: primaryBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: isSaving ? null : createSample,
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              teal.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 18,
                  ),

                  SizedBox(width: 7),

                  Text(
                    'Create Sample',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED UI HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primaryBlack,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: primaryBlack,
      ),
    );
  }

  Widget _buildSectionDivider() {
    return const Divider(
      height: 1,
      color: borderColor,
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    EdgeInsets? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: secondaryText,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              size: 19,
              color: secondaryText,
            ),
      contentPadding:
          contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: teal,
          width: 1.5,
        ),
      ),
    );
  }
}