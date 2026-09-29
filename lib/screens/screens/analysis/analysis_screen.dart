import 'package:flutter/material.dart';

import '../../../services/database_service.dart';
import 'screening_result_screen.dart';

/// Screen that displays the analysis process for a sample.
class AnalysisScreen extends StatefulWidget {
  final String sampleId;
  final String specimenType;
  final int imageCount;

  const AnalysisScreen({
    super.key,
    required this.sampleId,
    required this.specimenType,
    required this.imageCount,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int currentStep = 0;
  bool analysisFailed = false;

  final List<String> analysisSteps = [
    'Preparing images',
    'Extracting image features',
    'Analysing image features',
    'Preparing screening result',
  ];

  @override
  void initState() {
    super.initState();

    startAnalysis();
  }

  Future<void> startAnalysis() async {
    try {
      await DatabaseService.updateSampleAnalysis(
        sampleId: widget.sampleId,
        analysisDateTime: DateTime.now(),
        analysisStatus: 'Analysing',
      );

      for (int step = 0; step < analysisSteps.length; step++) {
        await Future.delayed(
          const Duration(seconds: 2),
        );

        if (!mounted) {
          return;
        }

        setState(() {
          currentStep = step + 1;
        });
      }

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
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        analysisFailed = true;
      });

      await DatabaseService.updateSampleAnalysis(
        sampleId: widget.sampleId,
        analysisDateTime: DateTime.now(),
        analysisStatus: 'Failed',
      );
    }
  }

  void viewScreeningResult() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreeningResultScreen(
          sampleId: widget.sampleId,
          specimenType: widget.specimenType,
          imageCount: widget.imageCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool analysisComplete =
        currentStep >= analysisSteps.length &&
            !analysisFailed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sample Analysis',
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.imageCount} image${widget.imageCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Images submitted for automated analysis.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Analysis Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              for (
                int index = 0;
                index < analysisSteps.length;
                index++
              )
                _buildAnalysisStep(index),

              const SizedBox(height: 28),

              if (analysisFailed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'The analysis could not be completed. '
                            'Please try again.',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (analysisComplete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewScreeningResult,
                    child: const Text(
                      'View Screening Result',
                    ),
                  ),
                )
              else
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Analysis in progress...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              const Text(
                'This screening process is intended as a '
                'preliminary assessment and does not replace '
                'conventional laboratory testing or clinical '
                'diagnosis.',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisStep(int index) {
    final bool completed = currentStep > index;
    final bool active = currentStep == index;

    IconData icon;

    if (completed) {
      icon = Icons.check_circle;
    } else if (active) {
      icon = Icons.sync;
    } else {
      icon = Icons.radio_button_unchecked;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          analysisSteps[index],
          style: TextStyle(
            fontWeight: active || completed
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          completed
              ? 'Complete'
              : active
                  ? 'In progress'
                  : 'Waiting',
        ),
      ),
    );
  }
}