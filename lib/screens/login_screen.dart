// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/chore_state.dart';
import '../models/reward_state.dart';
import '../models/user_state.dart';
import 'parent/parent_dashboard.dart';
import 'child/child_dashboard.dart';

/// Login screen for the ChorePal app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
  
  // Child login fields
  final _childNameController = TextEditingController();
  final _familyCodeController = TextEditingController();
  
  // Services
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Theme colors
  final Color _primaryColor = const Color(0xFF4CAF50); // Green
  final Color _accentColor = const Color(0xFF2196F3); // Blue
  final Color _backgroundColor = const Color(0xFFF5F5F5); // Light gray
  final Color _textColor = const Color(0xFF333333); // Dark gray

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
    _childNameController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
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
    );
  }

  /// Builds the app header with logo and title
  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.check_circle_outline,
          size: 70,
          color: _primaryColor,
        ),
        const SizedBox(height: 10),
        Text(
          'ChorePal',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Helping families manage chores together',
          style: TextStyle(
            fontSize: 16,
            color: _textColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  /// Builds the tab selector
  Widget _buildTabSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(25),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: _textColor,
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _parentFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRegistering ? 'Create Parent Account' : 'Parent Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (_isRegistering) 
                    _buildNameField(),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  if (_errorMessage != null)
                    _buildErrorMessage(),
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

  /// Builds the name field for parent registration
  Widget _buildNameField() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Your Name',
            prefixIcon: Icon(Icons.person, color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 2),
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
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
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
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      obscureText: true,
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  /// Builds the toggle button to switch between login and register
  Widget _buildToggleAuthModeButton() {
    return TextButton(
      onPressed: _isLoading ? null : _toggleParentAuthMode,
      child: Text(
        _isRegistering
            ? 'Already have an account? Login'
            : 'Create a new account',
        style: TextStyle(color: _accentColor),
      ),
    );
  }

  /// Builds the child login form
  Widget _buildChildLoginForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _childFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Child Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
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
    return TextFormField(
      controller: _childNameController,
      decoration: InputDecoration(
        labelText: 'Your Name',
        labelStyle: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(Icons.person, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        hintText: 'Enter your name',
        filled: true,
        fillColor: Colors.white,
      ),
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        fontSize: 16,
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _familyCodeController,
          decoration: InputDecoration(
            labelText: 'Family Code',
            labelStyle: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(Icons.numbers, color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            hintText: 'Enter 6-digit code',
            helperText: 'Ask your parent for the 6-digit family code',
            counterText: '',
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
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
    // Register new parent
    final credential = await _authService.registerWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    
    // Create a new family
    final familyRef = await _firestoreService.createFamily(
      credential.user!.uid,
      'Family ${_nameController.text}',
    );
    
    // Create user profile
    await _firestoreService.createParentProfile(
      credential.user!.uid,
      _nameController.text,
      _emailController.text,
      familyId: familyRef.id,
    );
    
    if (mounted) {
      await _initializeStateAndNavigateToParentDashboard(familyRef.id);
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
    final userDoc = await _firestoreService.users.doc(credential.user!.uid).get();
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
  Future<void> _initializeStateAndNavigateToParentDashboard(String familyId) async {
    // Initialize data for state providers
    final choreState = Provider.of<ChoreState>(context, listen: false);
    choreState.setFamilyId(familyId);
    await choreState.loadChores();
    
    final rewardState = Provider.of<RewardState>(context, listen: false);
    rewardState.setFamilyId(familyId);
    await rewardState.loadRewards();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ParentDashboard()),
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
        
        // Use the UserState provider to find or create the child
        final userState = Provider.of<UserState>(context, listen: false);
        
        try {
          final child = await userState.findOrCreateChild(childName, familyCode);
          
          if (child == null) {
            throw Exception('Failed to join family. Please try again');
          }
          
          // Set family ID for the state providers
          final familyId = child.familyId;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome, ${child.name}! You have ${child.points} points.'),
                backgroundColor: Colors.green,
              ),
            );
            
            await _initializeStateAndNavigateToChildDashboard(familyId, child.id);
          }
        } catch (e) {
          // Handle specific errors for family code and display appropriate messages
          String errorMessage = e.toString().replaceAll('Exception: ', '');
          setState(() {
            _errorMessage = errorMessage;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
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
  Future<void> _initializeStateAndNavigateToChildDashboard(String familyId, String childId) async {
    // Initialize data for state providers
    final choreState = Provider.of<ChoreState>(context, listen: false);
    choreState.setFamilyId(familyId);
    await choreState.loadChores();
    
    final rewardState = Provider.of<RewardState>(context, listen: false);
    rewardState.setFamilyId(familyId);
    await rewardState.loadRewards();
    
    // Navigate to child dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChildDashboard(childId: childId),
      ),
    );
  }
}