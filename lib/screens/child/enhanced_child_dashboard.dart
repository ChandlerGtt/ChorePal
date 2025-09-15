// lib/screens/child/enhanced_child_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart';
import '../../models/milestone.dart';
import '../../widgets/enhanced_chore_card.dart';
import '../../widgets/reward_card.dart';
import '../../widgets/enhanced_milestone_dialog.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import '../reward_history_screen.dart';
import '../chore_history_screen.dart';
import '../family_leaderboard_screen.dart';

class EnhancedChildDashboard extends StatefulWidget {
  final String childId;
  
  const EnhancedChildDashboard({
    Key? key, 
    required this.childId,
  }) : super(key: key);

  @override
  State<EnhancedChildDashboard> createState() => _EnhancedChildDashboardState();
}

class _EnhancedChildDashboardState extends State<EnhancedChildDashboard> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final MilestoneManager _milestoneManager = MilestoneManager();
  int _points = 0;
  bool _isLoading = true;
  int _lastPoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Added leaderboard tab
    // Schedule loading data after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPoints();
    });
  }

  Future<void> _loadPoints() async {
    try {
      _lastPoints = _points;
      
      final points = await _firestoreService.getChildPoints(widget.childId);
      if (mounted) {
        setState(() {
          _points = points;
          _isLoading = false;
        });
        
        _checkMilestones();
      }
    } catch (e) {
      print('Error loading points: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _checkMilestones() {
    if (_lastPoints != _points) {
      final milestone = _milestoneManager.checkNewMilestone(_lastPoints, _points);
      if (milestone != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          EnhancedMilestoneCelebrationDialog.show(context, milestone, _points);
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My ChorePal'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onSelected: (value) {
              if (value == 'chores') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChoreHistoryScreen(childId: widget.childId),
                  ),
                );
              } else if (value == 'rewards') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RewardHistoryScreen(childId: widget.childId),
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
                    Text('My Completed Chores'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rewards',
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('My Redeemed Rewards'),
                  ],
                ),
              ),
            ],
          ),
          // Enhanced points display with animations
          Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade300, Colors.amber.shade500],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_points Points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
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
                  text: 'My Chores',
                ),
                Tab(
                  icon: Icon(Icons.card_giftcard),
                  text: 'Rewards',
                ),
                Tab(
                  icon: Icon(Icons.emoji_events),
                  text: 'Leaderboard',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildChoresTab(),
                _buildRewardsTab(),
                _buildLeaderboardTab(),
              ],
            ),
    );
  }

  Widget _buildChoresTab() {
    return Consumer<ChoreState>(
      builder: (context, choreState, child) {
        if (choreState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final myChores = choreState.chores.where((chore) => 
          !chore.isCompleted && 
          (chore.assignedTo.isEmpty || chore.assignedTo.contains(widget.childId))
        ).toList();
        
        if (myChores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.celebration,
                    size: 64,
                    color: Colors.green.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'All caught up!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No chores assigned yet. Great job!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<ChoreState>(context, listen: false).loadChores();
            await _loadPoints();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: myChores.length,
            itemBuilder: (context, index) {
              final chore = myChores[index];
              return EnhancedChoreCard(
                chore: chore,
                isChild: true,
                onToggleComplete: (id) async {
                  try {
                    await Provider.of<ChoreState>(context, listen: false)
                        .markChoreAsPendingApproval(id, widget.childId);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Chore completed! Waiting for parent approval.'),
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
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
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
                Text(
                  'No rewards available yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask your parents to add some rewards!',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }
        
        final rewardsByTier = rewardState.rewardsByTier;
        final children = <Widget>[];
        
        // Build tier sections
        for (final tier in ['gold', 'silver', 'bronze']) {
          if (rewardsByTier.containsKey(tier)) {
            children.add(_buildTierHeader(tier));
            children.addAll(
              rewardsByTier[tier]!.map((reward) => 
                RewardCard(
                  reward: reward,
                  onRedeem: _points >= reward.pointsRequired && !reward.isRedeemed
                    ? (id, points) => _handleRedeemReward(id, points)
                    : null,
                )
              ).toList()
            );
          }
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<RewardState>(context, listen: false).loadRewards();
            await _loadPoints();
          },
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: children,
          ),
        );
      },
    );
  }

  Widget _buildTierHeader(String tier) {
    Color color;
    IconData icon;
    
    switch (tier) {
      case 'gold':
        color = Colors.amber;
        icon = Icons.workspace_premium;
        break;
      case 'silver':
        color = Colors.grey.shade400;
        icon = Icons.military_tech;
        break;
      case 'bronze':
        color = Colors.brown.shade400;
        icon = Icons.emoji_events;
        break;
      default:
        color = Colors.blue;
        icon = Icons.card_giftcard;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildLeaderboardTab() {
    return FamilyLeaderboardScreen(currentChildId: widget.childId);
  }

  Future<void> _handleRedeemReward(String rewardId, int pointsRequired) async {
    try {
      _lastPoints = _points;
      
      await Provider.of<RewardState>(context, listen: false)
        .redeemReward(rewardId, widget.childId);
      
      await _loadPoints();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Reward redeemed successfully!'),
              ],
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}