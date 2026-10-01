import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/routes.dart';
import '../../services/database_service.dart';
import 'individual_patient_record.dart';

/// Displays the patient directory and patient sample records.
class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() =>
      _PatientRecordsScreenState();
}

class _PatientRecordsScreenState
    extends State<PatientRecordsScreen> {
  // COLOURS
  static const Color teal = Color(0xFF087E78);
  static const Color primaryText = Color(0xFF000000);
  static const Color secondaryText = Color(0xFF60747B);
  static const Color tertiaryText = Color(0xFF94A4A9);
  static const Color pageBackground = Color(0xFFEEF3F5);
  static const Color lightGreen = Color(0xFFE2F3F1);
  static const Color filterBorder = Color(0xFFD8E2E5);
  static const Color searchBorder = Color(0xFFB8C4C8);

  static const Color completeBackground = Color(0xFFE4F3EA);
  static const Color completeText = Color(0xFF2D7D5B);

  static const Color analysisDueBackground = Color(0xFFFFF3DD);
  static const Color analysisDueText = Color(0xFFA66A18);

  static const Color newPatientBackground = Color(0xFFE8F1F8);
  static const Color newPatientText = Color(0xFF326B96);

  // PATIENT DATA
  List<Map<String, dynamic>> _patients = [];

  // SEARCH AND FILTERS
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'All';

  String? _selectedSampleStatus;
  String? _selectedSampleType;

  bool _showFilters = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadPatients();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads all patients and their sample information.
  Future<void> _loadPatients() async {
    try {
      final patients = await DatabaseService.getPatients();

      final patientsWithSamples =
          <Map<String, dynamic>>[];

      for (final patient in patients) {
        final patientId =
            (patient['id'] as String? ?? '').trim();

        final samples =
            await DatabaseService.getSamplesForPatient(
          patientId,
        );

        Map<String, dynamic>? latestSample;

        if (samples.isNotEmpty) {
          latestSample = samples.first;
        }

        patientsWithSamples.add({
          ...patient,
          'latest_sample': latestSample,
        });
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _patients = patientsWithSamples;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Returns the filtered patient list.
  List<Map<String, dynamic>> get _filteredPatients {
    final query =
        _searchController.text.trim().toLowerCase();

    final now = DateTime.now();
    final sevenDaysAgo =
        now.subtract(const Duration(days: 7));

    final filtered = _patients.where((patient) {
      final firstName =
          (patient['first_name'] as String? ?? '').trim();

      final surname =
          (patient['surname'] as String? ?? '').trim();

      final patientId =
          (patient['id'] as String? ?? '').trim();

      final fullName =
          '$firstName $surname'.trim().toLowerCase();

      final latestSample =
          patient['latest_sample']
              as Map<String, dynamic>?;

      final sampleType =
          (latestSample?['specimen_type'] as String? ?? '')
              .trim()
              .toLowerCase();

      final sampleStatus =
          (latestSample?['analysis_status'] as String? ?? '')
              .trim()
              .toLowerCase();

      final collectionDate =
          DateTime.tryParse(
        (latestSample?['collection_date_time']
                    as String? ??
                '')
            .trim(),
      );

      // Search filter.
      final matchesSearch = query.isEmpty ||
          fullName.contains(query) ||
          patientId.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      // Quick filters.
      if (_selectedFilter == 'Needs review') {
        if (latestSample == null ||
            !_isNeedsReviewStatus(sampleStatus)) {
          return false;
        }
      }

      if (_selectedFilter == 'Recent') {
        if (collectionDate == null) {
          return false;
        }

        if (collectionDate.isBefore(sevenDaysAgo) ||
            collectionDate.isAfter(now)) {
          return false;
        }
      }

      // Expanded sample status filters.
      if (_selectedSampleStatus != null) {
        final selectedStatus =
            _selectedSampleStatus!.toLowerCase();

        if (selectedStatus == 'complete' &&
            !_isCompleteStatus(sampleStatus)) {
          return false;
        }

        if (selectedStatus == 'needs review' &&
            (latestSample == null ||
                !_isNeedsReviewStatus(sampleStatus))) {
          return false;
        }
      }

      // Expanded sample type filters.
      if (_selectedSampleType != null) {
        final selectedType =
            _selectedSampleType!.toLowerCase();

        if (selectedType == 'urine sediment' &&
            sampleType != 'urine') {
          return false;
        }

        if (selectedType == 'blood smear' &&
            sampleType != 'blood') {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort alphabetically by FIRST NAME.
    filtered.sort((a, b) {
      final firstNameA =
          (a['first_name'] as String? ?? '')
              .toLowerCase();

      final firstNameB =
          (b['first_name'] as String? ?? '')
              .toLowerCase();

      final firstNameComparison =
          firstNameA.compareTo(firstNameB);

      if (firstNameComparison != 0) {
        return firstNameComparison;
      }

      final surnameA =
          (a['surname'] as String? ?? '')
              .toLowerCase();

      final surnameB =
          (b['surname'] as String? ?? '')
              .toLowerCase();

      return surnameA.compareTo(surnameB);
    });

    return filtered;
  }

  /// Determines whether a sample is complete.
  bool _isCompleteStatus(String status) {
    return status == 'complete' ||
        status == 'completed';
  }

  /// Determines whether a sample needs review.
  bool _isNeedsReviewStatus(String status) {
    return status == 'pending' ||
        status == 'new sample' ||
        status == 'analysis due' ||
        status == 'needs review';
  }

  /// Determines whether a patient has no sample yet.
  bool _isNewPatient(
    Map<String, dynamic> patient,
  ) {
    return patient['latest_sample'] == null;
  }

  /// Calculates the patient's current age.
  int _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null ||
        dateOfBirth.isEmpty) {
      return 0;
    }

    final parsedDate =
        DateTime.tryParse(dateOfBirth);

    if (parsedDate == null) {
      return 0;
    }

    final today = DateTime.now();

    int age =
        today.year - parsedDate.year;

    if (today.month < parsedDate.month ||
        (today.month == parsedDate.month &&
            today.day < parsedDate.day)) {
      age--;
    }

    return age;
  }

  /// Returns the patient's sex assigned at birth abbreviation.
  String _getSexAbbreviation(String? sex) {
    final value =
        (sex ?? '').trim().toLowerCase();

    if (value == 'male') {
      return 'M';
    }

    if (value == 'female') {
      return 'F';
    }

    return 'I';
  }

  /// Formats a sample collection date as 30 Sep.
  String _formatSampleDate(String? dateTime) {
    if (dateTime == null ||
        dateTime.isEmpty) {
      return '--';
    }

    final parsed =
        DateTime.tryParse(dateTime);

    if (parsed == null) {
      return '--';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${parsed.day} ${months[parsed.month - 1]}';
  }

  /// Returns the display name of a specimen type.
  String _getSampleTypeName(String? specimenType) {
    final type =
        (specimenType ?? '').trim().toLowerCase();

    if (type == 'urine') {
      return 'Urine sediment';
    }

    if (type == 'blood') {
      return 'Blood smear';
    }

    return specimenType?.trim().isNotEmpty == true
        ? specimenType!.trim()
        : 'No sample';
  }

  /// Generates patient initials.
  String _getInitials(
    String firstName,
    String surname,
  ) {
    final first = firstName.trim();
    final last = surname.trim();

    if (first.isEmpty && last.isEmpty) {
      return '?';
    }

    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }

    final name =
        first.isNotEmpty ? first : last;

    return name[0].toUpperCase();
  }

  /// Returns the first letter used for directory grouping.
  String _getDirectoryLetter(
    Map<String, dynamic> patient,
  ) {
    final firstName =
        (patient['first_name'] as String? ?? '').trim();

    if (firstName.isEmpty) {
      return '#';
    }

    return firstName[0].toUpperCase();
  }

  /// Clears all active filters.
  void _clearFilters() {
    setState(() {
      _selectedFilter = 'All';
      _selectedSampleStatus = null;
      _selectedSampleType = null;
    });
  }

  /// Opens the patient registration screen.
  void _openNewPatient() {
    Navigator.pushNamed(
      context,
      AppRoutes.registerPatient,
    ).then((_) {
      _loadPatients();
    });
  }

  /// Returns the number of active patient records.
  String _activeRecordLabel() {
    final count = _patients.length;

    return count == 1
        ? '1 active record'
        : '$count active records';
  }

  /// Returns the colours used by a patient's status.
  List<Color> _getStatusColours(
    Map<String, dynamic> patient,
  ) {
    if (_isNewPatient(patient)) {
      return [
        newPatientBackground,
        newPatientText,
      ];
    }

    final latestSample =
        patient['latest_sample']
            as Map<String, dynamic>?;

    final status =
        (latestSample?['analysis_status']
                    as String? ??
                '')
            .trim()
            .toLowerCase();

    if (_isCompleteStatus(status)) {
      return [
        completeBackground,
        completeText,
      ];
    }

    return [
      analysisDueBackground,
      analysisDueText,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTitleBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _buildBottomNavigationBar(),
    );
  }

  /// Builds the 78px title bar.
  Widget _buildTitleBar() {
    return SizedBox(
      height: 78,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patients',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeRecordLabel(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _openNewPatient,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: teal,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/images/user-plus.svg',
                      width: 19,
                      height: 19,
                      colorFilter:
                          const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Add patient',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: teal,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the patient directory content.
  Widget _buildContent() {
    return Container(
      width: double.infinity,
      color: pageBackground,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 9),
            _buildFilterPills(),
            if (_showFilters) ...[
              const SizedBox(height: 10),
              _buildExpandedFilters(),
            ],
            const SizedBox(height: 18),
            _buildDirectory(),
            const SizedBox(height: 18),
            _buildClinicNotice(),
          ],
        ),
      ),
    );
  }

  /// Builds the search bar and filter button.
  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: searchBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          SvgPicture.asset(
            'assets/images/search.svg',
            width: 17,
            height: 17,
            colorFilter:
                const ColorFilter.mode(
              secondaryText,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              decoration:
                  const InputDecoration(
                hintText:
                    'Search name or patient ID',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showFilters =
                    !_showFilters;
              });
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 13,
              ),
              child: SvgPicture.asset(
                'assets/images/sliders-horizontal.svg',
                width: 18,
                height: 18,
                colorFilter:
                    const ColorFilter.mode(
                  secondaryText,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the quick filter pills.
  Widget _buildFilterPills() {
    const filters = [
      'All',
      'Needs review',
      'Recent',
    ];

    return SizedBox(
      height: 27,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter =
              filters[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter =
                    filter;

                _selectedSampleStatus =
                    null;
                _selectedSampleType =
                    null;
              });
            },
            child: _buildFilterPill(
              filter,
              selected:
                  _selectedFilter == filter,
            ),
          );
        },
      ),
    );
  }

  /// Builds an individual quick filter pill.
  Widget _buildFilterPill(
    String label, {
    required bool selected,
  }) {
    return Container(
      height: 27,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      decoration: BoxDecoration(
        color: selected
            ? teal
            : Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? teal
              : filterBorder,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          color: selected
              ? Colors.white
              : secondaryText,
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }

  /// Builds the expanded filter controls.
  Widget _buildExpandedFilters() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: primaryText,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _clearFilters,
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: teal,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Sample status',
            style: TextStyle(
              fontFamily: 'Inter',
              color: secondaryText,
              fontSize: 10,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildExpandedFilterOption(
                'Complete',
                selected:
                    _selectedSampleStatus ==
                        'Complete',
                onTap: () {
                  setState(() {
                    _selectedSampleStatus =
                        _selectedSampleStatus ==
                                'Complete'
                            ? null
                            : 'Complete';
                    _selectedSampleType =
                        null;
                    _selectedFilter =
                        'All';
                  });
                },
              ),
              _buildExpandedFilterOption(
                'Needs review',
                selected:
                    _selectedSampleStatus ==
                        'Needs review',
                onTap: () {
                  setState(() {
                    _selectedSampleStatus =
                        _selectedSampleStatus ==
                                'Needs review'
                            ? null
                            : 'Needs review';
                    _selectedSampleType =
                        null;
                    _selectedFilter =
                        'All';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Sample type',
            style: TextStyle(
              fontFamily: 'Inter',
              color: secondaryText,
              fontSize: 10,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildExpandedFilterOption(
                'Urine sediment',
                selected:
                    _selectedSampleType ==
                        'Urine sediment',
                onTap: () {
                  setState(() {
                    _selectedSampleType =
                        _selectedSampleType ==
                                'Urine sediment'
                            ? null
                            : 'Urine sediment';
                    _selectedSampleStatus =
                        null;
                    _selectedFilter =
                        'All';
                  });
                },
              ),
              _buildExpandedFilterOption(
                'Blood smear',
                selected:
                    _selectedSampleType ==
                        'Blood smear',
                onTap: () {
                  setState(() {
                    _selectedSampleType =
                        _selectedSampleType ==
                                'Blood smear'
                            ? null
                            : 'Blood smear';
                    _selectedSampleStatus =
                        null;
                    _selectedFilter =
                        'All';
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an expanded filter option.
  Widget _buildExpandedFilterOption(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 27,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? teal
              : Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? teal
                : filterBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: selected
                ? Colors.white
                : secondaryText,
            fontSize: 10,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Builds the alphabetical patient directory.
  Widget _buildDirectory() {
    if (_isLoading) {
      return const SizedBox(
        width: double.infinity,
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: teal,
          ),
        ),
      );
    }

    final patients =
        _filteredPatients;

    if (patients.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: const Center(
          child: Text(
            'No patient records found',
            style: TextStyle(
              fontFamily: 'Inter',
              color: secondaryText,
              fontSize: 11,
              fontWeight:
                  FontWeight.w400,
            ),
          ),
        ),
      );
    }

    final groups =
        <String, List<Map<String, dynamic>>>{};

    for (final patient in patients) {
      final letter =
          _getDirectoryLetter(patient);

      groups.putIfAbsent(
        letter,
        () => [],
      );

      groups[letter]!.add(patient);
    }

    final letters =
        groups.keys.toList()..sort();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        for (final letter in letters) ...[
          Padding(
            padding:
                const EdgeInsets.only(
              left: 2,
              bottom: 6,
            ),
            child: Text(
              letter,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: teal,
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
          _buildPatientGroup(
            groups[letter]!,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Builds a visually grouped set of patient cards.
  Widget _buildPatientGroup(
    List<Map<String, dynamic>> patients,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: Column(
        children: [
          for (int index = 0;
              index < patients.length;
              index++)
            _buildPatientCard(
              patients[index],
              isFirst: index == 0,
              isLast:
                  index == patients.length - 1,
            ),
        ],
      ),
    );
  }

  /// Builds an individual patient directory card.
  Widget _buildPatientCard(
    Map<String, dynamic> patient, {
    required bool isFirst,
    required bool isLast,
  }) {
    final firstName =
        (patient['first_name'] as String? ?? '')
            .trim();

    final surname =
        (patient['surname'] as String? ?? '')
            .trim();

    final patientName =
        '$firstName $surname'.trim();

    final patientId =
        (patient['id'] as String? ?? '')
            .trim();

    final age = _calculateAge(
      patient['date_of_birth'] as String?,
    );

    final sex =
        _getSexAbbreviation(
      patient['sex_at_birth'] as String?,
    );

    final latestSample =
        patient['latest_sample']
            as Map<String, dynamic>?;

    final sampleType =
        _getSampleTypeName(
      latestSample?['specimen_type']
          as String?,
    );

    final sampleDate =
        _formatSampleDate(
      latestSample?['collection_date_time']
          as String?,
    );

    final statusColours =
        _getStatusColours(patient);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                IndividualPatientRecord(
              patientId: patientId,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 72,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: isFirst
                ? const Radius.circular(12)
                : Radius.zero,
            topRight: isFirst
                ? const Radius.circular(12)
                : Radius.zero,
            bottomLeft: isLast
                ? const Radius.circular(12)
                : Radius.zero,
            bottomRight: isLast
                ? const Radius.circular(12)
                : Radius.zero,
          ),
          border: !isLast
              ? const Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8EEF0),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // Patient initials use the same
            // colour system as the status tags.
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(
                color:
                    statusColours[0],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _getInitials(
                  firstName,
                  surname,
                ),
                style: TextStyle(
                  fontFamily: 'Inter',
                  color:
                      statusColours[1],
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Patient information.
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName.isEmpty
                        ? 'Unknown patient'
                        : patientName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: primaryText,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$patientId Â· $sex Â· $age years',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: secondaryText,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w400,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sampleType Â· $sampleDate',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: tertiaryText,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w400,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 7),

            // Patient status.
            _buildStatusPill(patient),
          ],
        ),
      ),
    );
  }

  /// Builds the patient status pill.
  Widget _buildStatusPill(
    Map<String, dynamic> patient,
  ) {
    Color backgroundColor;
    Color textColor;
    String displayStatus;

    if (_isNewPatient(patient)) {
      backgroundColor =
          newPatientBackground;
      textColor = newPatientText;
      displayStatus = 'New Patient';
    } else {
      final latestSample =
          patient['latest_sample']
              as Map<String, dynamic>?;

      final normalised =
          (latestSample?['analysis_status']
                      as String? ??
                  '')
              .trim()
              .toLowerCase();

      if (_isCompleteStatus(normalised)) {
        backgroundColor =
            completeBackground;
        textColor = completeText;
        displayStatus = 'Complete';
      } else {
        backgroundColor =
            analysisDueBackground;
        textColor = analysisDueText;
        displayStatus = 'Needs review';
      }
    }

    return Container(
      height: 23,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          // Six-pixel status dot SVG used
          // inside the patient status tag.
          SvgPicture.asset(
            'assets/images/status dot.svg',
            width: 6,
            height: 6,
            colorFilter:
                ColorFilter.mode(
              textColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            displayStatus,
            style: TextStyle(
              fontFamily: 'Inter',
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the clinic assignment notice.
  Widget _buildClinicNotice() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/shield-check.svg',
            width: 18,
            height: 18,
            colorFilter:
                const ColorFilter.mode(
              teal,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Only records assigned to your clinic are shown.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: teal,
                fontSize: 10,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the bottom navigation bar.
  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE3E8EA),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildNavigationItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: false,
            onTap: () {},
          ),
          _buildNavigationItem(
            icon: Icons.people_outline,
            label: 'Patients',
            selected: true,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.patientRecords,
              );
            },
          ),
          _buildNavigationItem(
            icon: Icons.camera_alt_outlined,
            label: 'Capture',
            selected: false,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.newSample,
              );
            },
          ),
          _buildNavigationItem(
            icon: Icons.description_outlined,
            label: 'Reports',
            selected: false,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.patientRecords,
              );
            },
          ),
        ],
      ),
    ),
    );
  }

  /// Builds an individual bottom navigation item.
  Widget _buildNavigationItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? teal : secondaryText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: selected ? teal : secondaryText,
                fontSize: 9,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: selected ? 20 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}