import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/samples/new_sample_screen.dart';
import '../screens/patients/patient_records_screen.dart';

/// Contains the named routes used for navigation throughout LabScreen.
class AppRoutes {
  static const String home = '/';
  static const String newSample = '/new-sample';
  static const String patientRecords = '/patient-records';
}

/// Connects each route name to the screen that should be displayed.
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.home: (context) => const HomeScreen(),
  AppRoutes.newSample: (context) => const NewSampleScreen(),
  AppRoutes.patientRecords: (context) => const PatientRecordsScreen()
};