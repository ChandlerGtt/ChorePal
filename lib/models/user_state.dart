import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'user.dart';

class UserState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _currentUser;
  List<Child> _childrenInFamily = [];
  bool _isLoading = false;
  String? _familyId;
  String? _familyCode;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  List<Child> get childrenInFamily => _childrenInFamily;
  bool get isLoading => _isLoading;
  String? get familyId => _familyId;
  String? get familyCode => _familyCode;
  String? get errorMessage => _errorMessage;
  bool get isParent => _currentUser != null && _currentUser!.isParent;

  /// Clears any error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load the current user from Firebase Auth
  Future<void> loadCurrentUser() async {
    if (_authService.currentUser == null) {
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = _authService.currentUser!.uid;
      final userDoc = await _firestoreService.users.doc(uid).get();

      if (!userDoc.exists) {
        _currentUser = null;
        return;
      }

      _currentUser =
          User.fromFirestore(uid, userDoc.data() as Map<String, dynamic>);
      _familyId = _currentUser!.familyId;

      if (_familyId != null && _familyId!.isNotEmpty) {
        await loadFamilyData();
      }
    } catch (e) {
      _errorMessage = 'Failed to load your profile. Please try again.';
      print('Error loading current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load specific child user
  Future<Child?> loadChildUser(String childId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userDoc = await _firestoreService.users.doc(childId).get();

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      if (userData['isParent'] == true) {
        return null;
      }

      return Child.fromFirestore(childId, userData);
    } catch (e) {
      print('Error loading child user: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if a child with given ID exists
  Future<bool> doesChildExist(String childId) async {
    try {
      final doc = await _firestoreService.users.doc(childId).get();
      return doc.exists &&
          (doc.data() as Map<String, dynamic>)['isParent'] == false;
    } catch (e) {
      print('Error checking if child exists: $e');
      return false;
    }
  }

  // Find or create a child from name and family code
  Future<Child?> findOrCreateChild(String name, String familyCode) async {
    try {
      _isLoading = true;
      notifyListeners();

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
      final existingChild =
          await _firestoreService.findChildByNameInFamily(name, familyId);

      if (existingChild != null) {
        // Child already exists, return the existing child
        return existingChild;
      } else {
        // Create a new child with a unique ID
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final childId = '${familyId}_${name}_$timestamp';

        // Create the child profile
        await _firestoreService.createChildProfile(childId, name, familyId);
        await _firestoreService.addChildToFamily(familyId, childId);

        // Load and return the child
        return await loadChildUser(childId);
      }
    } catch (e) {
      print('Error finding or creating child: $e');
      rethrow; // Rethrow to show the proper error message
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load family data
  Future<void> loadFamilyData() async {
    if (_familyId == null || _familyId!.isEmpty) return;

    try {
      final familyDoc = await _firestoreService.families.doc(_familyId!).get();

      if (!familyDoc.exists) {
        _familyCode = null;
        _childrenInFamily = [];
        return;
      }

      final familyData = familyDoc.data() as Map<String, dynamic>;
      _familyCode = familyData['familyCode'];

      // Load children in the family
      _childrenInFamily =
          await _firestoreService.getChildrenInFamily(_familyId!);
    } catch (e) {
      print('Error loading family data: $e');
    }
  }

  // Create a parent user
  Future<User?> createParentUser(
      String uid, String name, String email, String familyName) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create a new family
      final familyRef = await _firestoreService.createFamily(uid, familyName);

      // Create parent profile
      await _firestoreService.createParentProfile(
        uid,
        name,
        email,
        familyId: familyRef.id,
      );

      _familyId = familyRef.id;

      // Get the created user
      final userDoc = await _firestoreService.users.doc(uid).get();
      _currentUser =
          User.fromFirestore(uid, userDoc.data() as Map<String, dynamic>);

      await loadFamilyData();
      return _currentUser;
    } catch (e) {
      print('Error creating parent user: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a child from the family by ID
  Child? getChildById(String childId) {
    try {
      return _childrenInFamily.firstWhere(
        (child) => child.id == childId,
      );
    } catch (e) {
      // Not found
      return null;
    }
  }

  // Create a child user
  Future<Child?> createChildUser(String name, String familyCode) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Find family by code
      final familySnapshot =
          await _firestoreService.findFamilyByCode(familyCode);

      if (familySnapshot.docs.isEmpty) {
        throw Exception('Invalid family code');
      }

      final familyDoc = familySnapshot.docs.first;
      final familyId = familyDoc.id;

      // Generate a virtual ID for the child
      final childId = '${familyId}_${name.hashCode}';

      // Check if child profile exists
      final childDocRef = _firestoreService.users.doc(childId);
      final childDoc = await childDocRef.get();

      if (!childDoc.exists) {
        // Create child profile
        await _firestoreService.createChildProfile(childId, name, familyId);

        // Add child to family
        await _firestoreService.addChildToFamily(familyId, childId);
      }

      // Get the created child
      final updatedChildDoc = await _firestoreService.users.doc(childId).get();
      return Child.fromFirestore(
          childId, updatedChildDoc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error creating child user: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove a child from the family
  Future<void> removeChildFromFamily(String childId) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_familyId == null) {
        throw Exception('Family ID not set');
      }

      await _firestoreService.removeChildFromFamily(_familyId!, childId);

      // Reload family data to update the children list
      await loadFamilyData();

      print('Successfully removed child $childId from family');
    } catch (e) {
      print('Error removing child from family: $e');
      _errorMessage = 'Failed to remove child. Please try again.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _familyId = null;
      _familyCode = null;
      _childrenInFamily = [];
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
