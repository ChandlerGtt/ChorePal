// lib/screens/parent/add_reward_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reward.dart';
import '../../models/reward_state.dart';

class AddRewardScreen extends StatefulWidget {
  const AddRewardScreen({super.key});

  @override
  State<AddRewardScreen> createState() => _AddRewardScreenState();
}

class _AddRewardScreenState extends State<AddRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  String _selectedTier = 'bronze';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Reward'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Reward Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Points Required',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter points required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Reward Tier',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedTier,
                items: const [
                  DropdownMenuItem(value: 'bronze', child: Text('Bronze Tier')),
                  DropdownMenuItem(value: 'silver', child: Text('Silver Tier')),
                  DropdownMenuItem(value: 'gold', child: Text('Gold Tier')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTier = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveReward,
                child: const Text('Save Reward'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _saveReward() {
    if (_formKey.currentState!.validate()) {
      final reward = Reward(
        id: DateTime.now().toString(), // Will be replaced by Firestore
        title: _titleController.text,
        description: _descriptionController.text,
        pointsRequired: int.parse(_pointsController.text),
        tier: _selectedTier,
      );
      
      Provider.of<RewardState>(context, listen: false).addReward(reward);
      Navigator.pop(context);
    }
  }
}