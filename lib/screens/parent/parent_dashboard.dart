// lib/screens/parent/parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart'; // Import the RewardState
import '../../models/user_state.dart'; // Import the UserState
import '../../widgets/chore_card.dart';
import '../../widgets/reward_card.dart'; // Import the RewardCard
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import '../../models/reward.dart';
import 'add_reward_screen.dart'; // Import the AddRewardScreen
import 'assign_chore_screen.dart'; // Import the AssignChoreScreen
import '../reward_history_screen.dart';
import '../../models/milestone.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  String familyCode = 'Loading...';

  @override
  void initState() {
    super.initState();
    this._tabController = TabController(length: 4, vsync: this);
    this._tabController.addListener(() {});
    _loadFamilyCode();
  }

  Future<void> _loadFamilyCode() async {
    if (_authService.currentUser != null) {
      final userDoc = await _firestoreService.users
          .doc(_authService.currentUser!.uid)
          .get();
      if (!mounted) return; // Check mounted before using context

      final userData = userDoc.data() as Map<String, dynamic>;
      final familyId = userData['familyId'];

      if (familyId != null) {
        final familyDoc = await _firestoreService.families.doc(familyId).get();
        if (!mounted) return; // Check mounted again

        final familyData = familyDoc.data() as Map<String, dynamic>;
        setState(() {
          familyCode =
              familyData['familyCode'] ?? 'FAM123'; // Default code if not set
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        return DefaultTabController(
          length: 4, // Increased from 3 to 4 tabs
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Parent Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Reward History',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RewardHistoryScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
              bottom: TabBar(
                controller: this._tabController,
                tabs: [
                  Tab(text: 'Chores', icon: Icon(Icons.checklist)),
                  Tab(text: 'Rewards', icon: Icon(Icons.card_giftcard)),
                  Tab(text: 'Children', icon: Icon(Icons.people)),
                  Tab(
                      text: 'Statistics',
                      icon: Icon(Icons.bar_chart)), // New statistics tab
                ],
              ),
            ),
            body: TabBarView(
              controller: this._tabController,
              children: [
                _buildChoresTab(),
                _buildRewardsTab(),
                _buildChildrenTab(),
                _buildStatisticsTab(), // New statistics tab content
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddChoreDialog(context);
                }
                if (_tabController.index == 1) {
                  // Navigate to add reward screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddRewardScreen()),
                  );
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoresTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
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
                  child: Text(
                      'No chores added yet. Click the + button to add a chore!'),
                );
              }

              // First show all pending approval chores
              final pendingApprovalChores = choreState.pendingApprovalChores;
              final otherChores =
                  choreState.pendingChores + choreState.completedChores;

              final allChores = [...pendingApprovalChores, ...otherChores];

              return ListView.builder(
                itemCount: allChores.length +
                    (pendingApprovalChores.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  // If we have pending approvals, add a section header
                  if (pendingApprovalChores.isNotEmpty && index == 0) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Awaiting Approval',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    );
                  }

                  // Adjust index if we added a header
                  final choreIndex =
                      pendingApprovalChores.isNotEmpty ? index - 1 : index;
                  final chore = allChores[choreIndex];

                  return ChoreCard(
                    chore: chore,
                    onApprove: _handleApproveChore,
                    onAssign: (chore) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignChoreScreen(chore: chore),
                        ),
                      );
                    },
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
            child: Text(
                'No rewards added yet. Click the + button to add a reward!'),
          );
        }

        final rewardsByTier = rewardState.rewardsByTier;
        final children = <Widget>[];

        if (rewardsByTier.containsKey('gold')) {
          children.add(const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Gold Tier Rewards',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber),
            ),
          ));
          children.addAll(rewardsByTier['gold']!
              .map((reward) => RewardCard(reward: reward))
              .toList());
        }

        if (rewardsByTier.containsKey('silver')) {
          children.add(const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Silver Tier Rewards',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
          ));
          children.addAll(rewardsByTier['silver']!
              .map((reward) => RewardCard(reward: reward))
              .toList());
        }

        if (rewardsByTier.containsKey('bronze')) {
          children.add(const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Bronze Tier Rewards',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown),
            ),
          ));
          children.addAll(rewardsByTier['bronze']!
              .map((reward) => RewardCard(reward: reward))
              .toList());
        }

        return ListView(children: children);
      },
    );
  }

  Widget _buildChildrenTab() {
    return Consumer2<UserState, ChoreState>(
      builder: (context, userState, choreState, child) {
        if (userState.childrenInFamily.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No children in family yet'),
            ),
          );
        }

        return Consumer<RewardState>(
          builder: (context, rewardState, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: userState.childrenInFamily.map((childUser) {
                final completedChoreCount = choreState.chores
                    .where((chore) =>
                        chore.isCompleted && chore.completedBy == childUser.id)
                    .length;

                final redeemedRewardCount =
                    rewardState.getChildRedeemedRewards(childUser.id).length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                childUser.name.isNotEmpty
                                    ? childUser.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  childUser.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${childUser.points} Points',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Completed Chores',
                          '$completedChoreCount',
                          Icons.check_circle,
                        ),
                        _buildStatRow(
                          'Redeemed Rewards',
                          '$redeemedRewardCount',
                          Icons.redeem,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer2<ChoreState, RewardState>(
      builder: (context, choreState, rewardState, child) {
        if (choreState.isLoading || rewardState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Calculate statistics
        final totalChores = choreState.chores.length;
        final completedChores =
            choreState.chores.where((c) => c.isCompleted).length;
        final pendingChores =
            choreState.chores.where((c) => c.isPendingApproval).length;
        final totalRewards = rewardState.rewards.length;
        final redeemedRewards =
            rewardState.rewards.where((r) => r.isRedeemed).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Family stats card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Family Statistics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('Total Chores Created', '$totalChores',
                          Icons.assignment),
                      _buildStatRow('Completed Chores', '$completedChores',
                          Icons.check_circle),
                      _buildStatRow('Pending Approval', '$pendingChores',
                          Icons.hourglass_top),
                      _buildStatRow('Total Rewards', '$totalRewards',
                          Icons.card_giftcard),
                      _buildStatRow(
                          'Redeemed Rewards', '$redeemedRewards', Icons.redeem),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Child progress section
              const Text(
                'Children Progress',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Consumer<UserState>(
                builder: (context, userState, _) {
                  if (userState.childrenInFamily.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No children in family yet'),
                      ),
                    );
                  }

                  return Column(
                    children: userState.childrenInFamily.map((childUser) {
                      final completedChoreCount = choreState.chores
                          .where((chore) =>
                              chore.isCompleted &&
                              chore.completedBy == childUser.id)
                          .length;

                      final redeemedRewardCount = rewardState
                          .getChildRedeemedRewards(childUser.id)
                          .length;

                      // Get milestone info
                      final milestoneManager = MilestoneManager();
                      final currentMilestone = milestoneManager
                          .getCurrentMilestone(childUser.points);
                      final nextMilestone =
                          milestoneManager.getNextMilestone(childUser.points);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      childUser.name.isNotEmpty
                                          ? childUser.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        childUser.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${childUser.points} Points',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildStatRow(
                                'Completed Chores',
                                '$completedChoreCount',
                                Icons.check_circle,
                              ),
                              _buildStatRow(
                                'Redeemed Rewards',
                                '$redeemedRewardCount',
                                Icons.redeem,
                              ),

                              // Current milestone
                              if (currentMilestone != null) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Current Milestone: ${currentMilestone.title}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: currentMilestone.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(currentMilestone.icon,
                                        color: currentMilestone.color),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(currentMilestone.description),
                                    ),
                                  ],
                                ),
                              ],

                              // Next milestone
                              if (nextMilestone != null) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Next Milestone: ${nextMilestone.title}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(nextMilestone.icon,
                                        color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${nextMilestone.pointThreshold - childUser.points} more points needed',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: childUser.points /
                                        nextMilestone.pointThreshold,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      nextMilestone.color.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build a row of statistics
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApproveChore(
      String choreId, String childId, int points) async {
    try {
      await Provider.of<ChoreState>(context, listen: false)
          .approveChore(choreId, childId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chore approved and points awarded!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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
                  DropdownMenuItem(
                      value: 'medium', child: Text('Medium Priority')),
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
                child: Text(
                    'Select Deadline: ${selectedDate.toString().split(' ')[0]}'),
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
                    id: DateTime.now()
                        .toString(), // This ID will be replaced by Firestore
                    title: titleController.text,
                    description: descriptionController.text,
                    deadline: selectedDate,
                    pointValue: int.tryParse(rewardController.text) ?? 0,
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
