import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

// Main application widget for PocketScope.
// Sets up the application's theme, navigation routes and the first screen.
class PocketScopeApp extends StatelessWidget {
  const PocketScopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketScope',
      debugShowCheckedModeBanner: false,
      theme: appTheme,

      // Login is now the first screen shown when the app opens.
      initialRoute: AppRoutes.login,

      // Named routes used throughout the application.
      routes: appRoutes,
    );
  }
}