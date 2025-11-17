// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/chore_state.dart';
import '../models/reward_state.dart';
import '../models/user_state.dart';
import '../widgets/notification_helper.dart';
import '../utils/chorepal_colors.dart';
import 'parent/enhanced_parent_dashboard.dart';
import 'child/enhanced_child_dashboard.dart';

/// Login screen for the ChorePal app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Form keys
  final _parentFormKey = GlobalKey<FormState>();
  final _childFormKey = GlobalKey<FormState>();

  // Tab controller
  late TabController _tabController;

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRegistering = false;

  // Parent login fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  // Child login fields
  final _childNameController = TextEditingController();
  final _familyCodeController = TextEditingController();
  // Services
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Theme colors
  // Removed hardcoded text color - now using Theme.of(context)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneNumberController.dispose();
    _childNameController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? ChorePalColors.darkBackgroundGradient
              : ChorePalColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabSelector(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildParentLoginForm(),
                    _buildChildLoginForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the app header with logo and title
  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 40),
        Image.asset(
          'assets/images/chorepal-logo-ideas.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Text(
          'ChorePal',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: isDarkMode ? Colors.white : const Color(0xFF333333),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Helping families manage chores together',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    isDarkMode ? Colors.grey.shade300 : const Color(0xFF666666),
              ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  /// Builds the tab selector
  Widget _buildTabSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 50),
      child: Material(
        color: Colors.transparent,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: isDarkMode
                ? ChorePalColors.darkBlue
                : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(25),
          ),
          labelColor: Colors.white,
          unselectedLabelColor:
              isDarkMode ? Colors.grey.shade300 : const Color(0xFF333333),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'Parent'),
            Tab(text: 'Child'),
          ],
        ),
      ),
    );
  }

  /// Builds the parent login form
  Widget _buildParentLoginForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _parentFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRegistering ? 'Create Parent Account' : 'Parent Login',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF333333),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (_isRegistering) _buildNameField(),
                  if (_isRegistering) _buildPhoneNumberField(),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  if (!_isRegistering) _buildForgotPasswordLink(),
                  if (_errorMessage != null) _buildErrorMessage(),
                  const SizedBox(height: 24),
                  _buildParentActionButton(),
                  const SizedBox(height: 16),
                  _buildToggleAuthModeButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the phone number field for parent registration
  Widget _buildPhoneNumberField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        TextFormField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number (Optional)',
            hintText: '+18777804236 (E.164 format)',
            prefixIcon: isDarkMode
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: ChorePalColors.darkBlueGradient,
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.all(8),
                    child:
                        const Icon(Icons.phone, color: Colors.white, size: 20),
                  )
                : Icon(Icons.phone, color: ChorePalColors.darkBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ChorePalColors.darkBlue, width: 2),
            ),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty && !value.startsWith('+')) {
              return 'Phone number must be in E.164 format (e.g., +18777804236)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds the name field for parent registration
  Widget _buildNameField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Your Name',
            prefixIcon: isDarkMode
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: ChorePalColors.darkBlueGradient,
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.all(8),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 20),
                  )
                : Icon(Icons.person, color: ChorePalColors.darkBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ChorePalColors.darkBlue, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds the email field
  Widget _buildEmailField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: isDarkMode
            ? Container(
                decoration: const BoxDecoration(
                  gradient: ChorePalColors.darkBlueGradient,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.all(8),
                child: const Icon(Icons.email, color: Colors.white, size: 20),
              )
            : Icon(Icons.email, color: ChorePalColors.darkBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color:
                isDarkMode ? ChorePalColors.darkBlue : ChorePalColors.darkBlue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  /// Builds the password field
  Widget _buildPasswordField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: isDarkMode
            ? Container(
                decoration: const BoxDecoration(
                  gradient: ChorePalColors.darkBlueGradient,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.all(8),
                child: const Icon(Icons.lock, color: Colors.white, size: 20),
              )
            : Icon(Icons.lock, color: ChorePalColors.darkBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color:
                isDarkMode ? ChorePalColors.darkBlue : ChorePalColors.darkBlue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (_isRegistering && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  /// Builds the error message display
  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the parent login/register button
  Widget _buildParentActionButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isDarkMode
          ? Container(
              decoration: BoxDecoration(
                gradient: ChorePalColors.darkBlueGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: ChorePalColors.darkBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleParentSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward),
                        ],
                      ),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ChorePalColors.darkBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              onPressed: _isLoading ? null : _handleParentSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isRegistering ? Icons.person_add : Icons.login),
                        const SizedBox(width: 8),
                        Text(
                          _isRegistering ? 'Create Account' : 'Login',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
    );
  }

  /// Builds the forgot password link
  Widget _buildForgotPasswordLink() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : _showPasswordResetDialog,
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color:
                isDarkMode ? ChorePalColors.darkBlue : ChorePalColors.darkBlue,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Shows password reset dialog
  void _showPasswordResetDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final resetEmailController = TextEditingController();
    bool isSendingReset = false;
    String? resetErrorMessage;
    String? resetSuccessMessage;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ChorePalColors.darkBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    color: ChorePalColors.darkBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Reset Password'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: resetEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'your.email@example.com',
                      prefixIcon:
                          Icon(Icons.email, color: ChorePalColors.darkBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: ChorePalColors.darkBlue, width: 2),
                      ),
                      filled: true,
                      fillColor:
                          isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isSendingReset,
                  ),
                  if (resetErrorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              resetErrorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (resetSuccessMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              resetSuccessMessage!,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSendingReset
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                      },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSendingReset
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(() {
                            resetErrorMessage =
                                'Please enter a valid email address';
                            resetSuccessMessage = null;
                          });
                          return;
                        }

                        setDialogState(() {
                          isSendingReset = true;
                          resetErrorMessage = null;
                          resetSuccessMessage = null;
                        });

                        try {
                          await _authService.sendPasswordResetEmail(email);
                          setDialogState(() {
                            resetSuccessMessage =
                                'Password reset email sent! Please check your inbox and follow the instructions.';
                            resetErrorMessage = null;
                            isSendingReset = false;
                          });

                          // Auto-close dialog after 3 seconds
                          Future.delayed(const Duration(seconds: 3), () {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          });
                        } catch (e) {
                          setDialogState(() {
                            resetErrorMessage =
                                e.toString().replaceAll('Exception: ', '');
                            resetSuccessMessage = null;
                            isSendingReset = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChorePalColors.darkBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSendingReset
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send Reset Link'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Dispose controller when dialog is closed
      resetEmailController.dispose();
    });
  }

  /// Builds the toggle button to switch between login and register
  Widget _buildToggleAuthModeButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextButton(
      onPressed: _isLoading ? null : _toggleParentAuthMode,
      child: ShaderMask(
        shaderCallback: (bounds) => isDarkMode
            ? ChorePalColors.darkBlueGradient.createShader(bounds)
            : ChorePalColors.primaryGradient.createShader(bounds),
        child: Text(
          _isRegistering
              ? 'Already have an account? Login'
              : 'Create a new account',
          style: TextStyle(
            color: isDarkMode ? Colors.white : ChorePalColors.lightBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Builds the child login form
  Widget _buildChildLoginForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _childFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Child Login',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF333333),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildChildNameField(),
                  const SizedBox(height: 16),
                  _buildFamilyCodeField(),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    _buildChildErrorMessage(),
                    const SizedBox(height: 16),
                  ],
                  _buildChildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Displays the error message in the child form
  Widget _buildChildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the child name field
  Widget _buildChildNameField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: _childNameController,
      decoration: InputDecoration(
        labelText: 'Your Name',
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey.shade300 : ChorePalColors.darkBlue,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: isDarkMode
            ? Container(
                decoration: const BoxDecoration(
                  gradient: ChorePalColors.darkBlueGradient,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.all(8),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              )
            : Icon(Icons.person, color: ChorePalColors.darkBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ChorePalColors.darkBlue, width: 2),
        ),
        hintText: 'Enter your name',
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  /// Builds the family code field
  Widget _buildFamilyCodeField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _familyCodeController,
          decoration: InputDecoration(
            labelText: 'Family Code',
            labelStyle: TextStyle(
              color: ChorePalColors.darkBlue,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: isDarkMode
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: ChorePalColors.darkBlueGradient,
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.all(8),
                    child: const Icon(Icons.numbers,
                        color: Colors.white, size: 20),
                  )
                : Icon(Icons.numbers, color: ChorePalColors.darkBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ChorePalColors.darkBlue, width: 2),
            ),
            hintText: 'Enter 6-digit code',
            helperText: 'Ask your parent for the 6-digit family code',
            counterText: '',
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 20,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your family code';
            }
            if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
              return 'Code must be 6 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Builds the child login button
  Widget _buildChildLoginButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isDarkMode
          ? Container(
              decoration: BoxDecoration(
                gradient: ChorePalColors.darkBlueGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: ChorePalColors.darkBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleChildLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Login',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ChorePalColors.darkBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              onPressed: _isLoading ? null : _handleChildLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.login),
                        SizedBox(width: 8),
                        Text(
                          'Join Family',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
    );
  }

  /// Toggles between parent login and registration modes
  void _toggleParentAuthMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = null;
    });
  }

  /// Handles parent login or registration submission
  Future<void> _handleParentSubmit() async {
    try {
      if (_parentFormKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        if (_isRegistering) {
          await _handleParentRegistration();
        } else {
          await _handleParentLogin();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handles parent registration
  Future<void> _handleParentRegistration() async {
    try {
      // Register new parent (automatically signs the user in)
      final credential = await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Verify user is authenticated (auto-login happens automatically with registration)
      if (credential.user == null) {
        throw Exception('Registration succeeded but user is not signed in');
      }

      // Create a new family
      final familyRef = await _firestoreService.createFamily(
        credential.user!.uid,
        'Family ${_nameController.text}',
      );

      // Get phone number if provided
      final phoneNumber = _phoneNumberController.text.trim().isNotEmpty
          ? _phoneNumberController.text.trim()
          : null;

      // Create user profile
      try {
        await _firestoreService.createParentProfile(
          credential.user!.uid,
          _nameController.text,
          _emailController.text,
          familyId: familyRef.id,
          phoneNumber: phoneNumber,
        );
      } catch (userProfileError) {
        // Don't navigate if user profile creation failed
        throw Exception(
            'Family was created, but user profile creation failed: ${userProfileError.toString().replaceAll('Exception: ', '')}');
      }

      // Wait for the user document to be readable in Firestore
      // This ensures the document has propagated before navigation
      bool documentExists = false;
      for (int attempt = 0; attempt < 10; attempt++) {
        final doc =
            await _firestoreService.users.doc(credential.user!.uid).get();
        if (doc.exists) {
          documentExists = true;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!documentExists) {
        // Document still not readable after retries, but continue anyway
        // AuthWrapper will handle retrying when it loads
      }

      // Verify auth state is set (user is automatically logged in after registration)
      // Firebase's createUserWithEmailAndPassword automatically signs the user in
      // Wait a moment for the auth state to fully propagate
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify the user is authenticated and the session is established
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != credential.user!.uid) {
        throw Exception(
            'User session not properly established after registration. Please try logging in manually.');
      }

      // Force a reload of the user to ensure auth state is fully synced
      // This helps ensure the session persists across app restarts
      await currentUser.reload();

      // User is now logged in and will stay logged in when they reopen the app
      // Navigate to dashboard with state initialization
      if (mounted) {
        await _initializeStateAndNavigateToParentDashboard(familyRef.id);
      }
    } catch (e) {
      rethrow; // Re-throw to be caught by the outer catch block
    }
  }

  /// Handles parent login
  Future<void> _handleParentLogin() async {
    // Login existing parent
    final credential = await _authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // Get user data
    final userDoc =
        await _firestoreService.users.doc(credential.user!.uid).get();
    if (!userDoc.exists) {
      throw Exception('User profile not found');
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    if (userData['isParent'] != true) {
      throw Exception('This account is not registered as a parent');
    }

    if (mounted) {
      await _initializeStateAndNavigateToParentDashboard(userData['familyId']);
    }
  }

  /// Initializes state providers and navigates to parent dashboard
  Future<void> _initializeStateAndNavigateToParentDashboard(
      String familyId) async {
    // Initialize data for state providers
    final choreState = Provider.of<ChoreState>(context, listen: false);
    choreState.setFamilyId(familyId);
    await choreState.loadChores();

    final rewardState = Provider.of<RewardState>(context, listen: false);
    rewardState.setFamilyId(familyId);
    await rewardState.loadRewards();

    // Set user context for notifications
    final userState = Provider.of<UserState>(context, listen: false);
    await userState.loadCurrentUser();
    if (userState.currentUser != null) {
      NotificationHelper.setCurrentUser(userState.currentUser);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const EnhancedParentDashboard()),
    );
  }

  /// Handles child login
  Future<void> _handleChildLogin() async {
    try {
      if (_childFormKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final childName = _childNameController.text.trim();
        final familyCode = _familyCodeController.text.trim();

        // Clean and validate the family code
        final cleanedCode = familyCode.trim().replaceAll(' ', '');
        if (cleanedCode.length != 6 ||
            !RegExp(r'^\d{6}$').hasMatch(cleanedCode)) {
          throw Exception('Invalid family code format. Please enter 6 digits');
        }

        // Find family by code
        final familySnapshot =
            await _firestoreService.findFamilyByCode(cleanedCode);
        if (familySnapshot.docs.isEmpty) {
          throw Exception('Invalid family code. Please check with your parent');
        }

        final familyDoc = familySnapshot.docs.first;
        final familyId = familyDoc.id;

        // First, check if a child with this name already exists in the family
        final existingChild = await _firestoreService.findChildByNameInFamily(
            childName, familyId);

        String childId;
        if (existingChild != null) {
          // Child already exists, use their existing ID
          childId = existingChild.id;
        } else {
          // Create a new child

          // Create a Firebase Auth account for the child
          // Use a unique email format for children with timestamp to ensure uniqueness
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final childEmail =
              '${familyId}_${childName}_$timestamp@chorepal.child';
          final childPassword = 'child_${familyId}_${childName}_$timestamp';

          UserCredential credential;
          try {
            // Try to sign in with existing credentials first
            credential = await _authService.signInWithEmailAndPassword(
                childEmail, childPassword);
          } catch (e) {
            // If sign in fails, create a new account
            credential = await _authService.registerWithEmailAndPassword(
                childEmail, childPassword);
          }

          // Use the Firebase Auth UID as the child ID
          childId = credential.user!.uid;

          // Create the child profile in Firestore
          await _firestoreService.createChildProfile(
              childId, childName, familyId);
          await _firestoreService.addChildToFamily(familyId, childId);
        }

        if (mounted) {
          final message = existingChild != null
              ? 'Welcome back, $childName!'
              : 'Welcome, $childName! You have joined your family.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );

          await _initializeStateAndNavigateToChildDashboard(familyId, childId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Initializes state providers and navigates to child dashboard
  Future<void> _initializeStateAndNavigateToChildDashboard(
      String familyId, String childId) async {
    // Initialize data for state providers
    final choreState = Provider.of<ChoreState>(context, listen: false);
    choreState.setFamilyId(familyId);
    await choreState.loadChores();

    final rewardState = Provider.of<RewardState>(context, listen: false);
    rewardState.setFamilyId(familyId);
    await rewardState.loadRewards();

    // Set user context for notifications
    final userState = Provider.of<UserState>(context, listen: false);
    await userState.loadCurrentUser();
    if (userState.currentUser != null) {
      NotificationHelper.setCurrentUser(userState.currentUser);
    }

    // Navigate to child dashboard
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EnhancedChildDashboard(childId: childId),
      ),
    );
  }
}
