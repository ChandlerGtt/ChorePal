import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore_state.dart';
import '../../widgets/chore_card.dart';
import '../login_screen.dart';

class ChildDashboard extends StatelessWidget {
  const ChildDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chores'),
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
      body: Consumer<ChoreState>(
        builder: (context, choreState, child) {
          if (choreState.chores.isEmpty) {
            return const Center(
              child: Text('No chores assigned yet!'),
            );
          }
          return ListView.builder(
            itemCount: choreState.chores.length,
            itemBuilder: (context, index) {
              final chore = choreState.chores[index];
              return ChoreCard(
                chore: chore,
                isChild: true,
              );
            },
          );
        },
      ),
    );
  }
}