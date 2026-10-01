import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes.dart';
import '../services/database_service.dart';

/// Displays the main PocketScope dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // COLOURS
  static const Color teal = Color(0xFF087E78);
  static const Color primaryText = Color(0xFF000000);
  static const Color secondaryText = Color(0xFF60747B);
  static const Color pageBackground = Color(0xFFEEF3F5);
  static const Color lightGreen = Color(0xFFE2F3F1);

  static const Color completeBackground = Color(0xFFE4F3EA);
  static const Color completeText = Color(0xFF2D7D5B);

  static const Color analysisDueBackground = Color(0xFFFFF3DD);
  static const Color analysisDueText = Color(0xFFA66A18);

  static const Color newSampleBackground = Color(0xFFE8F1F8);
  static const Color newSampleText = Color(0xFF326B96);

  // USER INFORMATION
  String _firstName = '';
  String _fullName = '';
  String _occupation = '';
  String _hpcsaNumber = '';
  String _clinic = '';

  bool _isLoadingUser = true;

  // DASHBOARD COUNTS
  int _patientCount = 0;
  int _sampleCount = 0;
  int _pendingCount = 0;

  // RECENT REPORTS
  List<Map<String, dynamic>> _recentSamples = [];

  bool _isLoadingDashboard = true;

  @override
  void initState() {
    super.initState();

    _loadUser();
    _loadDashboardData();
  }

  /// Loads the currently logged-in user's information.
  Future<void> _loadUser() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final userId = preferences.getInt('logged_in_user_id');

      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }

        return;
      }

      final user = await DatabaseService.getUser(userId);

      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }

        return;
      }

      final fullName = (user['full_name'] as String? ?? '').trim();

      final nameParts = fullName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();

      final firstName = nameParts.isNotEmpty ? nameParts.first : '';

      if (!mounted) {
        return;
      }

      setState(() {
        _fullName = fullName;
        _firstName = firstName;
        _occupation = (user['occupation'] as String? ?? '').trim();
        _hpcsaNumber =
            (user['hpcsa_registration_number'] as String? ?? '').trim();

        // Facility is not currently stored in the users table.
        _clinic = '';

        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  /// Loads the dashboard counts and most recent reports.
  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        DatabaseService.getPatientCount(),
        DatabaseService.getSampleCount(),
        DatabaseService.getPendingSampleCount(),
        DatabaseService.getRecentSamples(limit: 3),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _patientCount = results[0] as int;
        _sampleCount = results[1] as int;
        _pendingCount = results[2] as int;
        _recentSamples = results[3] as List<Map<String, dynamic>>;
        _isLoadingDashboard = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }

  /// Returns a greeting based on the current time.
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  /// Returns the user's professional title and full name.
  String _displayProfessionalName() {
    if (_occupation.isEmpty || _fullName.isEmpty) {
      return _fullName;
    }

    return '$_occupation $_fullName';
  }

  /// Calculates the patient's current age from their date of birth.
  int _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) {
      return 0;
    }

    final parsedDate = DateTime.tryParse(dateOfBirth);

    if (parsedDate == null) {
      return 0;
    }

    final today = DateTime.now();

    int age = today.year - parsedDate.year;

    if (today.month < parsedDate.month ||
        (today.month == parsedDate.month &&
            today.day < parsedDate.day)) {
      age--;
    }

    return age;
  }

  /// Generates initials from a patient's first name and surname.
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

    final name = first.isNotEmpty ? first : last;

    return name[0].toUpperCase();
  }

  /// Generates initials from the logged-in user's full name.
  String _getInitialsFromFullName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Opens the user's profile editing area.
  void _openEditProfile() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Profile editing will be added next.',
            style: TextStyle(
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
  }

  /// Formats the current date for the dashboard header.
  String _formatDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildUserInformationBar(),
            Expanded(
              child: RefreshIndicator(
                color: teal,
                onRefresh: () async {
                  await Future.wait([
                    _loadUser(),
                    _loadDashboardData(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetrics(),
                      const SizedBox(height: 16),
                      _buildPatientActions(),
                      const SizedBox(height: 20),
                      _buildRecentSamplesSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Builds the dashboard header with the date, greeting and profile button.
  Widget _buildHeader() {
    final greeting = _getGreeting();

    return Container(
      width: double.infinity,
      height: 66,
      color: pageBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _isLoadingUser
                      ? greeting
                      : '$greeting, $_firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Profile picture and edit profile.
          GestureDetector(
            onTap: _openEditProfile,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 1,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile picture stays completely unchanged.
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: teal,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitialsFromFullName(_fullName),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Edit profile is always displayed as a white pill.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Edit profile',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the professional information shown underneath the header.
  Widget _buildUserInformationBar() {
    final professionalName = _displayProfessionalName();

    final details = <String>[
      if (professionalName.isNotEmpty) professionalName,
      if (_hpcsaNumber.isNotEmpty) 'HPCSA $_hpcsaNumber',
      _clinic.isNotEmpty ? 'Facility: $_clinic' : 'Facility: Missing',
    ];

    return Container(
      width: double.infinity,
      height: 51,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: pageBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int index = 0; index < details.length; index++) ...[
            Text(
              details[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.0,
              ),
            ),
            if (index < details.length - 1)
              const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  /// Builds the New Patient and Existing Patient action cards.
  Widget _buildPatientActions() {
    return Row(
      children: [
        Expanded(
          child: _buildPatientActionCard(
            title: 'New Patient',
            description: 'Upload information',
            backgroundColor: Colors.white,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.registerPatient,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPatientActionCard(
            title: 'Existing Patient',
            description: 'Find information',
            backgroundColor: Colors.white,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.patientRecords,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds an individual patient action card.
  Widget _buildPatientActionCard({
    required String title,
    required String description,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 97,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/users.svg',
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(
                teal,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w400,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the three dashboard metric cards.
  Widget _buildMetrics() {
    return SizedBox(
      height: 87,
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              iconPath: 'assets/images/users.svg',
              value: _patientCount.toString(),
              label: 'patients',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
              iconPath: 'assets/images/layers-3.svg',
              value: _sampleCount.toString(),
              label: 'samples',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
              iconPath: 'assets/images/clock-3.svg',
              value: _pendingCount.toString(),
              label: 'pending',
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an individual dashboard metric card.
  Widget _buildMetricCard({
    required String iconPath,
    required String value,
    required String label,
  }) {
    return Container(
      height: 87,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: teal.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              teal,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Recent Reports section.
  Widget _buildRecentSamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Reports',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.patientRecords,
                );
              },
              child: const Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoadingDashboard)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: teal,
              ),
            ),
          )
        else if (_recentSamples.isEmpty)
          _buildEmptyRecentReports()
        else
          Column(
            children: [
              for (int index = 0;
                  index < _recentSamples.length;
                  index++) ...[
                _buildRecentSampleCard(
                  _recentSamples[index],
                ),
                if (index < _recentSamples.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }

  /// Builds the empty state shown when there are no recent reports.
  Widget _buildEmptyRecentReports() {
    return Container(
      width: double.infinity,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'No recent reports',
        style: TextStyle(
          fontFamily: 'Inter',
          color: secondaryText,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// Builds an individual recent report card.
  Widget _buildRecentSampleCard(
    Map<String, dynamic> sample,
  ) {
    final firstName =
        (sample['first_name'] as String? ?? '').trim();

    final surname =
        (sample['surname'] as String? ?? '').trim();

    final patientName = '$firstName $surname'.trim();

    final age = _calculateAge(
      sample['date_of_birth'] as String?,
    );

    // The database query returns the sample number as sample_id.
    final sampleNumber =
        (sample['sample_id'] ?? '').toString().trim();

    final status =
        (sample['analysis_status'] as String? ??
                'New Sample')
            .trim();

    return Container(
      width: double.infinity,
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Patient initials circle.
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(
                firstName,
                surname,
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                color: teal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Patient name, sample ID and age.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName.isEmpty
                      ? 'Unknown patient'
                      : patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sample ID: $sampleNumber Â· $age years',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Report status.
          _buildStatusPill(status),
        ],
      ),
    );
  }

  /// Builds the coloured status pill for a recent report.
  Widget _buildStatusPill(String status) {
    Color backgroundColor;
    Color textColor;

    final normalised = status.toLowerCase().trim();

    if (normalised == 'complete' ||
        normalised == 'completed') {
      backgroundColor = completeBackground;
      textColor = completeText;
    } else if (normalised == 'analysis due') {
      backgroundColor = analysisDueBackground;
      textColor = analysisDueText;
    } else {
      backgroundColor = newSampleBackground;
      textColor = newSampleText;
    }

    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'â€¢',
            style: TextStyle(
              fontFamily: 'Inter',
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Inter',
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.0,
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
            selected: true,
            onTap: () {},
          ),
          _buildNavigationItem(
            icon: Icons.people_outline,
            label: 'Patients',
            selected: false,
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