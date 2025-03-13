import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore.dart';
import '../../models/chore_state.dart';
import '../../widgets/chore_card.dart';
import '../login_screen.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Code: ${generateFamilyCode()}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton(
                  onPressed: () {
                    // Implement add child functionality
                  },
                  child: const Text('Add Child'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ChoreState>(
              builder: (context, choreState, child) {
                if (choreState.chores.isEmpty) {
                  return const Center(
                    child: Text('No chores added yet. Click the + button to add a chore!'),
                  );
                }
                return ListView.builder(
                  itemCount: choreState.chores.length,
                  itemBuilder: (context, index) {
                    final chore = choreState.chores[index];
                    return ChoreCard(chore: chore);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddChoreDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String generateFamilyCode() {
    return 'FAM123';
  }

  void _showAddChoreDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final rewardController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Chore'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rewardController,
                decoration: const InputDecoration(labelText: 'Reward'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
                child: const Text('Select Deadline'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  rewardController.text.isNotEmpty) {
                Provider.of<ChoreState>(context, listen: false).addChore(
                  Chore(
                    id: DateTime.now().toString(), // Temporary ID solution
                    title: titleController.text,
                    description: descriptionController.text,
                    deadline: selectedDate,
                    reward: rewardController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}