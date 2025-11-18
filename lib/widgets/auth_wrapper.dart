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

      // First, check the authenticated user's document to determine if they're a parent
      // This prevents stale child data from redirecting parents to child dashboard
      final prefs = await SharedPreferences.getInstance();
      final storedChildId = prefs.getString('child_user_id');
      final storedFamilyId = prefs.getString('child_family_id');

      DocumentSnapshot? userDoc;
      String? actualUserId;
      String? familyId;

      // Always check the auth UID's document first to determine user type
      // This is critical to prevent parent logins from being misrouted
      const maxRetries = 10;
      const retryDelay = Duration(milliseconds: 500);

      for (int attempt = 0; attempt < maxRetries; attempt++) {
        userDoc = await _firestoreService.users.doc(user.uid).get();

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
        final finalDoc = await _firestoreService.users.doc(user.uid).get();

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

      // Get user data from the auth UID's document
      final authUserData = userDoc.data() as Map<String, dynamic>;
      final isParentFromAuth = authUserData['isParent'] ?? false;

      // If the authenticated user is a parent, clear any stale child data and use parent account
      if (isParentFromAuth) {
        // Clear any stored child data (stale from previous child login)
        if (storedChildId != null || storedFamilyId != null) {
          await prefs.remove('child_user_id');
          await prefs.remove('child_family_id');
        }
        
        // Use parent auth UID
        actualUserId = user.uid;
        familyId = authUserData['familyId'] as String? ?? '';
        userDoc = userDoc; // Already loaded above
      } else {
        // This is a child user - check if we have stored child data
        if (storedChildId != null && storedFamilyId != null) {
          // Use the stored child ID (child uses anonymous auth, so auth UID != child document ID)
          actualUserId = storedChildId;
          familyId = storedFamilyId;
          
          // Get child document from Firestore
          for (int attempt = 0; attempt < maxRetries; attempt++) {
            userDoc = await _firestoreService.users.doc(actualUserId).get();

            if (userDoc.exists) {
              break; // Document found, exit retry loop
            }

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
          // No stored child data but auth user is not a parent - this shouldn't happen
          await _authService.signOut();
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final isParent = userData['isParent'] ?? false;
      final finalFamilyId = familyId ?? (userData['familyId'] as String? ?? '');
      final finalUserId = actualUserId!;

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
