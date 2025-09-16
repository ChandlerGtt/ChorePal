// lib/screens/parent/parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for clipboard functionality
import 'package:provider/provider.dart';
import '../../models/chore.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart'; // Import the RewardState
import '../../models/user_state.dart'; // Import the UserState
import '../../models/user.dart'; // Add this import for Child class
import '../../widgets/chore_card.dart';
import '../../widgets/reward_card.dart'; // Import the RewardCard
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import 'add_reward_screen.dart'; // Import the AddRewardScreen
import 'assign_chore_screen.dart'; // Import the AssignChoreScreen
import '../reward_history_screen.dart';
import '../../models/milestone.dart';
import '../chore_history_screen.dart';

/// The main dashboard screen for parent users.
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
    _tabController = TabController(length: 4, vsync: this);
    // Add listener to rebuild when tab changes (for FAB visibility)
    _tabController.addListener(() {
      setState(() {});
    });
    _loadFamilyCode();
    _loadFamilyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads the family data and updates the UserState
  Future<void> _loadFamilyData() async {
    // Make sure to load updated family data, including all children
    final userState = Provider.of<UserState>(context, listen: false);
    await userState.loadCurrentUser();
    await userState.loadFamilyData();
  }

  /// Loads the family code for the current user
  Future<void> _loadFamilyCode() async {
    if (_authService.currentUser != null) {
      final userDoc = await _firestoreService.users
          .doc(_authService.currentUser!.uid)
          .get();
      if (!mounted) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final familyId = userData['familyId'];

      if (familyId != null) {
        final familyDoc = await _firestoreService.families.doc(familyId).get();
        if (!mounted) return;

        final familyData = familyDoc.data() as Map<String, dynamic>;
        setState(() {
          familyCode =
              familyData['familyCode'] ?? 'FAM123'; // Default code if not set
        });
      }
    }
  }

  /// Copies the family code to clipboard
  void _copyFamilyCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: familyCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Family code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        return Scaffold(
          appBar: _buildAppBar(),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // Prevent swiping which can cause visual issues
            children: [
              _buildChoresTab(),
              _buildRewardsTab(),
              _buildChildrenTab(),
              _buildStatisticsTab(),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  /// Builds the app bar with tabs
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Parent Dashboard'),
      actions: [
        // History button with dropdown menu
        PopupMenuButton<String>(
          tooltip: 'History',
          icon: const Icon(Icons.history),
          onSelected: (value) {
            if (value == 'chores') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChoreHistoryScreen(),
                ),
              );
            } else if (value == 'rewards') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RewardHistoryScreen(),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'chores',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Chore History'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rewards',
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('Reward History'),
                ],
              ),
            ),
          ],
        ),
        // Logout button
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _handleLogout,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Material(
          color: Theme.of(context).primaryColor,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            // Setting a specific text style for the tabs
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.checklist),
                text: 'Chores',
              ),
              Tab(
                icon: Icon(Icons.card_giftcard),
                text: 'Rewards',
              ),
              Tab(
                icon: Icon(Icons.people),
                text: 'Children',
              ),
              Tab(
                icon: Icon(Icons.bar_chart),
                text: 'Statistics',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles user logout
  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  /// Builds the floating action button
  Widget _buildFloatingActionButton() {
    // Only show the FAB on Chores and Rewards tabs (indexes 0 and 1)
    if (_tabController.index > 1) {
      return Container(); // Return an empty container when we're on other tabs
    }
    
    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 0) {
          _showAddChoreDialog(context);
        }
        if (_tabController.index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRewardScreen(),
            ),
          );
        }
      },
      child: const Icon(Icons.add),
    );
  }

  /// Builds the chores tab content
  Widget _buildChoresTab() {
    return Column(
      children: [
        _buildFamilyCodeHeader(),
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

              return _buildChoresList(choreState);
            },
          ),
        ),
      ],
    );
  }

  /// Builds the family code header
  Widget _buildFamilyCodeHeader() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Family Code",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        familyCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: "Copy code",
                      onPressed: _copyFamilyCodeToClipboard,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add Child'),
                  onPressed: () {
                    // Implement add child functionality
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Share this code with your children to let them join your family group",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of chores
  Widget _buildChoresList(ChoreState choreState) {
    // First show all pending approval chores
    final pendingApprovalChores = choreState.pendingApprovalChores;
    final otherChores = choreState.pendingChores + choreState.completedChores;

    final allChores = [...pendingApprovalChores, ...otherChores];

    return ListView.builder(
      itemCount: allChores.length + (pendingApprovalChores.isNotEmpty ? 1 : 0),
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
        final choreIndex = pendingApprovalChores.isNotEmpty ? index - 1 : index;
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
  }

  /// Builds the rewards tab content
  Widget _buildRewardsTab() {
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

        return _buildRewardsList(rewardState);
      },
    );
  }

  /// Builds the list of rewards grouped by tier
  Widget _buildRewardsList(RewardState rewardState) {
    final rewardsByTier = rewardState.rewardsByTier;
    final children = <Widget>[];

    // Create sections for each tier
    final tierColors = {
      'gold': Colors.amber,
      'silver': Colors.grey,
      'bronze': Colors.brown,
    };

    tierColors.forEach((tier, color) {
      if (rewardsByTier.containsKey(tier)) {
        children.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${tier.substring(0, 1).toUpperCase()}${tier.substring(1)} Tier Rewards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ));
        
        children.addAll(rewardsByTier[tier]!
            .map((reward) => RewardCard(reward: reward))
            .toList());
      }
    });

    return ListView(children: children);
  }

  /// Builds the children tab content
  Widget _buildChildrenTab() {
    return Consumer2<UserState, ChoreState>(
      builder: (context, userState, choreState, child) {
        if (userState.childrenInFamily.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No children in family yet'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Family Code: $familyCode',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Share this code with your children so they can join your family',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Consumer<RewardState>(
          builder: (context, rewardState, _) {
            return RefreshIndicator(
              onRefresh: () async {
                // Refresh the family data including children list
                await _loadFamilyData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: userState.childrenInFamily.map((childUser) {
                  return _buildChildCard(childUser, choreState, rewardState);
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds a card for a child
  Widget _buildChildCard(Child childUser, ChoreState choreState, RewardState rewardState) {
    final completedChoreCount = choreState.chores
        .where((chore) => chore.isCompleted && chore.completedBy == childUser.id)
        .length;

    final redeemedRewardCount = rewardState.getChildRedeemedRewards(childUser.id).length;

    // Get milestone info
    final milestoneManager = MilestoneManager();
    final currentMilestone = milestoneManager.getCurrentMilestone(childUser.points);
    final nextMilestone = milestoneManager.getNextMilestone(childUser.points);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    childUser.name.isNotEmpty
                        ? childUser.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childUser.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${childUser.points} Points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Stats section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildChildStatRow(
                  'Completed Chores',
                  '$completedChoreCount',
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildChildStatRow(
                  'Redeemed Rewards',
                  '$redeemedRewardCount',
                  Icons.card_giftcard,
                  Colors.amber,
                ),

                // Current milestone
                if (currentMilestone != null)
                  _buildMilestoneSectionImproved(
                    'Current Milestone', 
                    currentMilestone, 
                    childUser.points
                  ),

                // Next milestone
                if (nextMilestone != null)
                  _buildMilestoneSectionImproved(
                    'Next Milestone', 
                    nextMilestone, 
                    childUser.points
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds an improved milestone section
  Widget _buildMilestoneSectionImproved(String label, Milestone milestone, int currentPoints) {
    final bool isCurrentMilestone = label == 'Current Milestone';
    final int pointsNeeded = isCurrentMilestone ? 0 : milestone.pointThreshold - currentPoints;
    final double progress = isCurrentMilestone ? 1.0 : 
      currentPoints / milestone.pointThreshold;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: milestone.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: milestone.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: milestone.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(milestone.icon, color: milestone.color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label: ${milestone.title}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: milestone.color,
                      ),
                    ),
                    Text(
                      milestone.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isCurrentMilestone) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(milestone.color),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: milestone.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pointsNeeded pts needed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: milestone.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a stat row for the child card
  Widget _buildChildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the statistics tab content
  Widget _buildStatisticsTab() {
    return Consumer2<ChoreState, RewardState>(
      builder: (context, choreState, rewardState, child) {
        if (choreState.isLoading || rewardState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildStatisticsContent(choreState, rewardState);
      },
    );
  }

  /// Builds the content for the statistics tab
  Widget _buildStatisticsContent(ChoreState choreState, RewardState rewardState) {
    // Calculate statistics
    final totalChores = choreState.chores.length;
    final completedChores = choreState.chores.where((c) => c.isCompleted).length;
    final pendingChores = choreState.chores.where((c) => c.isPendingApproval).length;
    final totalRewards = rewardState.rewards.length;
    final redeemedRewards = rewardState.rewards.where((r) => r.isRedeemed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family stats header
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Family Statistics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
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
                  _buildStatRow('Total Chores Created', '$totalChores', Icons.assignment),
                  _buildStatRow('Completed Chores', '$completedChores', Icons.check_circle),
                  _buildStatRow('Pending Approval', '$pendingChores', Icons.hourglass_top),
                  _buildStatRow('Total Rewards', '$totalRewards', Icons.card_giftcard),
                  _buildStatRow('Redeemed Rewards', '$redeemedRewards', Icons.redeem),
                ],
              ),
            ),
          ),
          
          // Child progress section header
          const Padding(
            padding: EdgeInsets.only(top: 24, bottom: 16),
            child: Text(
              'Children Progress',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Child progress list
          _buildChildrenProgressSection(choreState, rewardState),
        ],
      ),
    );
  }

  /// Builds the children progress section
  Widget _buildChildrenProgressSection(ChoreState choreState, RewardState rewardState) {
    return Consumer<UserState>(
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
            return _buildChildProgressCard(childUser, choreState, rewardState);
          }).toList(),
        );
      },
    );
  }

  /// Builds a child progress card
  Widget _buildChildProgressCard(
    Child childUser, 
    ChoreState choreState, 
    RewardState rewardState
  ) {
    final completedChoreCount = choreState.chores
        .where((chore) => chore.isCompleted && chore.completedBy == childUser.id)
        .length;

    final redeemedRewardCount = rewardState.getChildRedeemedRewards(childUser.id).length;

    // Get milestone info
    final milestoneManager = MilestoneManager();
    final currentMilestone = milestoneManager.getCurrentMilestone(childUser.points);
    final nextMilestone = milestoneManager.getNextMilestone(childUser.points);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    childUser.name.isNotEmpty
                        ? childUser.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childUser.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${childUser.points} Points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Stats section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildChildStatRow(
                  'Completed Chores',
                  '$completedChoreCount',
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildChildStatRow(
                  'Redeemed Rewards',
                  '$redeemedRewardCount',
                  Icons.card_giftcard,
                  Colors.amber,
                ),

                // Current milestone
                if (currentMilestone != null)
                  _buildMilestoneSectionImproved(
                    'Current Milestone', 
                    currentMilestone, 
                    childUser.points
                  ),

                // Next milestone
                if (nextMilestone != null)
                  _buildMilestoneSectionImproved(
                    'Next Milestone', 
                    nextMilestone, 
                    childUser.points
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a stat row for the statistics tab
  Widget _buildStatRow(String label, String value, IconData icon) {
    final color = _getStatColor(icon);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Gets an appropriate color for stat icons
  Color _getStatColor(IconData icon) {
    if (icon == Icons.check_circle) {
      return Colors.green;
    } else if (icon == Icons.hourglass_top) {
      return Colors.orange;
    } else if (icon == Icons.assignment) {
      return Colors.blue;
    } else if (icon == Icons.card_giftcard || icon == Icons.redeem) {
      return Colors.purple;
    }
    return Colors.blue;
  }

  /// Handles approving a chore
  Future<void> _handleApproveChore(String choreId, String childId, int points) async {
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

  /// Shows the dialog to add a new chore
  void _showAddChoreDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final rewardController = TextEditingController();
    
    // Add state variables for the dialog
    bool includeReward = false;
    String selectedPriority = 'medium';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    // Use StatefulBuilder to allow updating dialog state
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog title
                    Row(
                      children: [
                        const Icon(Icons.add_task, color: Colors.green),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Add New Chore',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Content
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    
                    // Reward toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SwitchListTile(
                        title: const Text('Include Reward Points'),
                        subtitle: const Text('Offer points for completing this chore'),
                        dense: true,
                        value: includeReward,
                        activeThumbColor: Colors.green,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setDialogState(() {
                            includeReward = value;
                            if (!value) {
                              rewardController.text = '';
                            }
                          });
                        },
                      ),
                    ),
                    
                    // Reward points field (only shown when toggle is on)
                    if (includeReward) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: rewardController,
                        decoration: InputDecoration(
                          labelText: 'Reward Points',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.star),
                          hintText: 'e.g. 10',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    Text(
                      'Priority:',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SwitchListTile(
                        title: const Row(
                          children: [
                            Icon(
                              Icons.priority_high, 
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('High Priority'),
                          ],
                        ),
                        subtitle: const Text('This chore must be completed before other chores'),
                        dense: true,
                        value: selectedPriority == 'high',
                        activeThumbColor: Colors.red,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPriority = value ? 'high' : 'medium';
                          });
                        },
                      ),
                    ),
                    
                    // Deadline section header
                    Text(
                      'Deadline:',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Date picker
                    InkWell(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Time picker
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                alwaysUse24HourFormat: false,
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    selectedTime.format(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Actions
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create Chore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            if (titleController.text.isNotEmpty) {
                              Provider.of<ChoreState>(context, listen: false).addChore(
                                Chore(
                                  id: DateTime.now().toString(),
                                  title: titleController.text,
                                  description: descriptionController.text,
                                  deadline: DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  ),
                                  pointValue: includeReward ? (int.tryParse(rewardController.text) ?? 0) : 0,
                                  priority: selectedPriority,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
