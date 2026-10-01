import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/database_service.dart';
import '../../utils/id_generator.dart';

/// Screen used to register a complete new patient record.
///
/// The form follows the same visual style as the PocketScope
/// Create Account screen. It collects the information needed
/// to identify and contact the patient before samples are taken.
class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() =>
      _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  // ------------------------------------------------------------
  // POCKETSCOPE COLOURS
  // ------------------------------------------------------------

  /// Main PocketScope teal.
  static const Color teal = Color(0xFF087E78);

  /// Main text colour.
  static const Color primaryText = Color(0xFF000000);

  /// Secondary / muted text colour.
  static const Color secondaryText = Color(0xFF60747B);

  /// Main page background.
  static const Color pageBackground = Color(0xFFEEF3F5);

  /// White background used inside form fields.
  static const Color inputBackground = Color(0xFFFFFFFF);

  /// Light grey outline used around form fields.
  static const Color inputBorder = Color(0xFFD0D7DA);

  // ------------------------------------------------------------
  // FORM CONTROLLERS
  // ------------------------------------------------------------

  final TextEditingController _firstNameController =
      TextEditingController();

  final TextEditingController _surnameController =
      TextEditingController();

  /// Stores the optional South African ID or passport number.
  final TextEditingController _identityNumberController =
      TextEditingController();

  final TextEditingController _mrnController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _genderDescriptionController =
      TextEditingController();

  final TextEditingController _clinicController =
      TextEditingController();

  final TextEditingController _doctorController =
      TextEditingController();

  // ------------------------------------------------------------
  // PATIENT FORM STATE
  // ------------------------------------------------------------

  /// Stores the patient's selected date of birth.
  DateTime? _selectedDateOfBirth;

  /// Stores the selected sex assigned at birth.
  String? _selectedSexAtBirth;

  /// Stores the selected gender.
  String? _selectedGender;

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _identityNumberController.dispose();
    _mrnController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _genderDescriptionController.dispose();
    _clinicController.dispose();
    _doctorController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 342,
              child: Column(
                children: [
                  // ------------------------------------------------
                  // PAGE HEADER
                  // ------------------------------------------------

                  SizedBox(
                    width: 342,
                    height: 100,
                    child: _buildHeader(),
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------
                  // PATIENT FORM
                  // ------------------------------------------------

                  _buildPatientForm(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PAGE HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return SizedBox(
      width: 390,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ----------------------------------------------------------
          // BACK BUTTON
          // ----------------------------------------------------------

          Positioned(
            left: 0,
            top: 16,
            child: GestureDetector(
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
                    primaryText,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // ----------------------------------------------------------
          // PAGE TITLE
          // ----------------------------------------------------------

          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 45,
                right: 45,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Register a New Patient',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter the patient information below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PATIENT FORM
  // ------------------------------------------------------------

  Widget _buildPatientForm() {
    return SizedBox(
      width: 342,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------
          // NAME
          // --------------------------------------------------------

          _buildInputField(
            label: 'First name',
            hint: 'Enter first name',
            controller: _firstNameController,
          ),

          const SizedBox(height: 7),

          _buildInputField(
            label: 'Surname',
            hint: 'Enter surname',
            controller: _surnameController,
          ),

          const SizedBox(height: 7),

          // --------------------------------------------------------
          // ID / PASSPORT NUMBER
          // --------------------------------------------------------

          _buildInputField(
            label: 'ID / Passport Number',
            hint: 'Optional',
            controller: _identityNumberController,
          ),

          const SizedBox(height: 7),

          // --------------------------------------------------------
          // DATE OF BIRTH
          // --------------------------------------------------------

          const Text(
            'Date of birth',
            style: TextStyle(
              fontFamily: 'Inter',
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 7),

          _buildDateOfBirthField(),

          const SizedBox(height: 7),

          // --------------------------------------------------------
          // MEDICAL RECORD NUMBER
          // --------------------------------------------------------

          _buildInputField(
            label: 'Medical Record Number (MRN)',
            hint: 'Leave blank to generate automatically',
            controller: _mrnController,
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // SEX ASSIGNED AT BIRTH
          // --------------------------------------------------------

          const Text(
            'Sex assigned at birth',
            style: TextStyle(
              fontFamily: 'Inter',
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 8),

          _buildSexOptions(),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // GENDER
          // --------------------------------------------------------

          const Text(
            'Gender',
            style: TextStyle(
              fontFamily: 'Inter',
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 8),

          _buildGenderOptions(),

          // Gender description only appears when "Other" is selected.
          if (_selectedGender == 'Other') ...[
            const SizedBox(height: 7),

            _buildInputField(
              label: 'Gender description',
              hint: 'Please specify',
              controller: _genderDescriptionController,
            ),
          ],

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // CONTACT DETAILS
          // --------------------------------------------------------

          _buildInputField(
            label: 'Phone number',
            hint: 'Enter phone number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 7),

          _buildInputField(
            label: 'Email',
            hint: 'Optional',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 7),

          _buildMultilineInputField(
            label: 'Address',
            hint: 'Enter patient address',
            controller: _addressController,
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // CLINIC DETAILS
          // --------------------------------------------------------

          _buildInputField(
            label: 'Clinic name',
            hint: 'Enter clinic name',
            controller: _clinicController,
          ),

          const SizedBox(height: 7),

          _buildInputField(
            label: 'Doctor / GP name',
            hint: 'Enter doctor or GP name',
            controller: _doctorController,
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------------
          // SAVE BUTTON
          // --------------------------------------------------------

          _buildSaveButton(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STANDARD INPUT FIELD
  // ------------------------------------------------------------

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? iconPath,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      width: 342,
      height: 74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 7),

          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  color: secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: inputBackground,
                prefixIcon: iconPath != null
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: SvgPicture.asset(
                          iconPath,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: inputBorder,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: inputBorder,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: teal,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MULTILINE INPUT FIELD
  // ------------------------------------------------------------

  Widget _buildMultilineInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 3,
          keyboardType: TextInputType.streetAddress,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              color: secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: inputBackground,
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: inputBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: inputBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: teal,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // DATE OF BIRTH
  // ------------------------------------------------------------

  Widget _buildDateOfBirthField() {
    return SizedBox(
      width: 342,
      height: 48,
      child: OutlinedButton(
        onPressed: _selectDateOfBirth,
        style: OutlinedButton.styleFrom(
          backgroundColor: inputBackground,
          foregroundColor: primaryText,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          side: const BorderSide(
            color: inputBorder,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/calendar.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                secondaryText,
                BlendMode.srcIn,
              ),
            ),

            const SizedBox(width: 10),

            Text(
              _selectedDateOfBirth == null
                  ? 'Select date of birth'
                  : _formatDate(_selectedDateOfBirth!),
              style: TextStyle(
                fontFamily: 'Inter',
                color: _selectedDateOfBirth == null
                    ? secondaryText
                    : primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SEX OPTIONS
  // ------------------------------------------------------------

  Widget _buildSexOptions() {
    const sexOptions = [
      'Female',
      'Male',
      'Intersex',
      'Not specified',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: sexOptions.map((sex) {
        final bool isSelected =
            _selectedSexAtBirth == sex;

        return _buildCheckboxOption(
          label: sex,
          isSelected: isSelected,
          onChanged: (selected) {
            setState(() {
              _selectedSexAtBirth =
                  selected ? sex : null;
            });
          },
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // GENDER OPTIONS
  // ------------------------------------------------------------

  Widget _buildGenderOptions() {
    const genderOptions = [
      'Female',
      'Male',
      'Other',
      'Prefer not to say',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: genderOptions.map((gender) {
        final bool isSelected =
            _selectedGender == gender;

        return _buildCheckboxOption(
          label: gender,
          isSelected: isSelected,
          onChanged: (selected) {
            setState(() {
              _selectedGender =
                  selected ? gender : null;

              // Remove an old description when the user changes
              // away from "Other".
              if (gender != 'Other') {
                _genderDescriptionController.clear();
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // CHECKBOX OPTION
  // ------------------------------------------------------------

  Widget _buildCheckboxOption({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                onChanged(value == true);
              },
              fillColor:
                  WidgetStateProperty.resolveWith<Color>(
                (states) {
                  if (states.contains(
                    WidgetState.selected,
                  )) {
                    return teal;
                  }

                  return Colors.white;
                },
              ),
              checkColor: Colors.white,
              side: const BorderSide(
                color: teal,
                width: 1,
              ),
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),

          const SizedBox(width: 4),

          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SAVE BUTTON
  // ------------------------------------------------------------

  Widget _buildSaveButton() {
    return SizedBox(
      width: 342,
      height: 50,
      child: ElevatedButton(
        onPressed: _savePatient,
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Patient-record icon displayed inside the save button.
            SvgPicture.asset(
              'assets/images/file-check-2.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),

            const SizedBox(width: 8),

            const Text(
              'Save to Patient Records',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE PICKER
  // ------------------------------------------------------------

  Future<void> _selectDateOfBirth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDateOfBirth = pickedDate;
    });
  }

  // ------------------------------------------------------------
  // DATE FORMAT
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ------------------------------------------------------------
  // SAVE PATIENT
  // ------------------------------------------------------------

  Future<void> _savePatient() async {
    final firstName =
        _firstNameController.text.trim();

    final surname =
        _surnameController.text.trim();

    final identityNumber =
        _identityNumberController.text.trim();

    final enteredMrn =
        _mrnController.text.trim();

    final phoneNumber =
        _phoneController.text.trim();

    final email =
        _emailController.text.trim();

    final address =
        _addressController.text.trim();

    final genderDescription =
        _genderDescriptionController.text.trim();

    final clinicName =
        _clinicController.text.trim();

    final doctorName =
        _doctorController.text.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (firstName.isEmpty ||
        surname.isEmpty ||
        _selectedDateOfBirth == null ||
        _selectedSexAtBirth == null ||
        _selectedGender == null ||
        phoneNumber.isEmpty ||
        address.isEmpty ||
        clinicName.isEmpty ||
        doctorName.isEmpty) {
      _showMessage(
        'Please complete all required fields.',
      );
      return;
    }

    // A gender description is required when "Other" is selected.
    if (_selectedGender == 'Other' &&
        genderDescription.isEmpty) {
      _showMessage(
        'Please specify the patient\'s gender.',
      );
      return;
    }

    // ----------------------------------------------------------
    // GENERATE IDS
    // ----------------------------------------------------------

    try {
      // Generate the permanent patient ID.
      final patientId =
          await IdGenerator.generatePatientId();

      // Generate an MRN only when the clinic worker did not
      // provide one.
      final medicalRecordNumber =
          enteredMrn.isNotEmpty
              ? enteredMrn
              : await IdGenerator.generateMedicalRecordNumber();

      // --------------------------------------------------------
      // SAVE TO DATABASE
      // --------------------------------------------------------

      await DatabaseService.savePatient({
        'id': patientId,

        'first_name': firstName,

        'surname': surname,

        // ID / passport number is optional.
        // Store null when the field is left blank.
        'identity_number':
            identityNumber.isEmpty
                ? null
                : identityNumber,

        'date_of_birth':
            _selectedDateOfBirth!.toIso8601String(),

        'medical_record_number':
            medicalRecordNumber,

        'sex_at_birth':
            _selectedSexAtBirth!,

        'gender':
            _selectedGender!,

        'gender_description':
            _selectedGender == 'Other'
                ? genderDescription
                : null,

        'phone_number':
            phoneNumber,

        'email':
            email.isEmpty ? null : email,

        'address':
            address,

        'clinic_name':
            clinicName,

        'doctor_gp_name':
            doctorName,
      });

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      await _showSuccessDialog(
        patientId: patientId,
        medicalRecordNumber: medicalRecordNumber,
      );

      if (!mounted) {
        return;
      }

      // Return to the patient records screen and tell it that
      // a new patient was successfully created.
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to save patient: $error',
      );
    }
  }

  // ------------------------------------------------------------
  // SUCCESS DIALOG
  // ------------------------------------------------------------

  Future<void> _showSuccessDialog({
    required String patientId,
    required String medicalRecordNumber,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success checkmark.
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Patient saved successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Patient ID: $patientId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'MRN: $medicalRecordNumber',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}