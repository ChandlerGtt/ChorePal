// lib/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/chore_state.dart';
import '../models/reward_state.dart';
import '../screens/login_screen.dart';
import '../screens/parent/enhanced_parent_dashboard.dart';
import '../screens/child/enhanced_child_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final user = _authService.currentUser;

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get user data from Firestore
      final userDoc = await _firestoreService.users.doc(user.uid).get();

      if (!userDoc.exists) {
        // User exists in Firebase Auth but not in Firestore
        // This shouldn't happen, but handle gracefully
        await _authService.signOut();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final isParent = userData['isParent'] ?? false;
      final familyId = userData['familyId'] ?? '';

      if (isParent) {
        await _initializeParentDashboard(familyId);
      } else {
        // This is a child user - use the Firebase Auth UID as the child ID
        await _initializeChildDashboard(familyId, user.uid);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeParentDashboard(String familyId) async {
    try {
      // Initialize state providers
      final choreState = Provider.of<ChoreState>(context, listen: false);
      choreState.setFamilyId(familyId);
      await choreState.loadChores();

      final rewardState = Provider.of<RewardState>(context, listen: false);
      rewardState.setFamilyId(familyId);
      await rewardState.loadRewards();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const EnhancedParentDashboard(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing parent dashboard: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeChildDashboard(
      String familyId, String childId) async {
    try {
      // Initialize state providers
      final choreState = Provider.of<ChoreState>(context, listen: false);
      choreState.setFamilyId(familyId);
      await choreState.loadChores();

      final rewardState = Provider.of<RewardState>(context, listen: false);
      rewardState.setFamilyId(familyId);
      await rewardState.loadRewards();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EnhancedChildDashboard(childId: childId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing child dashboard: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your ChorePal...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _authService.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Sign Out and Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // If we get here, user is not authenticated
    return const LoginScreen();
  }
}
