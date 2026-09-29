import 'package:flutter/material.dart';

import '../../services/database_service.dart';
import 'individual_patient_record.dart';
import 'register_patient_screen.dart';

/// Displays all registered patients and allows the user
/// to search for a patient or open an individual record.
class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({
    super.key,
  });

  @override
  State<PatientRecordsScreen> createState() =>
      _PatientRecordsScreenState();
}

class _PatientRecordsScreenState
    extends State<PatientRecordsScreen> {
  final TextEditingController searchController =
      TextEditingController();

  List<Map<String, dynamic>> patients = [];

  bool isLoading = true;

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

    super.dispose();
  }

  Future<void> loadPatients() async {
    try {
      final loadedPatients =
          await DatabaseService.getPatients();

      if (!mounted) {
        return;
      }

      setState(() {
        patients = loadedPatients;
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

  Future<void> openPatient(
    Map<String, dynamic> patient,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            IndividualPatientRecord(
          patientId:
              patient['id'] as String,
        ),
      ),
    );

    await loadPatients();
  }

  Future<void> registerPatient() async {
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

    await loadPatients();

    if (result is String) {
      final newPatient =
          await DatabaseService.getPatient(
        result,
      );

      if (newPatient != null &&
          mounted) {
        await openPatient(newPatient);
      }
    }
  }

  Widget buildPatientCard(
    Map<String, dynamic> patient,
  ) {
    final name = patientName(patient);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        onTap: () => openPatient(patient),
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  (patient['first_name'] ??
                          '?')
                      .toString()
                      .substring(0, 1)
                      .toUpperCase(),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patient ID: '
                      '${patient['id']}',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredPatients;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Records',
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: registerPatient,
        icon: const Icon(
          Icons.person_add_outlined,
        ),
        label: const Text(
          'Register Patient',
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: loadPatients,
                child:
                    SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    100,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Records',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        'Search for a patient '
                        'or open a record.',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      TextField(
                        controller:
                            searchController,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Search Patient',
                          hintText:
                              'Name, surname or patient ID',
                          prefixIcon:
                              const Icon(
                            Icons.search,
                          ),
                          suffixIcon:
                              searchController
                                      .text
                                      .isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed:
                                          () {
                                        searchController
                                            .clear();
                                      },
                                      icon:
                                          const Icon(
                                        Icons
                                            .clear,
                                      ),
                                    ),
                          border:
                              const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      if (filtered.isEmpty)
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(24),
                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color: Colors
                                  .grey
                                  .shade300,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .person_search_outlined,
                                size: 42,
                                color: Colors
                                    .grey
                                    .shade500,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                patients.isEmpty
                                    ? 'No patients registered yet.'
                                    : 'No matching patients found.',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Text(
                                patients.isEmpty
                                    ? 'Register a patient to get started.'
                                    : 'Try a different name or patient ID.',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filtered.map(
                          buildPatientCard,
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}