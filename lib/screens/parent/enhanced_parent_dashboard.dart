// lib/screens/parent/enhanced_parent_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/chore.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart';
import '../../models/user_state.dart';
import '../../models/user.dart';
import '../../widgets/enhanced_chore_card.dart';
import '../../widgets/reward_card.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import '../../models/reward.dart';
import 'add_reward_screen.dart';
import 'assign_chore_screen.dart';
import '../reward_history_screen.dart';
import '../../models/milestone.dart';
import '../chore_history_screen.dart';
import '../family_leaderboard_screen.dart';
import '../../widgets/error_widget.dart';



class EnhancedParentDashboard extends StatefulWidget {
  const EnhancedParentDashboard({super.key});

  @override
  State<EnhancedParentDashboard> createState() => _EnhancedParentDashboardState();
}

class _EnhancedParentDashboardState extends State<EnhancedParentDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  final TextEditingController _parentEmail = TextEditingController();
  String familyCode = 'Loading...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadFamilyCode();
    // Schedule loading data after the current frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFamilyData();
    });
  }



  @override
  void dispose() {
    _tabController.dispose();
    _parentEmail.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyData() async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.loadCurrentUser();
      await userState.loadFamilyData();
           } catch (e) {
         if (mounted) {
           AppSnackBar.showError(context, 'Failed to load family data. Please try again.');
         }
       }
  }


  Future<void> _loadFamilyCode() async {
    try {
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
            familyCode = familyData['familyCode'] ?? 'FAM123';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          familyCode = 'Error loading code';
        });
      }
    }
  }

  void _copyFamilyCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: familyCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy, color: Colors.white),
            SizedBox(width: 8),
            Text('Family code copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildChoresTab(),
              _buildRewardsTab(),
              _buildChildrenTab(),
              _buildLeaderboardTab(),
              _buildStatisticsTab(),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Parent Dashboard'),
      actions: [
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
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'chores',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Chore History'),
                ],
              ),
            ),
            PopupMenuItem(
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
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            isScrollable: true,
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
                icon: Icon(Icons.emoji_events),
                text: 'Leaderboard',
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

  Widget _buildFloatingActionButton() {
    if (_tabController.index > 1) {
      return Container();
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No chores created yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Click the + button to add your first chore!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return _buildChoresList(choreState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyCodeHeader() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.family_restroom, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  "Family Code",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      familyCode,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    tooltip: "Copy code",
                    onPressed: _copyFamilyCodeToClipboard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Share this code with your children so they can join your family group",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoresList(ChoreState choreState) {
    final pendingApprovalChores = choreState.pendingApprovalChores;
    final otherChores = choreState.pendingChores + choreState.completedChores;
    final allChores = [...pendingApprovalChores, ...otherChores];

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: allChores.length + (pendingApprovalChores.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (pendingApprovalChores.isNotEmpty && index == 0) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.orange.shade200],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Awaiting Your Approval (${pendingApprovalChores.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        final choreIndex = pendingApprovalChores.isNotEmpty ? index - 1 : index;
        final chore = allChores[choreIndex];

        return EnhancedChoreCard(
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

  Widget _buildRewardsTab() {
    return Consumer<RewardState>(
      builder: (context, rewardState, child) {
        if (rewardState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (rewardState.rewards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_giftcard_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No rewards created yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Click the + button to add your first reward!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return _buildRewardsList(rewardState);
      },
    );
  }

  Widget _buildRewardsList(RewardState rewardState) {
    final rewardsByTier = rewardState.rewardsByTier;
    final children = <Widget>[];

    final tierColors = {
      'gold': Colors.amber,
      'silver': Colors.grey,
      'bronze': Colors.brown,
    };

    tierColors.forEach((tier, color) {
      if (rewardsByTier.containsKey(tier)) {
        children.add(_buildTierHeader(tier, color));
        children.addAll(rewardsByTier[tier]!
            .map((reward) => RewardCard(reward: reward))
            .toList());
      }
    });

    return ListView(
      padding: const EdgeInsets.all(8),
      children: children,
    );
  }

  Widget _buildTierHeader(String tier, Color color) {
    IconData icon;
    switch (tier) {
      case 'gold':
        icon = Icons.workspace_premium;
        break;
      case 'silver':
        icon = Icons.military_tech;
        break;
      case 'bronze':
        icon = Icons.emoji_events;
        break;
      default:
        icon = Icons.card_giftcard;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            '${tier.substring(0, 1).toUpperCase()}${tier.substring(1)} Tier Rewards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenTab() {
    return Consumer2<UserState, ChoreState>(
      builder: (context, userState, choreState, child) {
        //check if theres children associated with the user
        if (userState.childrenInFamily.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom:12.0),
                      child : Row(
                        children : [
                          Expanded(
                            child : TextField(
                              controller : _parentEmail,
                              decoration : const InputDecoration(
                              labelText: 'enter Parent email to invite!',
                              border : OutlineInputBorder(),
                              prefixIcon : Icon(Icons.search),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            onPressed: () async {

                              final email = _parentEmail.text.trim();
                              if(email.isEmpty){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content : Text('please enter an email')),
                                );

                                try{
                                  final parent = await _firestoreService.parentExists(email);
                                  await _firestoreService.addParentToFamily(userState.familyId.toString(), parent.id);
                                } catch(e){
                                  //not actually sure what the error should be but here we are
                                }

                              }

                            },
                            style : ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              ),
                            child: const Text('send'),
                          ),
                        ],
                      ),
                  ),
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No children in family yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Family Code: $familyCode',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Share this code with your children so they can join your family',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
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
                await _loadFamilyData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children:[
                  Padding(
                    padding: const EdgeInsets.only(bottom:12.0),
                      child : Row(
                        children : [
                          Expanded(
                            child : TextField(
                              controller : _parentEmail,
                              decoration : const InputDecoration(
                              labelText: 'enter Parent email to invite!',
                              border : OutlineInputBorder(),
                              prefixIcon : Icon(Icons.search),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            onPressed: () async {
                              final email = _parentEmail.text.trim();
                              if(email.isEmpty){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content : Text('please enter an email')),
                                );
                              }

                              try{
                                final parent = await _firestoreService.parentExists(email);
                                await _firestoreService.addParentToFamily(userState.familyId.toString(), parent.id);
                              } catch(e){
                                //not actually sure what the error should be but here we are
                              }

                            },
                            style : ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              ),
                            child: const Text('send'),
                          ),
                        ],
                      ),
                  ),
                ...userState.childrenInFamily.map((childUser) {
                  return _buildChildCard(childUser, choreState, rewardState);
                }).toList(),
                        ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return const FamilyLeaderboardScreen();
  }

  Widget _buildChildCard(Child childUser, ChoreState choreState, RewardState rewardState) {
    final completedChoreCount = choreState.chores
        .where((chore) => chore.isCompleted && chore.completedBy == childUser.id)
        .length;

    final redeemedRewardCount = rewardState.getChildRedeemedRewards(childUser.id).length;

    final milestoneManager = MilestoneManager();
    final currentMilestone = milestoneManager.getCurrentMilestone(childUser.points);
    final nextMilestone = milestoneManager.getNextMilestone(childUser.points);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    childUser.name.isNotEmpty
                        ? childUser.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${childUser.points} Points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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

                if (currentMilestone != null)
                  _buildMilestoneSectionImproved(
                    'Current Milestone', 
                    currentMilestone, 
                    childUser.points
                  ),

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

  Widget _buildMilestoneSectionImproved(String label, Milestone milestone, int currentPoints) {
    final bool isCurrentMilestone = label == 'Current Milestone';
    final int pointsNeeded = isCurrentMilestone ? 0 : milestone.pointThreshold - currentPoints;
    final double progress = isCurrentMilestone ? 1.0 : 
      currentPoints / milestone.pointThreshold;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: milestone.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: milestone.color.withValues(alpha: 0.3),
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
                  color: milestone.color.withValues(alpha: 0.2),
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
                    color: milestone.color.withValues(alpha: 0.2),
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

  Widget _buildChildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildStatisticsContent(ChoreState choreState, RewardState rewardState) {
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
          const Text(
            'Family Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
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
          
          const SizedBox(height: 24),
          const Text(
            'Children Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildChildrenProgressSection(choreState, rewardState),
        ],
      ),
    );
  }

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
            return _buildChildCard(childUser, choreState, rewardState);
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    final color = _getStatColor(icon);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Future<void> _handleApproveChore(String choreId, String childId, int points) async {
    try {
      await Provider.of<ChoreState>(context, listen: false)
          .approveChore(choreId, childId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.white),
              SizedBox(width: 8),
              Text('Chore approved and points awarded!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddChoreDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final rewardController = TextEditingController();
    
    bool includeReward = false;
    String selectedPriority = 'medium';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_task, color: Colors.green.shade700),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Create New Chore',
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
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Chore Title',
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
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SwitchListTile(
                        title: const Text('Include Reward Points'),
                        subtitle: const Text('Motivate with points for completion'),
                        dense: true,
                        value: includeReward,
                        activeColor: Colors.green,
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
                    Container(
                      padding: const EdgeInsets.all(12),
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
                            const SizedBox(width: 8),
                            const Text('High Priority'),
                          ],
                        ),
                        subtitle: const Text('This chore will be highlighted for children'),
                        dense: true,
                        value: selectedPriority == 'high',
                        activeColor: Colors.red,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPriority = value ? 'high' : 'medium';
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Text(
                      'Deadline:',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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