import 'package:flutter/material.dart';

import '../../services/database_service.dart';
import '../patients/register_patient_screen.dart';
import '../screens/images/upload_images_screen.dart';

/// Screen used to create a new biological sample.
///
/// A sample must always be linked to a patient before it can be created.
/// The user can either search for an existing patient or register a new one.
class NewSampleScreen extends StatefulWidget {
  final String? patientId;

  const NewSampleScreen({
    super.key,
    this.patientId,
  });

  @override
  State<NewSampleScreen> createState() =>
      _NewSampleScreenState();
}

class _NewSampleScreenState
    extends State<NewSampleScreen> {
  final TextEditingController searchController =
      TextEditingController();

  final TextEditingController reasonController =
      TextEditingController();

  List<Map<String, dynamic>> patients = [];

  Map<String, dynamic>? selectedPatient;

  String? specimenType;

  DateTime collectionDateTime = DateTime.now();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    searchController.addListener(
      filterPatients,
    );

    loadPatients();
  }

  @override
  void dispose() {
    searchController.removeListener(
      filterPatients,
    );

    searchController.dispose();
    reasonController.dispose();

    super.dispose();
  }

  Future<void> loadPatients() async {
    try {
      final loadedPatients =
          await DatabaseService.getPatients();

      Map<String, dynamic>? initialPatient;

      if (widget.patientId != null) {
        initialPatient =
            await DatabaseService.getPatient(
          widget.patientId!,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        patients = loadedPatients;
        selectedPatient = initialPatient;
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
            'Unable to load patients: $error',
          ),
        ),
      );
    }
  }

  void filterPatients() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  List<Map<String, dynamic>> get filteredPatients {
    final search =
        searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return patients;
    }

    return patients.where((patient) {
      final firstName =
          (patient['first_name'] ?? '')
              .toString()
              .toLowerCase();

      final surname =
          (patient['surname'] ?? '')
              .toString()
              .toLowerCase();

      final patientId =
          (patient['id'] ?? '')
              .toString()
              .toLowerCase();

      return firstName.contains(search) ||
          surname.contains(search) ||
          patientId.contains(search);
    }).toList();
  }

  String patientName(
    Map<String, dynamic> patient,
  ) {
    return '${patient['first_name']} '
        '${patient['surname']}';
  }

  Future<String> generateSampleId(
    String specimen,
  ) async {
    final database =
        await DatabaseService.database;

    final counterType =
        specimen.toLowerCase() == 'urine'
            ? 'urine'
            : 'blood';

    return database.transaction(
      (transaction) async {
        final results =
            await transaction.query(
          'id_counters',
          columns: [
            'next_number',
          ],
          where: 'counter_type = ?',
          whereArgs: [counterType],
          limit: 1,
        );

        int nextNumber;

        if (results.isEmpty) {
          nextNumber = 1;

          await transaction.insert(
            'id_counters',
            {
              'counter_type': counterType,
              'next_number': 2,
            },
          );
        } else {
          nextNumber =
              results.first['next_number'] as int;

          await transaction.update(
            'id_counters',
            {
              'next_number':
                  nextNumber + 1,
            },
            where: 'counter_type = ?',
            whereArgs: [counterType],
          );
        }

        final prefix =
            counterType == 'urine'
                ? 'S-U-'
                : 'S-B-';

        return '$prefix'
            '${nextNumber.toString().padLeft(6, '0')}';
      },
    );
  }

  Future<void> selectPatient(
    Map<String, dynamic> patient,
  ) async {
    FocusScope.of(context).unfocus();

    setState(() {
      selectedPatient = patient;
    });
  }

  Future<void> registerNewPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const RegisterPatientScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result is String) {
      final newlyRegisteredPatient =
          await DatabaseService.getPatient(
        result,
      );

      if (newlyRegisteredPatient != null) {
        setState(() {
          selectedPatient =
              newlyRegisteredPatient;
          searchController.clear();
        });
      }

      await loadPatients();
    } else {
      await loadPatients();
    }
  }

  Future<void> chooseCollectionDateTime() async {
    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate: collectionDateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null ||
        !mounted) {
      return;
    }

    final selectedTime =
        await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        collectionDateTime,
      ),
    );

    if (selectedTime == null ||
        !mounted) {
      return;
    }

    setState(() {
      collectionDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  String formatCollectionDateTime() {
    final day =
        collectionDateTime.day
            .toString()
            .padLeft(2, '0');

    final month =
        collectionDateTime.month
            .toString()
            .padLeft(2, '0');

    final year =
        collectionDateTime.year
            .toString();

    final hour =
        collectionDateTime.hour
            .toString()
            .padLeft(2, '0');

    final minute =
        collectionDateTime.minute
            .toString()
            .padLeft(2, '0');

    return '$day/$month/$year '
        '$hour:$minute';
  }

  Future<void> createSample() async {
    if (selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a patient first.',
          ),
        ),
      );

      return;
    }

    if (specimenType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a specimen type.',
          ),
        ),
      );

      return;
    }

    if (reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the reason for the visit.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final sampleId =
          await generateSampleId(
        specimenType!,
      );

      await DatabaseService.saveSample({
        'id': sampleId,
        'patient_id':
            selectedPatient!['id'],
        'specimen_type':
            specimenType!,
        'reason_for_visit':
            reasonController.text.trim(),
        'collection_date_time':
            collectionDateTime
                .toIso8601String(),
        'analysis_date_time': null,
        'analysis_status': 'Pending',
      });

      if (!mounted) {
        return;
      }

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UploadImagesScreen(
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create sample: $error',
          ),
        ),
      );
    }
  }

  Widget buildSelectedPatientCard() {
    if (selectedPatient == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(
        top: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                (selectedPatient!['first_name'] ??
                        '?')
                    .toString()
                    .substring(0, 1)
                    .toUpperCase(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Patient',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patientName(
                      selectedPatient!,
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Patient ID: '
                    '${selectedPatient!['id']}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedPatient = null;
                });
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPatientSearch() {
    if (selectedPatient != null) {
      return buildSelectedPatientCard();
    }

    final results = filteredPatients;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Search Patient',
            hintText:
                'Name, surname or patient ID',
            prefixIcon:
                const Icon(Icons.search),
            suffixIcon:
                searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                        },
                        icon: const Icon(
                          Icons.clear,
                        ),
                      ),
            border: const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        if (results.isNotEmpty)
          Container(
            constraints:
                const BoxConstraints(
              maxHeight: 240,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder:
                  (context, index) =>
                      const Divider(
                height: 1,
              ),
              itemBuilder:
                  (context, index) {
                final patient =
                    results[index];

                return ListTile(
                  title: Text(
                    patientName(patient),
                  ),
                  subtitle: Text(
                    'Patient ID: '
                    '${patient['id']}',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {
                    selectPatient(patient);
                  },
                );
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: const Text(
              'No matching patients found.',
            ),
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                registerNewPatient,
            icon: const Icon(
              Icons.person_add_outlined,
            ),
            label: const Text(
              'Register New Patient',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sample'),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Sample',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Select the patient and enter '
                      'the sample details.',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Patient',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    buildPatientSearch(),

                    const SizedBox(height: 28),

                    const Text(
                      'Specimen Type',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child:
                              ChoiceChip(
                            label:
                                const Text(
                              'Urine',
                            ),
                            selected:
                                specimenType ==
                                    'Urine',
                            onSelected:
                                (selected) {
                              if (!selected) {
                                return;
                              }

                              setState(() {
                                specimenType =
                                    'Urine';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child:
                              ChoiceChip(
                            label:
                                const Text(
                              'Blood',
                            ),
                            selected:
                                specimenType ==
                                    'Blood',
                            onSelected:
                                (selected) {
                              if (!selected) {
                                return;
                              }

                              setState(() {
                                specimenType =
                                    'Blood';
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Reason for Visit',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller:
                          reasonController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Enter reason for visit',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Collection Date & Time',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    InkWell(
                      onTap:
                          chooseCollectionDateTime,
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                          prefixIcon:
                              Icon(
                            Icons
                                .calendar_today_outlined,
                          ),
                        ),
                        child: Text(
                          formatCollectionDateTime(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            isSaving
                                ? null
                                : createSample,
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Sample',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}