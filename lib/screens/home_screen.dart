import 'package:flutter/material.dart';
import '../app/routes.dart';

/// Home screen for the LabScreen application
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LabScreen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to LabScreen',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'A portable screening platform for resource-limited settings.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                  context,
                  AppRoutes.newSample,
                  );
                },
                child: const Text('New Sample'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                  context,
                  AppRoutes.patientRecords,
                );
              },
                child: const Text('Find Patient'),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Recent Samples',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Card(
              child: ListTile(
                title: Text('No recent samples'),
                subtitle: Text(
                  'New sample records will appear here.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}