import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/database_service.dart';
import '../../app/routes.dart';

/// Create Account screen for the PocketScope application.
///
/// This screen follows the same visual style as the Login screen.
/// The native device status bar is handled by SafeArea,
/// so the app does not draw a fake status bar.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // ------------------------------------------------------------
  // POCKETSCOPE COLOURS
  // ------------------------------------------------------------

  /// Main PocketScope teal.
  static const Color teal = Color(0xFF087E78);

  /// Main text colour.
  static const Color primaryText = Color(0xFF000000);

  /// Secondary / muted text colour.
  static const Color secondaryText = Color(0xFF60747B);

  /// Main page background from the Figma design.
  static const Color pageBackground = Color(0xFFEEF3F5);

  /// White background used inside the form fields.
  static const Color inputBackground = Color(0xFFFFFFFF);

  /// Light grey outline used around the form fields.
  static const Color inputBorder = Color(0xFFD0D7DA);

  // ------------------------------------------------------------
  // FORM CONTROLLERS
  // ------------------------------------------------------------

  final TextEditingController _fullNameController =
      TextEditingController();

  final TextEditingController _idPassportController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _hpcsaController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ------------------------------------------------------------
  // ACCOUNT STATE
  // ------------------------------------------------------------

  /// Controls whether the password text is visible.
  bool _isPasswordVisible = false;

  /// Controls whether the confirm password text is visible.
  bool _isConfirmPasswordVisible = false;

  /// Stores the selected occupation.
  String? _selectedOccupation;

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _fullNameController.dispose();
    _idPassportController.dispose();
    _emailController.dispose();
    _hpcsaController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 342,
              child: Column(
                children: [
                  // ------------------------------------------------
                  // IDENTITY
                  // ------------------------------------------------
                  // This is kept the same as the Login screen.
                  SizedBox(
                    width: 342,
                    height: 172,
                    child: _buildIdentity(),
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------
                  // ACCOUNT FORM
                  // ------------------------------------------------

                  _buildAccountForm(),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // IDENTITY
  // ------------------------------------------------------------

  Widget _buildIdentity() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // PocketScope logo.
        Image.asset(
          'assets/images/pocketscope_logo.png',
          width: 58,
          height: 58,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 12),

        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Pocket',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              TextSpan(
                text: 'Scope',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: teal,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Mobile Microscopy',
          style: TextStyle(
            fontFamily: 'Inter',
            color: secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // ACCOUNT FORM
  // ------------------------------------------------------------

  Widget _buildAccountForm() {
    return SizedBox(
      width: 342,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full name.
          _buildInputField(
            label: 'Full name',
            hint: 'Enter your full name',
            controller: _fullNameController,
          ),

          const SizedBox(height: 7),

          // ID / Passport number.
          _buildInputField(
            label: 'ID / Passport number',
            hint: 'Enter your ID or passport number',
            controller: _idPassportController,
          ),

          const SizedBox(height: 7),

          // Email.
          _buildInputField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailController,
            iconPath: 'assets/images/mail.svg',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // OCCUPATION
          // --------------------------------------------------------

          const Text(
            'Occupation',
            style: TextStyle(
              fontFamily: 'Inter',
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 8),

          _buildOccupationOptions(),

          const SizedBox(height: 10),

          // HPCSA registration number.
          _buildInputField(
            label: 'HPCSA registration number (optional)',
            hint: 'Enter registration number',
            controller: _hpcsaController,
          ),

          const SizedBox(height: 7),

          // Password.
          _buildInputField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            iconPath: 'assets/images/lock.svg',
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: secondaryText,
                size: 20,
              ),
              splashRadius: 20,
              tooltip: _isPasswordVisible
                  ? 'Hide password'
                  : 'Show password',
            ),
          ),

          const SizedBox(height: 7),

          // Confirm password.
          _buildInputField(
            label: 'Confirm password',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            iconPath: 'assets/images/lock.svg',
            obscureText: !_isConfirmPasswordVisible,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible =
                      !_isConfirmPasswordVisible;
                });
              },
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: secondaryText,
                size: 20,
              ),
              splashRadius: 20,
              tooltip: _isConfirmPasswordVisible
                  ? 'Hide password'
                  : 'Show password',
            ),
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------------
          // CREATE ACCOUNT BUTTON
          // --------------------------------------------------------

          _buildCreateAccountButton(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FORM FIELD
  // ------------------------------------------------------------

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? iconPath,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: 342,
      height: 74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 7),

          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,

              // Entered text is black.
              style: const TextStyle(
                fontFamily: 'Inter',
                color: primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),

              decoration: InputDecoration(
                hintText: hint,

                // Placeholder text remains muted.
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  color: secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),

                // Form fields are white.
                filled: true,
                fillColor: inputBackground,

                // Only show an icon when one is provided.
                prefixIcon: iconPath != null
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: SvgPicture.asset(
                          iconPath,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      )
                    : null,

                suffixIcon: suffixIcon,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: inputBorder,
                    width: 1,
                  ),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: inputBorder,
                    width: 1,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: teal,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // OCCUPATION OPTIONS
  // ------------------------------------------------------------

  Widget _buildOccupationOptions() {
    const occupations = [
      'Nurse',
      'Doctor',
      'Medical Scientist',
      'Laboratory Technician',
      'Other',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: occupations.map((occupation) {
        final bool isSelected =
            _selectedOccupation == occupation;

        return SizedBox(
          height: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      _selectedOccupation =
                          value == true ? occupation : null;
                    });
                  },
                  fillColor:
                      WidgetStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(
                        WidgetState.selected,
                      )) {
                        return teal;
                      }

                      return Colors.white;
                    },
                  ),
                  checkColor: Colors.white,
                  side: const BorderSide(
                    color: teal,
                    width: 1,
                  ),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),

              const SizedBox(width: 4),

              Text(
                occupation,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // CREATE ACCOUNT BUTTON
  // ------------------------------------------------------------

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: 342,
      height: 50,
      child: ElevatedButton(
        onPressed: _createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CREATE ACCOUNT
  // ------------------------------------------------------------

  Future<void> _createAccount() async {
    final fullName = _fullNameController.text.trim();
    final idPassport = _idPassportController.text.trim();
    final email = _emailController.text.trim();
    final hpcsa = _hpcsaController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (fullName.isEmpty ||
        idPassport.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        'Please complete all required fields.',
      );
      return;
    }

    if (_selectedOccupation == null) {
      _showMessage(
        'Please select your occupation.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Passwords do not match.',
      );
      return;
    }

    // ----------------------------------------------------------
    // SHOW LOADING
    // ----------------------------------------------------------

    _showLoadingDialog();

    try {
      // Save the account to SQLite.
      await DatabaseService.saveUser({
        'full_name': fullName,
        'id_passport': idPassport,
        'email': email,
        'occupation': _selectedOccupation!,
        'hpcsa_registration_number':
            hpcsa.isEmpty ? null : hpcsa,
        'password': password,
      });

      if (!mounted) return;

      // Close loading dialog.
      Navigator.of(context).pop();

      // Show account-created confirmation.
      await _showSuccessDialog();

      if (!mounted) return;

      // Return to Login.
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      // Close loading dialog.
      Navigator.of(context).pop();

      // Show the actual error while testing.
      _showMessage(
        'Database error: $error',
      );
    }
  }

  // ------------------------------------------------------------
  // LOADING DIALOG
  // ------------------------------------------------------------

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            color: teal,
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SUCCESS DIALOG
  // ------------------------------------------------------------

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success checkmark.
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Account created successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Please log in to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}