import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

/// Main application widget for LabScreen.
/// Sets up the application's theme, navigation routes,and the first screen shown when the app is opened.
class LabScreenApp extends StatelessWidget {
  const LabScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LabScreen',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: AppRoutes.home,
      routes: appRoutes,
    );
  }
}