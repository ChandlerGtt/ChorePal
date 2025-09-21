// lib/screens/child/child_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart';
import '../../models/milestone.dart';
import '../../widgets/chore_card.dart';
import '../../widgets/reward_card.dart';
import '../../widgets/milestone_dialog.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import '../reward_history_screen.dart';
import '../chore_history_screen.dart';

class ChildDashboard extends StatefulWidget {
  final String childId;
  
  const ChildDashboard({
    Key? key, 
    required this.childId,
  }) : super(key: key);

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final MilestoneManager _milestoneManager = MilestoneManager();
  int _points = 0;
  bool _isLoading = true;
  int _lastPoints = 0; // Track previous points for milestone detection

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      // Save previous points for milestone detection
      _lastPoints = _points;
      
      final points = await _firestoreService.getChildPoints(widget.childId);
      if (mounted) {
        setState(() {
          _points = points;
          _isLoading = false;
        });
        
        // Check for milestone achievements
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
        // Show celebration dialog for the new milestone
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MilestoneCelebrationDialog.show(context, milestone, _points);
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
          // History button with dropdown menu
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
          // Points display
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text('$_points Points'),
              backgroundColor: Colors.green.shade100,
            ),
          ),
          // Logout button
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
        
        // Filter chores for this child
        final myChores = choreState.chores.where((chore) => 
          !chore.isCompleted && 
          (chore.assignedTo.isEmpty || chore.assignedTo.contains(widget.childId))
        ).toList();
        
        if (myChores.isEmpty) {
          return const Center(
            child: Text('No chores assigned yet!'),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<ChoreState>(context, listen: false).loadChores();
            await _loadPoints();
          },
          child: ListView.builder(
            itemCount: myChores.length,
            itemBuilder: (context, index) {
              final chore = myChores[index];
              return ChoreCard(
                chore: chore,
                isChild: true,
                onToggleComplete: (id) async {
                  try {
                    await Provider.of<ChoreState>(context, listen: false)
                        .markChoreAsPendingApproval(id, widget.childId);
                    
                    // Check if the widget is still mounted before showing SnackBar
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chore marked as completed! Waiting for parent approval.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
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
          return const Center(
            child: Text('No rewards available yet!'),
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
            rewardsByTier['gold']!.map((reward) => 
              RewardCard(
                reward: reward,
                onRedeem: _points >= reward.pointsRequired && !reward.isRedeemed
                  ? (id, points) => _handleRedeemReward(id, points)
                  : null,
              )
            ).toList()
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
            rewardsByTier['silver']!.map((reward) => 
              RewardCard(
                reward: reward,
                onRedeem: _points >= reward.pointsRequired && !reward.isRedeemed 
                  ? (id, points) => _handleRedeemReward(id, points)
                  : null,
              )
            ).toList()
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
            rewardsByTier['bronze']!.map((reward) => 
              RewardCard(
                reward: reward,
                onRedeem: _points >= reward.pointsRequired && !reward.isRedeemed
                  ? (id, points) => _handleRedeemReward(id, points) 
                  : null,
              )
            ).toList()
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<RewardState>(context, listen: false).loadRewards();
            await _loadPoints();
          },
          child: ListView(children: children),
        );
      },
    );
  }

  Future<void> _handleRedeemReward(String rewardId, int pointsRequired) async {
    try {
      // Save current points for milestone detection
      _lastPoints = _points;
      
      await Provider.of<RewardState>(context, listen: false)
        .redeemReward(rewardId, widget.childId);
      
      // Refresh points
      await _loadPoints();
      
      // Check if the widget is still mounted before showing SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward redeemed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }
}