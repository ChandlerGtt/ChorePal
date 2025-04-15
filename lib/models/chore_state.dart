// lib/models/chore_state.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chore.dart';
import 'user.dart';

class ChoreState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Chore> _chores = [];
  List<Chore> _pendingChores = [];
  List<Chore> _pendingApprovalChores = [];
  List<Chore> _completedChores = [];
  String? _familyId;
  bool _isLoading = false;

  List<Chore> get chores => _chores;
  List<Chore> get pendingChores => _pendingChores;
  List<Chore> get pendingApprovalChores => _pendingApprovalChores;
  List<Chore> get completedChores => _completedChores;
  bool get isLoading => _isLoading;
  
  void setFamilyId(String familyId) {
    _familyId = familyId;
  }

  Future<void> loadChores() async {
    if (_familyId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestoreService.getChoresForFamily(_familyId!);
      
      _chores = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Chore.fromFirestore(doc.id, data);
      }).toList();
      
      // Separate chores into different categories
      _pendingChores = _chores.where((chore) => 
        !chore.isCompleted && !chore.isPendingApproval).toList();
      
      _pendingApprovalChores = _chores.where((chore) => 
        !chore.isCompleted && chore.isPendingApproval).toList();
      
      _completedChores = _chores.where((chore) => 
        chore.isCompleted).toList();
      
      // Sort pending chores by priority (high, medium, low) then by deadline
      _pendingChores.sort((a, b) {
        // First compare priority
        final priorityComparison = _getPriorityValue(a.priority).compareTo(_getPriorityValue(b.priority));
        if (priorityComparison != 0) return priorityComparison;
        
        // If priority is the same, compare deadline
        return a.deadline.compareTo(b.deadline);
      });
      
      // Also sort pending approval chores
      _pendingApprovalChores.sort((a, b) {
        return a.completedAt?.compareTo(b.completedAt ?? DateTime.now()) ?? 0;
      });
    } catch (e) {
      print('Error loading chores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to convert priority strings to numeric values for sorting
  int _getPriorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return 0;
      case 'medium': return 1;
      case 'low': return 2;
      default: return 1;
    }
  }

  Future<void> addChore(Chore chore) async {
    if (_familyId == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.addChore(chore, _familyId!);
      await loadChores(); // Reload the chores
    } catch (e) {
      print('Error adding chore: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a chore as pending approval when a child completes it
  Future<void> markChoreAsPendingApproval(String choreId, String childId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Find the chore
      final chore = _chores.firstWhere((c) => c.id == choreId);
      
      // Create updated chore
      final updatedChore = chore.copyWith(
        isPendingApproval: true,
        completedBy: childId,
        completedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await _firestoreService.chores.doc(choreId).update(
        updatedChore.toFirestore()
      );
      
      await loadChores(); // Reload the chores
    } catch (e) {
      print('Error marking chore as pending approval: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Approve a completed chore (parent only)
  Future<void> approveChore(String choreId, String childId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Find the chore
      final chore = _chores.firstWhere((c) => c.id == choreId);
      
      // Create updated chore
      final updatedChore = chore.copyWith(
        isCompleted: true,
        isPendingApproval: false,
      );
      
      // Update in Firestore
      await _firestoreService.chores.doc(choreId).update(
        updatedChore.toFirestore()
      );
      
      // Award points to the child
      await _firestoreService.awardPointsToChild(childId, chore.pointValue);
      
      await loadChores(); // Reload the chores
    } catch (e) {
      print('Error approving chore: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // The old completeChore method is kept for backward compatibility
  Future<void> completeChore(String choreId, String childId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.completeChore(choreId, childId);
      await loadChores(); // Reload the chores
    } catch (e) {
      print('Error completing chore: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Get chores for a specific child
  Future<List<Chore>> getChoresForChild(String childId) async {
    if (_familyId == null) return [];
    
    try {
      return await _firestoreService.getChoresForChild(childId, _familyId!);
    } catch (e) {
      print('Error getting chores for child: $e');
      return [];
    }
  }
  
  // Get all chores that don't have any children assigned
  List<Chore> getUnassignedChores() {
    return _pendingChores.where((chore) => chore.assignedTo.isEmpty).toList();
  }
  
  // Assign a chore to a specific child
  Future<void> assignChoreToChild(String choreId, String childId) async {
    final choreIndex = _chores.indexWhere((chore) => chore.id == choreId);
    if (choreIndex == -1) return;
    
    final chore = _chores[choreIndex];
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Create a new list with the child added
      List<String> newAssignedTo = List.from(chore.assignedTo);
      if (!newAssignedTo.contains(childId)) {
        newAssignedTo.add(childId);
      }
      
      // Update the chore in Firestore
      await _firestoreService.chores.doc(choreId).update({
        'assignedTo': newAssignedTo
      });
      
      await loadChores(); // Reload the chores
    } catch (e) {
      print('Error assigning chore: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Remove a child from a chore's assignment
  Future<void> unassignChoreFromChild(String choreId, String childId) async {
    final choreIndex = _chores.indexWhere((chore) => chore.id == choreId);
    if (choreIndex == -1) return;
    
    final chore = _chores[choreIndex];
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Create a new list with the child removed
      List<String> newAssignedTo = List.from(chore.assignedTo);
      newAssignedTo.remove(childId);
      
      // Update the chore in Firestore
      await _firestoreService.chores.doc(choreId).update({
        'assignedTo': newAssignedTo
      });
      
      await loadChores(); // Reload the chores
    } catch (e) {
      print('Error unassigning chore: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update an existing chore with new data
  Future<void> updateChore(Chore updatedChore) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Update the chore in Firestore
      await _firestoreService.chores.doc(updatedChore.id).update(
        updatedChore.toFirestore()
      );
      
      await loadChores(); // Reload the chores
    } catch (e) {
      print('Error updating chore: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}