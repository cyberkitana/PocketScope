import 'package:flutter/material.dart';

import '../../services/database_service.dart';
import '../../utils/id_generator.dart';

/// Screen used to register a new patient.
class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController genderDescriptionController =
      TextEditingController();

  String? selectedSexAtBirth;
  String? selectedGender;
  DateTime? selectedDateOfBirth;

  @override
  void dispose() {
    firstNameController.dispose();
    surnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    genderDescriptionController.dispose();
    super.dispose();
  }

  Future<void> selectDateOfBirth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDateOfBirth = pickedDate;
      });
    }
  }

  String formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> registerPatient() async {
    final firstName = firstNameController.text.trim();
    final surname = surnameController.text.trim();
    final phoneNumber = phoneController.text.trim();
    final email = emailController.text.trim();
    final address = addressController.text.trim();
    final genderDescription =
        genderDescriptionController.text.trim();

    if (firstName.isEmpty ||
        surname.isEmpty ||
        selectedDateOfBirth == null ||
        selectedSexAtBirth == null ||
        selectedGender == null ||
        phoneNumber.isEmpty ||
        address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all required fields.',
          ),
        ),
      );
      return;
    }

    if (selectedGender == 'Other' &&
        genderDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please specify the patient\'s gender.',
          ),
        ),
      );
      return;
    }

    try {
      final patientId = await IdGenerator.generatePatientId();

      await DatabaseService.savePatient({
        'id': patientId,
        'first_name': firstName,
        'surname': surname,
        'date_of_birth': selectedDateOfBirth!.toIso8601String(),
        'sex_at_birth': selectedSexAtBirth!,
        'gender': selectedGender!,
        'gender_description':
            selectedGender == 'Other'
                ? genderDescription
                : null,
        'phone_number': phoneNumber,
        'email': email.isEmpty ? null : email,
        'address': address,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Patient registered successfully: $patientId',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to register patient: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Patient'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register New Patient',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Enter the patient details below.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: surnameController,
                decoration: const InputDecoration(
                  labelText: 'Surname *',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Date of Birth *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: selectDateOfBirth,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDateOfBirth == null
                        ? 'Select Date of Birth'
                        : formatDate(selectedDateOfBirth!),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Sex Assigned at Birth *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: selectedSexAtBirth,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select sex assigned at birth',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Intersex',
                    child: Text('Intersex'),
                  ),
                  DropdownMenuItem(
                    value: 'Not specified',
                    child: Text('Not specified'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSexAtBirth = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Gender *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select gender',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Non-binary',
                    child: Text('Non-binary'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                  DropdownMenuItem(
                    value: 'Prefer not to say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;

                    if (value != 'Other') {
                      genderDescriptionController.clear();
                    }
                  });
                },
              ),

              if (selectedGender == 'Other') ...[
                const SizedBox(height: 12),

                TextField(
                  controller: genderDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Please specify *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: registerPatient,
                  child: const Text('Register Patient'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}