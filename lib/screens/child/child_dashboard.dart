// lib/screens/child/child_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart';
import '../../widgets/chore_card.dart';
import '../../widgets/reward_card.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';

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
  int _points = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final points = await _firestoreService.getChildPoints(widget.childId);
      if (mounted) {
        setState(() {
          _points = points;
          _isLoading = false;
        });
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text('$_points Points'),
              backgroundColor: Colors.green.shade100,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Chores', icon: Icon(Icons.checklist)),
            Tab(text: 'Rewards', icon: Icon(Icons.card_giftcard)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
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
          !chore.isCompleted).toList();
        
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
                  await Provider.of<ChoreState>(context, listen: false)
                      .toggleChoreCompletion(id);
                  await _loadPoints();
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
      await Provider.of<RewardState>(context, listen: false)
        .redeemReward(rewardId, widget.childId, pointsRequired);
      
      // Refresh points
      await _loadPoints();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward redeemed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    }
  }
}