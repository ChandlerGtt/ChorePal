// lib/screens/child/enhanced_child_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart';
import '../../models/milestone.dart';
import '../../widgets/reward_card.dart';
import '../../widgets/enhanced_milestone_dialog.dart';
import '../../services/firestore_service.dart';
import '../reward_history_screen.dart';
import '../chore_history_screen.dart';
import '../family_leaderboard_screen.dart';
import '../settings_screen.dart';
import '../notification_test_screen.dart';
import '../../widgets/professional_empty_state.dart';
import '../../widgets/modern_chore_card.dart';
import '../../widgets/dashboard_header.dart';
import '../../models/user_state.dart';
import '../../models/user.dart';
import '../../utils/chorepal_colors.dart';

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
    _tabController =
        TabController(length: 3, vsync: this); // Added leaderboard tab
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
      final milestone =
          _milestoneManager.checkNewMilestone(_lastPoints, _points);
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
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(),
      body: Builder(
        builder: (context) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? ChorePalColors.darkBackgroundGradient
                  : ChorePalColors.backgroundGradient,
            ),
            child: _isLoading
                ? const ProfessionalLoadingIndicator(
                    message: 'Loading your dashboard...',
                  )
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
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Consumer<UserState>(
        builder: (context, userState, child) {
          // Find the current child user
          User? currentUser;
          if (userState.currentUser != null &&
              userState.currentUser!.id == widget.childId) {
            currentUser = userState.currentUser;
          } else {
            // Try to find in children list
            currentUser = userState.childrenInFamily
                .where((child) => child.id == widget.childId)
                .firstOrNull;
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isSmallScreen = screenWidth < 400;
              
              return DashboardHeader(
                user: currentUser,
                actions: [
                  PopupMenuButton<String>(
                    tooltip: 'Menu',
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2D2D2D)
                        : Colors.white,
                    onSelected: (value) {
                      if (value == 'chores') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ChoreHistoryScreen(childId: widget.childId),
                          ),
                        );
                      } else if (value == 'rewards') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                RewardHistoryScreen(childId: widget.childId),
                          ),
                        );
                      } else if (value == 'settings') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      } else if (value == 'test_notifications') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationTestScreen(),
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
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'test_notifications',
                    child: Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Test Notifications'),
                      ],
                    ),
                  ),
                ],
              ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Settings',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  Flexible(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: screenWidth * 0.01,
                        right: screenWidth * 0.02,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? screenWidth * 0.02 : screenWidth * 0.025,
                        vertical: 6,
                      ),
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
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: isSmallScreen ? 14 : 16,
                              width: isSmallScreen ? 14 : 16,
                              child: Icon(
                                Icons.stars,
                                color: Colors.white,
                                size: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 5),
                            Flexible(
                              child: Text(
                                isSmallScreen ? '$_points' : '$_points Points',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 12 : 13,
                                  height: 1.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? ChorePalColors.darkBlueGradient
            : ChorePalColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color:
                (isDarkMode ? ChorePalColors.darkBlue : ChorePalColors.skyBlue)
                    .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.checklist, 'Chores', 0),
              _buildNavItem(Icons.card_giftcard, 'Rewards', 1),
              _buildNavItem(Icons.emoji_events, 'Leaderboard', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: isSelected ? 26 : 22,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSelected ? 11 : 10,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoresTab() {
    return Consumer<ChoreState>(
      builder: (context, choreState, child) {
        if (choreState.isLoading) {
          return const ProfessionalLoadingIndicator(
            message: 'Loading your chores...',
          );
        }

        final myChores = choreState.chores
            .where((chore) =>
                !chore.isCompleted &&
                (chore.assignedTo.isEmpty ||
                    chore.assignedTo.contains(widget.childId)))
            .toList();

        if (myChores.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: ProfessionalEmptyState(
                icon: Icons.celebration,
                title: 'All Caught Up!',
                subtitle:
                    'You don\'t have any chores assigned right now. Great job staying on top of your tasks!',
                iconColor: Colors.green,
              ),
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
              return ModernChoreCard(
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
                              Text(
                                  'Chore completed! Waiting for parent approval.'),
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
          return const ProfessionalLoadingIndicator(
            message: 'Loading rewards...',
          );
        }

        if (rewardState.rewards.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: ProfessionalEmptyState(
                icon: Icons.card_giftcard_outlined,
                title: 'No Rewards Available',
                subtitle:
                    'Ask your parents to add some exciting rewards you can earn with your points!',
                iconColor: Colors.purple,
              ),
            ),
          );
        }

        final rewardsByTier = rewardState.rewardsByTier;
        final children = <Widget>[];

        // Build tier sections
        for (final tier in ['gold', 'silver', 'bronze']) {
          if (rewardsByTier.containsKey(tier)) {
            children.add(_buildTierHeader(tier));
            children.addAll(rewardsByTier[tier]!
                .map((reward) => RewardCard(
                      reward: reward,
                      onRedeem:
                          _points >= reward.pointsRequired && !reward.isRedeemed
                              ? (id, points) => _handleRedeemReward(id, points)
                              : null,
                    ))
                .toList());
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<RewardState>(context, listen: false)
                .loadRewards();
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
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 8),
                Text('Reward redeemed successfully!'),
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
            content:
                Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
