import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore.dart';
import '../../models/chore_state.dart';
import '../../models/user_state.dart';
import '../../models/user.dart';

class AssignChoreScreen extends StatefulWidget {
  final Chore chore;

  const AssignChoreScreen({
    Key? key,
    required this.chore,
  }) : super(key: key);

  @override
  State<AssignChoreScreen> createState() => _AssignChoreScreenState();
}

class _AssignChoreScreenState extends State<AssignChoreScreen> {
  final Map<String, bool> _selectedChildren = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
    });

    // Initialize the selection based on the chore's already assigned children
    final userState = Provider.of<UserState>(context, listen: false);
    await userState.loadFamilyData();

    for (final child in userState.childrenInFamily) {
      _selectedChildren[child.id] = widget.chore.assignedTo.contains(child.id);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Chore'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveAssignments,
          child: const Text('Save Assignments'),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (userState.childrenInFamily.isEmpty) {
          return const Center(
            child: Text('No children in family yet. Add children first.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chore.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(widget.chore.description),
                  const SizedBox(height: 8),
                  Text(
                    'Points: ${widget.chore.pointValue} • Due: ${widget.chore.deadline.toString().split(' ')[0]}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Assign to:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: userState.childrenInFamily.length,
                itemBuilder: (context, index) {
                  final child = userState.childrenInFamily[index];
                  return CheckboxListTile(
                    title: Text(child.name),
                    subtitle: Text('Points: ${child.points}'),
                    value: _selectedChildren[child.id] ?? false,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          _selectedChildren[child.id] = value;
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveAssignments() {
    final selectedChildIds = _selectedChildren.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Create an updated chore with the new assignments
    final updatedChore = widget.chore.copyWith(
      assignedTo: selectedChildIds,
    );

    // Update the chore in the state
    Provider.of<ChoreState>(context, listen: false).updateChore(updatedChore);

    Navigator.of(context).pop();
  }
}
