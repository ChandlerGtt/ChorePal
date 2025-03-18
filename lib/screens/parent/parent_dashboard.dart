// lib/screens/parent/parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart'; // Import the RewardState
import '../../widgets/chore_card.dart';
import '../../widgets/reward_card.dart'; // Import the RewardCard
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  String familyCode = 'Loading...';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadFamilyCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyCode() async {
    if (_authService.currentUser != null) {
      final userDoc = await _firestoreService.users.doc(_authService.currentUser!.uid).get();
      if (!mounted) return; // Check mounted before using context
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final familyId = userData['familyId'];
      
      if (familyId != null) {
        final familyDoc = await _firestoreService.families.doc(familyId).get();
        if (!mounted) return; // Check mounted again
        
        final familyData = familyDoc.data() as Map<String, dynamic>;
        setState(() {
          familyCode = familyData['familyCode'] ?? 'FAM123'; // Default code if not set
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chores', icon: Icon(Icons.checklist)),
            Tab(text: 'Rewards', icon: Icon(Icons.card_giftcard)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChoresTab(),
          _buildRewardsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedTabIndex == 0) {
            _showAddChoreDialog(context);
          } else {
            // Navigate to add reward screen
            // You'll need to create this screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add Reward feature coming soon')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChoresTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Family Code: $familyCode',
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
              if (choreState.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (choreState.chores.isEmpty) {
                return const Center(
                  child: Text('No chores added yet. Click the + button to add a chore!'),
                );
              }
              return ListView.builder(
                itemCount: choreState.chores.length,
                itemBuilder: (context, index) {
                  final chore = choreState.chores[index];
                  return ChoreCard(
                    chore: chore,
                    onApprove: _handleApproveChore,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsTab() {
    // This needs to be wrapped with a Consumer for RewardState
    return Consumer<RewardState>(
      builder: (context, rewardState, child) {
        if (rewardState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (rewardState.rewards.isEmpty) {
          return const Center(
            child: Text('No rewards added yet. Click the + button to add a reward!'),
          );
        }
        
        final rewardsByTier = rewardState.rewardsByTier;
        final children = <Widget>[];
        
        if (rewardsByTier.containsKey('gold')) {
          children.add(
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Gold Tier Rewards', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            )
          );
          children.addAll(
            rewardsByTier['gold']!.map((reward) => RewardCard(reward: reward)).toList()
          );
        }
        
        if (rewardsByTier.containsKey('silver')) {
          children.add(
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Silver Tier Rewards', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            )
          );
          children.addAll(
            rewardsByTier['silver']!.map((reward) => RewardCard(reward: reward)).toList()
          );
        }
        
        if (rewardsByTier.containsKey('bronze')) {
          children.add(
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Bronze Tier Rewards', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
            )
          );
          children.addAll(
            rewardsByTier['bronze']!.map((reward) => RewardCard(reward: reward)).toList()
          );
        }
        
        return ListView(children: children);
      },
    );
  }

  Future<void> _handleApproveChore(String choreId, String childId, int points) async {
    // Award points to the child
    await _firestoreService.awardPointsForChore(childId, points);
    
    // Mark chore as approved
    await _firestoreService.updateChoreStatus(choreId, true);
  }

  void _showAddChoreDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final rewardController = TextEditingController();
    String selectedPriority = 'medium';
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
                decoration: const InputDecoration(labelText: 'Reward Points'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Priority'),
                value: selectedPriority,
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('High Priority')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                  DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedPriority = value;
                  }
                },
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
                child: Text('Select Deadline: ${selectedDate.toString().split(' ')[0]}'),
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
                    id: DateTime.now().toString(), // This ID will be replaced by Firestore
                    title: titleController.text,
                    description: descriptionController.text,
                    deadline: selectedDate,
                    reward: rewardController.text,
                    priority: selectedPriority,
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