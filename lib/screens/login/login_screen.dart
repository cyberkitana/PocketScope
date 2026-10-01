import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes.dart';
import '../../services/database_service.dart';

/// Login screen for the PocketScope application.
///
/// This screen follows the Figma login layout.
/// The native device status bar is handled by SafeArea,
/// so the app does not draw a fake status bar.
///
/// Login functionality:
/// - Checks the saved PocketScope account.
/// - Supports Remember me.
/// - Supports local password reset for the prototype.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ------------------------------------------------------------
  // POCKETSCOPE COLOURS
  // ------------------------------------------------------------

  /// Main PocketScope teal.
  static const Color teal = Color(0xFF087E78);

  /// Darker teal used for privacy text.
  static const Color darkTeal = Color(0xFF075D5B);

  /// Main text colour.
  static const Color primaryText = Color(0xFF000000);

  /// Secondary / muted text colour.
  static const Color secondaryText = Color(0xFF60747B);

  /// Main page background from the Figma design.
  static const Color pageBackground = Color(0xFFEEF3F5);

  /// Light green used for highlighted sections.
  static const Color lightGreen = Color(0xFFE2F3F1);

  /// White background used inside the form fields.
  static const Color inputBackground = Color(0xFFFFFFFF);

  /// Light grey outline used around the form fields.
  static const Color inputBorder = Color(0xFFD0D7DA);

  // ------------------------------------------------------------
  // CONTROLLERS
  // ------------------------------------------------------------

  /// Reads the email entered by the user.
  final TextEditingController _emailController =
      TextEditingController();

  /// Reads the password entered by the user.
  final TextEditingController _passwordController =
      TextEditingController();

  // ------------------------------------------------------------
  // LOGIN STATE
  // ------------------------------------------------------------

  /// Controls whether the password text is visible.
  bool _isPasswordVisible = false;

  /// Controls whether Remember me is selected.
  bool _rememberMe = false;

  /// Prevents multiple login requests at once.
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();

    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // REMEMBERED EMAIL
  // ------------------------------------------------------------

  /// Loads the email saved by Remember me.
  Future<void> _loadRememberedEmail() async {
    final preferences = await SharedPreferences.getInstance();

    final rememberedEmail =
        preferences.getString('remembered_email');

    if (!mounted) {
      return;
    }

    if (rememberedEmail != null &&
        rememberedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = rememberedEmail;
        _rememberMe = true;
      });
    }
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  /// Checks the entered credentials and logs the user in.
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter your email and password.',
      );
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final user = await DatabaseService.loginUser(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (user == null) {
        setState(() {
          _isLoggingIn = false;
        });

        _showMessage(
          'Incorrect email or password.',
        );
        return;
      }

      // --------------------------------------------------------
      // REMEMBER ME
      // --------------------------------------------------------

      final preferences =
          await SharedPreferences.getInstance();

      if (_rememberMe) {
        await preferences.setString(
          'remembered_email',
          email,
        );
      } else {
        await preferences.remove(
          'remembered_email',
        );
      }

      // Save the currently logged-in user.
      //
      // This will allow the Home screen to load the real
      // user's details instead of using hard-coded information.
      await preferences.setInt(
        'logged_in_user_id',
        user['id'] as int,
      );

      await preferences.setString(
        'logged_in_user_name',
        user['full_name'] as String,
      );

      setState(() {
        _isLoggingIn = false;
      });

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoggingIn = false;
      });

      _showMessage(
        'Unable to log in. Please try again.',
      );
    }
  }

  // ------------------------------------------------------------
  // FORGOT PASSWORD
  // ------------------------------------------------------------

  /// Opens the password reset dialog.
  ///
  /// This is a local prototype flow.
  /// A production version would use a secure server-side
  /// password reset process instead.
  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final newPasswordController =
        TextEditingController();

    final confirmPasswordController =
        TextEditingController();

    bool newPasswordVisible = false;
    bool confirmPasswordVisible = false;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Reset password',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller:
                          newPasswordController,
                      obscureText:
                          !newPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              newPasswordVisible =
                                  !newPasswordVisible;
                            });
                          },
                          icon: Icon(
                            newPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller:
                          confirmPasswordController,
                      obscureText:
                          !confirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText:
                            'Confirm password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              confirmPasswordVisible =
                                  !confirmPasswordVisible;
                            });
                          },
                          icon: Icon(
                            confirmPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: secondaryText,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final email =
                        emailController.text.trim();

                    final newPassword =
                        newPasswordController.text;

                    final confirmPassword =
                        confirmPasswordController.text;

                    if (email.isEmpty ||
                        newPassword.isEmpty ||
                        confirmPassword.isEmpty) {
                      _showMessage(
                        'Please complete all fields.',
                      );
                      return;
                    }

                    if (newPassword !=
                        confirmPassword) {
                      _showMessage(
                        'The passwords do not match.',
                      );
                      return;
                    }

                    if (newPassword.length < 6) {
                      _showMessage(
                        'Password must be at least 6 characters.',
                      );
                      return;
                    }

                    final user =
                        await DatabaseService
                            .getUserByEmail(email);

                    if (user == null) {
                      _showMessage(
                        'No account was found for this email.',
                      );
                      return;
                    }

                    await DatabaseService
                        .updateUserPassword(
                      email: email,
                      newPassword: newPassword,
                    );

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Reset password',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (!mounted || shouldReset != true) {
      return;
    }

    _emailController.text =
        emailController.text.trim();

    _passwordController.clear();

    _showMessage(
      'Password reset successfully. Please log in.',
    );
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
                  SizedBox(
                    width: 342,
                    height: 172,
                    child: _buildIdentity(),
                  ),
                  const SizedBox(height: 10),
                  _buildLoginForm(),
                  const SizedBox(height: 10),
                  _buildPrivacyNotice(),
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
  // LOGIN FORM
  // ------------------------------------------------------------

  Widget _buildLoginForm() {
    return SizedBox(
      width: 342,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildInputField(
            label: 'Email',
            hint: 'Enter your email',
            iconPath: 'assets/images/mail.svg',
            controller: _emailController,
            keyboardType:
                TextInputType.emailAddress,
          ),
          const SizedBox(height: 7),
          _buildInputField(
            label: 'Password',
            hint: 'Enter your password',
            iconPath: 'assets/images/lock.svg',
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible =
                      !_isPasswordVisible;
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
          const SizedBox(height: 10),
          _buildFormOptions(),
          const SizedBox(height: 16),
          _buildLoginButton(),
          const SizedBox(height: 16),
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
    required String iconPath,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 20,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
              style: const TextStyle(
                fontFamily: 'Inter',
                color: primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  color: secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: inputBackground,
                prefixIcon: Padding(
                  padding:
                      const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                suffixIcon: suffixIcon,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
                    color: inputBorder,
                    width: 1,
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
                    color: inputBorder,
                    width: 1,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(
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
  // REMEMBER ME / FORGOT PASSWORD
  // ------------------------------------------------------------

  Widget _buildFormOptions() {
    return SizedBox(
      width: 342,
      height: 20,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe =
                      value ?? false;
                });
              },
              fillColor:
                  WidgetStateProperty
                      .resolveWith<Color>(
                (states) {
                  if (states.contains(
                    WidgetState.selected,
                  )) {
                    return teal;
                  }

                  return lightGreen;
                },
              ),
              checkColor: Colors.white,
              side: const BorderSide(
                color: teal,
                width: 1,
              ),
              materialTapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
              visualDensity:
                  VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Remember me',
            style: TextStyle(
              fontFamily: 'Inter',
              color: secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Flexible(
          child: GestureDetector(
            onTap: _forgotPassword,
            child: const Text(
              'Forgot password?',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                color: teal,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LOG IN BUTTON
  // ------------------------------------------------------------

  Widget _buildLoginButton() {
    return SizedBox(
      width: 342,
      height: 50,
      child: ElevatedButton(
        onPressed:
            _isLoggingIn ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              teal.withValues(alpha: 0.6),
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        child: _isLoggingIn
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Log in',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CREATE ACCOUNT BUTTON
  // ------------------------------------------------------------

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: 342,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.createAccount,
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryText,
          padding: EdgeInsets.zero,
          side: const BorderSide(
            color: inputBorder,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(
            fontFamily: 'Inter',
            color: primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PRIVACY NOTICE
  // ------------------------------------------------------------

  Widget _buildPrivacyNotice() {
    return Container(
      width: 342,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 12,
            ),
            child: SvgPicture.asset(
              'assets/images/lock-keyhole.svg',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
          const Expanded(
            child: Text(
              'Patient data is strictly confidential. Never share your access credentials.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: darkTeal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}