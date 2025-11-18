// lib/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/chore_state.dart';
import '../models/reward_state.dart';
import '../models/user.dart';
import '../widgets/notification_helper.dart';
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
  Widget? _targetWidget; // Widget to display after initialization

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

      // Check if this is a child user (anonymous auth with stored child ID)
      final prefs = await SharedPreferences.getInstance();
      final storedChildId = prefs.getString('child_user_id');
      final storedFamilyId = prefs.getString('child_family_id');

      DocumentSnapshot? userDoc;
      String? actualUserId;
      String? familyId;

      if (storedChildId != null && storedFamilyId != null) {
        // This is a child user - use the stored child ID instead of auth UID
        actualUserId = storedChildId;
        familyId = storedFamilyId;
        
        // Get user data from Firestore using the stored child ID
        const maxRetries = 10;
        const retryDelay = Duration(milliseconds: 500);

        for (int attempt = 0; attempt < maxRetries; attempt++) {
          userDoc = await _firestoreService.users.doc(actualUserId).get();

          if (userDoc.exists) {
            break; // Document found, exit retry loop
          }

          // If this is not the last attempt, wait before retrying
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelay);
          }
        }

        if (userDoc == null || !userDoc.exists) {
          // Child document not found - clear stored data and sign out
          await prefs.remove('child_user_id');
          await prefs.remove('child_family_id');
          await _authService.signOut();
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else {
        // This is a parent user - use the auth UID directly
        actualUserId = user.uid;
        
        // Get user data from Firestore with retry logic
        const maxRetries = 10;
        const retryDelay = Duration(milliseconds: 500);

        for (int attempt = 0; attempt < maxRetries; attempt++) {
          userDoc = await _firestoreService.users.doc(actualUserId).get();

          if (userDoc.exists) {
            break; // Document found, exit retry loop
          }

          // If this is not the last attempt, wait before retrying
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelay);
          }
        }

        if (userDoc == null || !userDoc.exists) {
          // User exists in Firebase Auth but not in Firestore after retries
          // Wait a bit longer and try one more time before signing out
          await Future.delayed(const Duration(seconds: 2));
          final finalDoc = await _firestoreService.users.doc(actualUserId).get();

          if (!finalDoc.exists) {
            // Still doesn't exist after extended wait - sign out
            await _authService.signOut();
            setState(() {
              _isLoading = false;
            });
            return;
          }
          userDoc = finalDoc;
        }
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final isParent = userData['isParent'] ?? false;
      final finalFamilyId = familyId ?? (userData['familyId'] as String? ?? '');
      // actualUserId is guaranteed to be non-null here (set in both branches above)
      final finalUserId = actualUserId;

      // Verify: If we have stored child data but the user is actually a parent, clear child data
      if (storedChildId != null && storedFamilyId != null && isParent) {
        // Stale child data - clear it and use parent auth UID
        await prefs.remove('child_user_id');
        await prefs.remove('child_family_id');
        // Reload with parent auth UID
        final parentDoc = await _firestoreService.users.doc(user.uid).get();
        if (parentDoc.exists) {
          final parentData = parentDoc.data() as Map<String, dynamic>;
          final currentUser = User.fromFirestore(user.uid, parentData);
          NotificationHelper.setCurrentUser(currentUser);
          await _initializeParentDashboard(parentData['familyId'] ?? '');
          return;
        }
      }

      // Verify: If we're using parent auth but have child data stored, clear it
      if (storedChildId == null && storedFamilyId == null && !isParent) {
        // This shouldn't happen, but if it does, sign out
        await _authService.signOut();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Set user context for notifications
      final currentUser = User.fromFirestore(finalUserId, userData);
      NotificationHelper.setCurrentUser(currentUser);

      if (isParent) {
        await _initializeParentDashboard(finalFamilyId);
      } else {
        // This is a child user - use the actual child ID (from Firestore document)
        await _initializeChildDashboard(finalFamilyId, finalUserId);
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
        setState(() {
          _targetWidget = const EnhancedParentDashboard();
          _isLoading = false;
        });
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
        setState(() {
          _targetWidget = EnhancedChildDashboard(childId: childId);
          _isLoading = false;
        });
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
                  // No navigation needed - StreamBuilder will handle it
                },
                child: const Text('Sign Out and Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Return the target widget if we have one (dashboard)
    if (_targetWidget != null) {
      return _targetWidget!;
    }

    // If we get here, user is not authenticated
    return const LoginScreen();
  }
}