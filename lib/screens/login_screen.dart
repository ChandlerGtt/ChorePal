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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _parentFormKey = GlobalKey<FormState>();
  final _childFormKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Parent login fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegistering = false;
  
  // Child login fields
  final _childNameController = TextEditingController();
  final _familyCodeController = TextEditingController();
  
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 50),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: _textColor,
                tabs: const [
                  Tab(text: 'Parent'),
                  Tab(text: 'Child'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
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
                  if (_isRegistering) ...[
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
                  TextFormField(
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
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
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _handleParentSubmit,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            _isRegistering ? 'Register' : 'Login',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleParentAuthMode,
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Login'
                          : 'Create a new account',
                      style: TextStyle(color: _accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                  TextFormField(
                    controller: _childNameController,
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
                  TextFormField(
                    controller: _familyCodeController,
                    decoration: InputDecoration(
                      labelText: 'Family Code',
                      prefixIcon: Icon(Icons.home, color: _primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _primaryColor, width: 2),
                      ),
                      hintText: 'Example: FAM-1234',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your family code';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _handleChildLogin,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ask your parent for the family code',
                    style: TextStyle(color: _textColor.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleParentAuthMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = null;
    });
  }

  Future<void> _handleParentSubmit() async {
    try {
      if (_parentFormKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        if (_isRegistering) {
          // Register new parent
          final credential = await _authService.registerWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          
          // Create a new family (use test family for debugging)
          final createTestFamily = _emailController.text.trim().contains('test');
          final familyRef = createTestFamily
              ? await _firestoreService.createTestFamily(
                  credential.user!.uid,
                  'Test Family ${_nameController.text}',
                )
              : await _firestoreService.createFamily(
                  credential.user!.uid,
                  'Family ${_nameController.text}',
                );
          
          // Show family code for testing
          if (createTestFamily) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Created test family with code: TEST-1234')),
            );
          }
          
          // Create user profile
          await _firestoreService.createParentProfile(
            credential.user!.uid,
            _nameController.text,
            _emailController.text,
            familyId: familyRef.id,
          );
          
          if (mounted) {
            // Initialize data for state providers
            final choreState = Provider.of<ChoreState>(context, listen: false);
            choreState.setFamilyId(familyRef.id);
            await choreState.loadChores();
            
            final rewardState = Provider.of<RewardState>(context, listen: false);
            rewardState.setFamilyId(familyRef.id);
            await rewardState.loadRewards();
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ParentDashboard()),
            );
          }
        } else {
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
            // Initialize data for state providers
            final choreState = Provider.of<ChoreState>(context, listen: false);
            choreState.setFamilyId(userData['familyId']);
            await choreState.loadChores();
            
            final rewardState = Provider.of<RewardState>(context, listen: false);
            rewardState.setFamilyId(userData['familyId']);
            await rewardState.loadRewards();
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ParentDashboard()),
            );
          }
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
        final child = await userState.findOrCreateChild(childName, familyCode);
        
        if (child == null) {
          throw Exception('Failed to find or create child profile');
        }
        
        // Set family ID for the state providers
        final familyId = child.familyId;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, ${child.name}! You have ${child.points} points.')),
          );
          
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
              builder: (context) => ChildDashboard(childId: child.id),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}