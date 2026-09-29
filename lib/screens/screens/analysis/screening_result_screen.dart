import 'package:flutter/material.dart';

import '../../../services/database_service.dart';
import '../../home_screen.dart';

/// Screen that displays the preliminary screening result for a sample.
class ScreeningResultScreen extends StatefulWidget {
  final String sampleId;
  final String specimenType;
  final int imageCount;

  const ScreeningResultScreen({
    super.key,
    required this.sampleId,
    required this.specimenType,
    required this.imageCount,
  });

  @override
  State<ScreeningResultScreen> createState() =>
      _ScreeningResultScreenState();
}

class _ScreeningResultScreenState
    extends State<ScreeningResultScreen> {
  Map<String, dynamic>? sample;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    loadSample();
  }

  Future<void> loadSample() async {
    try {
      final loadedSample =
          await DatabaseService.getSample(widget.sampleId);

      if (!mounted) {
        return;
      }

      setState(() {
        sample = loadedSample;
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
            'Unable to load screening result: $error',
          ),
        ),
      );
    }
  }

  Future<void> saveToSampleRecords() async {
    if (sample == null) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final analysisDateTime = DateTime.now();

      await DatabaseService.updateSampleAnalysis(
        sampleId: widget.sampleId,
        analysisDateTime: analysisDateTime,
        analysisStatus: 'Completed',
      );

      await DatabaseService.saveAnalysisResult({
        'sample_id': widget.sampleId,
        'analysis_date_time':
            analysisDateTime.toIso8601String(),
        'analysis_status': 'Completed',
        'detected_features': '[]',
        'screening_result':
            'Preliminary screening completed. '
            'Detailed image-based screening output will '
            'be generated when the image analysis pipeline '
            'is connected.',
        'confidence': null,
      });

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save screening result: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Screening Result'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (sample == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Screening Result'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Unable to find this sample.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening Result'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Screening Result',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${widget.specimenType} sample • ${widget.sampleId}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 56,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Preliminary Screening',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Analysis completed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Sample Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.image_outlined,
                      ),
                      title: const Text(
                        'Images analysed',
                      ),
                      trailing: Text(
                        '${widget.imageCount}',
                      ),
                    ),

                    const Divider(height: 1),

                    const ListTile(
                      leading: Icon(
                        Icons.check_circle_outline,
                      ),
                      title: Text(
                        'Analysis status',
                      ),
                      trailing: Text(
                        'Completed',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'This screening result is intended '
                          'for preliminary assessment only. '
                          'It does not constitute a clinical '
                          'diagnosis and does not replace '
                          'conventional laboratory testing.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : saveToSampleRecords,
                  child: Text(
                    isSaving
                        ? 'Saving...'
                        : 'Save to Sample Records',
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}