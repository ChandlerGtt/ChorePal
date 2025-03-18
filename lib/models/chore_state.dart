// lib/models/chore_state.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chore.dart';

class ChoreState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Chore> _chores = [];
  String? _familyId;
  bool _isLoading = false;

  List<Chore> get chores => _chores;
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
        return Chore(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          deadline: data['deadline'] != null 
              ? (data['deadline'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(days: 1)),
          isCompleted: data['isCompleted'] ?? false,
          reward: data['reward']?.toString() ?? '0',
          priority: data['priority'] ?? 'medium',
        );
      }).toList();
      
      // Sort by priority (high, medium, low) then by deadline
      _chores.sort((a, b) {
        // First compare priority
        final priorityComparison = _getPriorityValue(a.priority).compareTo(_getPriorityValue(b.priority));
        if (priorityComparison != 0) return priorityComparison;
        
        // If priority is the same, compare deadline
        return a.deadline.compareTo(b.deadline);
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

  Future<void> toggleChoreCompletion(String id) async {
    final choreIndex = _chores.indexWhere((chore) => chore.id == id);
    if (choreIndex != -1) {
      try {
        final newStatus = !_chores[choreIndex].isCompleted;
        await _firestoreService.updateChoreStatus(id, newStatus);
        await loadChores(); // Reload the chores
      } catch (e) {
        print('Error toggling chore completion: $e');
      }
    }
  }
}