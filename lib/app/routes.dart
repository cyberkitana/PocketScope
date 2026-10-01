import 'package:flutter/material.dart';

import '../screens/login/login_screen.dart';
import '../screens/login/create_account_screen.dart';
import '../screens/home_screen.dart';
import '../screens/samples/new_sample_screen.dart';
import '../screens/patients/patient_records_screen.dart';
import '../screens/patients/register_patient_screen.dart';

/// Contains the named routes used for navigation throughout PocketScope.
class AppRoutes {
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String home = '/';
  static const String newSample = '/new-sample';
  static const String patientRecords = '/patient-records';
  static const String registerPatient = '/register-patient';
}

/// Connects each route name to the screen that should be displayed.
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.login: (context) => const LoginScreen(),
  AppRoutes.createAccount: (context) => const CreateAccountScreen(),
  AppRoutes.home: (context) => const HomeScreen(),
  AppRoutes.newSample: (context) => const NewSampleScreen(),
  AppRoutes.patientRecords: (context) => const PatientRecordsScreen(),
  AppRoutes.registerPatient: (context) => const RegisterPatientScreen(),
};