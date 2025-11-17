// lib/screens/parent/enhanced_parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/chore.dart';
import '../../models/chore_state.dart';
import '../../models/reward_state.dart';
import '../../models/user_state.dart';
import '../../models/user.dart';
import '../../widgets/reward_card.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import 'add_reward_screen.dart';
import 'assign_chore_screen.dart';
import '../reward_history_screen.dart';
import '../../models/milestone.dart';
import '../chore_history_screen.dart';
import '../family_leaderboard_screen.dart';
import '../settings_screen.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/professional_empty_state.dart';
import '../../widgets/modern_chore_card.dart';
import '../../widgets/fun_stat_item.dart';
import '../../utils/chorepal_colors.dart';
import '../../services/email_service.dart';
import '../../services/sms_service.dart';

class EnhancedParentDashboard extends StatefulWidget {
  const EnhancedParentDashboard({super.key});

  @override
  State<EnhancedParentDashboard> createState() =>
      _EnhancedParentDashboardState();
}

class _EnhancedParentDashboardState extends State<EnhancedParentDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
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
    super.dispose();
  }

  Future<void> _loadFamilyData() async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.loadCurrentUser();
      await userState.loadFamilyData();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
            context, 'Failed to load family data. Please try again.');
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
          final familyDoc =
              await _firestoreService.families.doc(familyId).get();
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
          extendBodyBehindAppBar: false,
          appBar: _buildAppBar(),
          body: Builder(
            builder: (context) {
              final isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? ChorePalColors.darkBackgroundGradient
                      : ChorePalColors.backgroundGradient,
                ),
                child: TabBarView(
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
              );
            },
          ),
          bottomNavigationBar: _buildBottomNavBar(),
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? ChorePalColors.darkBlueGradient
              : ChorePalColors.primaryGradient,
        ),
      ),
      title: const Text('ChorePal'),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Menu',
          icon: const Icon(Icons.more_vert),
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
            } else if (value == 'settings') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
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
          ],
        ),
        IconButton(
          icon: const Icon(Icons.email),
          tooltip: 'Test Email',
          onPressed: _handleTestEmail,
        ),
        IconButton(
          icon: const Icon(Icons.sms),
          tooltip: 'Test SMS',
          onPressed: _handleTestSMS,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Future<void> _handleTestEmail() async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      final user = userState.currentUser;

      if (user == null || user is! Parent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found or not a parent'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending test email...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      final success = await EmailService.sendTestEmail(user.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Test email sent to ${user.email}'
                  : 'Failed to send test email',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Email test error: $e');
      String errorMessage = 'Failed to send test email: ${e.toString()}';

      // Extract more details if it's a Firebase Functions error
      if (e.toString().contains('UNAUTHENTICATED')) {
        errorMessage =
            'Authentication required. Please ensure you are logged in.';
      } else if (e.toString().contains('NOT_FOUND')) {
        errorMessage =
            'Cloud Function not found. Please deploy the email function.';
      } else if (e.toString().contains('SendGrid') ||
          e.toString().contains('SENDGRID')) {
        errorMessage = 'Email service error. Check SendGrid configuration.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleTestSMS() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending test SMS...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      const testNumber = '+18777804236';
      final success = await SMSService.sendTestSMS();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Test SMS sent to $testNumber'
                  : 'Failed to send test SMS',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('SMS test error: $e');
      String errorMessage = 'Failed to send test SMS: ${e.toString()}';

      // Extract more details if it's a Firebase Functions error
      if (e.toString().contains('UNAUTHENTICATED')) {
        errorMessage =
            'Authentication required. Please ensure you are logged in.';
      } else if (e.toString().contains('NOT_FOUND')) {
        errorMessage =
            'Cloud Function not found. Please deploy the SMS function.';
      } else if (e.toString().contains('Twilio') ||
          e.toString().contains('TWILIO')) {
        errorMessage =
            'SMS service error. Check Twilio credentials configuration.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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

  /// Builds modern bottom navigation bar
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
              _buildNavItem(Icons.people, 'Children', 2),
              _buildNavItem(Icons.emoji_events, 'Leaderboard', 3),
              _buildNavItem(Icons.bar_chart, 'Stats', 4),
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
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: isSelected ? 26 : 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_tabController.index > 1) {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 75),
      child: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add, size: 24),
        label: Text(
          _tabController.index == 0 ? 'Add Chore' : 'Add Reward',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        tooltip:
            _tabController.index == 0 ? 'Add a new chore' : 'Add a new reward',
      ),
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
                return const ProfessionalLoadingIndicator(
                  message: 'Loading chores...',
                );
              }

              if (choreState.chores.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: ProfessionalEmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No Chores Yet',
                      subtitle:
                          'Start organizing your family\'s tasks by creating your first chore.',
                      actionLabel: 'Create First Chore',
                      onAction: () => _showAddChoreDialog(context),
                    ),
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
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: ChorePalColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChorePalColors.lightBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.family_restroom,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Family Code",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Share with children to join",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    familyCode,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: ChorePalColors.lightBlue,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white, size: 24),
                  tooltip: "Copy code",
                  onPressed: _copyFamilyCodeToClipboard,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoresList(ChoreState choreState) {
    final pendingApprovalChores = choreState.pendingApprovalChores;
    final otherChores = choreState.pendingChores + choreState.completedChores;
    final allChores = [...pendingApprovalChores, ...otherChores];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: allChores.length + (pendingApprovalChores.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (pendingApprovalChores.isNotEmpty && index == 0) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChorePalColors.sunshineOrange.withOpacity(0.2),
                  ChorePalColors.strawberryPink.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ChorePalColors.sunshineOrange.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: ChorePalColors.sunshineOrange.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ChorePalColors.sunshineOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pending_actions,
                    color: ChorePalColors.sunshineOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Awaiting Your Approval',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ChorePalColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pendingApprovalChores.length} chore${pendingApprovalChores.length > 1 ? 's' : ''} need approval',
                        style: TextStyle(
                          fontSize: 13,
                          color: ChorePalColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final choreIndex = pendingApprovalChores.isNotEmpty ? index - 1 : index;
        final chore = allChores[choreIndex];

        return ModernChoreCard(
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
          return const ProfessionalLoadingIndicator(
            message: 'Loading rewards...',
          );
        }
        if (rewardState.rewards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ProfessionalEmptyState(
                icon: Icons.card_giftcard_outlined,
                title: 'No Rewards Yet',
                subtitle:
                    'Motivate your children by creating exciting rewards they can earn with points.',
                actionLabel: 'Create First Reward',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddRewardScreen(),
                    ),
                  );
                },
                iconColor: Colors.purple,
              ),
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
        if (userState.childrenInFamily.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ProfessionalEmptyState(
                icon: Icons.people_outline,
                title: 'No Children Added',
                subtitle:
                    'Share your family code ($familyCode) with your children so they can join and start earning points.',
                iconColor: Colors.blue,
              ),
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

  Widget _buildLeaderboardTab() {
    return const FamilyLeaderboardScreen();
  }

  Widget _buildChildCard(
      Child childUser, ChoreState choreState, RewardState rewardState) {
    final completedChoreCount = choreState.chores
        .where(
            (chore) => chore.isCompleted && chore.completedBy == childUser.id)
        .length;

    final redeemedRewardCount =
        rewardState.getChildRedeemedRewards(childUser.id).length;

    final milestoneManager = MilestoneManager();
    final currentMilestone =
        milestoneManager.getCurrentMilestone(childUser.points);
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                // Remove child button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.person_remove,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Remove child from family',
                    onPressed: () => _showRemoveChildDialog(childUser),
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
                      'Current Milestone', currentMilestone, childUser.points),
                if (nextMilestone != null)
                  _buildMilestoneSectionImproved(
                      'Next Milestone', nextMilestone, childUser.points),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneSectionImproved(
      String label, Milestone milestone, int currentPoints) {
    final bool isCurrentMilestone = label == 'Current Milestone';
    final int pointsNeeded =
        isCurrentMilestone ? 0 : milestone.pointThreshold - currentPoints;
    final double progress =
        isCurrentMilestone ? 1.0 : currentPoints / milestone.pointThreshold;

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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(milestone.color),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildChildStatRow(
      String label, String value, IconData icon, Color color) {
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
          return const ProfessionalLoadingIndicator(
            message: 'Loading statistics...',
          );
        }

        return _buildStatisticsContent(choreState, rewardState);
      },
    );
  }

  Widget _buildStatisticsContent(
      ChoreState choreState, RewardState rewardState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalChores = choreState.chores.length;
    final completedChores =
        choreState.chores.where((c) => c.isCompleted).length;
    final pendingChores =
        choreState.chores.where((c) => c.isPendingApproval).length;
    final totalRewards = rewardState.rewards.length;
    final redeemedRewards =
        rewardState.rewards.where((r) => r.isRedeemed).length;
    final completionRate =
        totalChores > 0 ? ((completedChores / totalChores) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard header
          Text(
            'Family Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ChorePalColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Overview of your family\'s activity',
            style: TextStyle(
              fontSize: 15,
              color: ChorePalColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Fun statistics row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FunStatItem(
                  label: 'Total Chores',
                  value: '$totalChores',
                  icon: Icons.assignment,
                  color: ChorePalColors.skyBlue,
                ),
                const SizedBox(width: 12),
                FunStatItem(
                  label: 'Completed',
                  value: '$completedChores',
                  icon: Icons.check_circle,
                  color: ChorePalColors.grassGreen,
                ),
                const SizedBox(width: 12),
                FunStatItem(
                  label: 'Pending',
                  value: '$pendingChores',
                  icon: Icons.hourglass_top,
                  color: ChorePalColors.sunshineOrange,
                ),
                const SizedBox(width: 12),
                FunStatItem(
                  label: 'Rewards',
                  value: '$totalRewards',
                  icon: Icons.card_giftcard,
                  gradient: ChorePalColors.rewardGradient,
                  color: ChorePalColors.lavenderPurple,
                ),
                const SizedBox(width: 12),
                FunStatItem(
                  label: 'Redeemed',
                  value: '$redeemedRewards',
                  icon: Icons.redeem,
                  color: ChorePalColors.strawberryPink,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Completion rate progress bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ChorePalColors.lavenderPurple.withOpacity(0.15),
                  ChorePalColors.strawberryPink.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ChorePalColors.lavenderPurple.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: ChorePalColors.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completion Rate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : ChorePalColors.textPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your family\'s progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade300
                                    : ChorePalColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: ChorePalColors.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                ChorePalColors.lavenderPurple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '$completionRate%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: completionRate / 100),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 20,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ChorePalColors.lavenderPurple,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Children progress section
          Text(
            'Children Progress',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: ChorePalColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildChildrenProgressSection(choreState, rewardState),
        ],
      ),
    );
  }

  Widget _buildChildrenProgressSection(
      ChoreState choreState, RewardState rewardState) {
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

  Future<void> _handleApproveChore(
      String choreId, String childId, int points) async {
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
                          child: Icon(Icons.add_task,
                              color: Colors.green.shade700),
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
                        subtitle:
                            const Text('Motivate with points for completion'),
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
                            SizedBox(width: 8),
                            Text('High Priority'),
                          ],
                        ),
                        subtitle: const Text(
                            'This chore will be highlighted for children'),
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
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
                              Provider.of<ChoreState>(context, listen: false)
                                  .addChore(
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
                                  pointValue: includeReward
                                      ? (int.tryParse(rewardController.text) ??
                                          0)
                                      : 0,
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

  /// Shows a confirmation dialog for removing a child
  void _showRemoveChildDialog(Child child) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Remove Child'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to remove ${child.name} from your family?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'This action will:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Permanently delete ${child.name}\'s account',
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                    Text(
                      '• Remove all their points and progress',
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                    Text(
                      '• Delete their chore and reward history',
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                    Text(
                      '• This action cannot be undone',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _removeChild(child);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Remove Child'),
            ),
          ],
        );
      },
    );
  }

  /// Removes a child from the family
  Future<void> _removeChild(Child child) async {
    try {
      await Provider.of<UserState>(context, listen: false)
          .removeChildFromFamily(child.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${child.name} has been removed from the family'),
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
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to remove child: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
