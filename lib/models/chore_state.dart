import 'package:flutter/foundation.dart';
import 'chore.dart';

class ChoreState extends ChangeNotifier {
  final List<Chore> _chores = [];

  List<Chore> get chores => _chores;

  void addChore(Chore chore) {
    _chores.add(chore);
    notifyListeners();
  }

  void toggleChoreCompletion(String id) {
    final choreIndex = _chores.indexWhere((chore) => chore.id == id);
    if (choreIndex != -1) {
      _chores[choreIndex].isCompleted = !_chores[choreIndex].isCompleted;
      notifyListeners();
    }
  }
}