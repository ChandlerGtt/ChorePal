// lib/screens/family_leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/leaderboard.dart';
import '../models/user_state.dart';
import '../models/chore_state.dart';
/*unused
import '../models/user.dart';
*/
class FamilyLeaderboardScreen extends StatefulWidget {
  final String? currentChildId; // If viewing as a child

  const FamilyLeaderboardScreen({
    Key? key,
    this.currentChildId,
  }) : super(key: key);

  @override
  State<FamilyLeaderboardScreen> createState() => _FamilyLeaderboardScreenState();
}

class _FamilyLeaderboardScreenState extends State<FamilyLeaderboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late ConfettiController _confettiController;
  
  List<LeaderboardEntry> _leaderboardEntries = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week'; // week, month, all-time

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    _loadLeaderboardData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });

    final userState = Provider.of<UserState>(context, listen: false);
    final choreState = Provider.of<ChoreState>(context, listen: false);
    
    // Load family data if not already loaded
    await userState.loadFamilyData();
    await choreState.loadChores();

    // Calculate stats for each child
    Map<String, Map<String, dynamic>> choreStats = {};
    
    for (final child in userState.childrenInFamily) {
      choreStats[child.id] = await _calculateChildStats(child.id, choreState);
    }

    // Generate leaderboard
    final leaderboardManager = LeaderboardManager();
    _leaderboardEntries = leaderboardManager.calculateLeaderboard(
      userState.childrenInFamily,
      choreStats,
    );

    setState(() {
      _isLoading = false;
    });

    // Start animations
    _slideController.forward();
    _bounceController.repeat(reverse: true);
    
    // Show confetti for the winner
    if (_leaderboardEntries.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _confettiController.play();
      });
    }
  }

  Future<Map<String, dynamic>> _calculateChildStats(String childId, ChoreState choreState) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    int weeklyCompleted = 0;
    int monthlyCompleted = 0;
    int totalCompleted = 0;
    int streak = 0;
    
    final completedChores = choreState.completedChores
        .where((chore) => chore.completedBy == childId)
        .toList();

    for (final chore in completedChores) {
      totalCompleted++;
      
      if (chore.completedAt != null) {
        if (chore.completedAt!.isAfter(weekStart)) {
          weeklyCompleted++;
        }
        if (chore.completedAt!.isAfter(monthStart)) {
          monthlyCompleted++;
        }
      }
    }

    // Calculate streak (simplified - last 7 days)
    streak = _calculateStreak(completedChores);
    
    // Calculate weekly progress
    final weeklyAssigned = choreState.chores
        .where((chore) => chore.assignedTo.contains(childId) && 
                         chore.deadline.isAfter(weekStart))
        .length;
    
    final weeklyProgress = weeklyAssigned > 0 ? weeklyCompleted / weeklyAssigned : 0.0;

    return {
      'weeklyCompleted': weeklyCompleted,
      'monthlyCompleted': monthlyCompleted,
      'totalCompleted': totalCompleted,
      'streak': streak,
      'weeklyProgress': weeklyProgress,
    };
  }

  int _calculateStreak(List<dynamic> completedChores) {
    // Simplified streak calculation - count consecutive days with completed chores
    if (completedChores.isEmpty) return 0;
    
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 7; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final hasChoreOnDay = completedChores.any((chore) {
        if (chore.completedAt == null) return false;
        final completedDate = chore.completedAt!;
        return completedDate.year == checkDate.year &&
               completedDate.month == checkDate.month &&
               completedDate.day == checkDate.day;
      });
      
      if (hasChoreOnDay) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Leaderboard'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadLeaderboardData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'all-time', child: Text('All Time')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getPeriodTitle()),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ],
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.02,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
                Colors.orange,
              ],
            ),
          ),

          // Content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildLeaderboardContent(),
        ],
      ),
    );
  }

  String _getPeriodTitle() {
    switch (_selectedPeriod) {
      case 'week': return 'This Week';
      case 'month': return 'This Month';
      case 'all-time': return 'All Time';
      default: return 'This Week';
    }
  }

  Widget _buildLeaderboardContent() {
    if (_leaderboardEntries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No leaderboard data yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Complete some chores to see the family rankings!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboardData,
      child: CustomScrollView(
        slivers: [
          // Header section with trophy
          SliverToBoxAdapter(
            child: _buildHeaderSection(),
          ),
          
          // Leaderboard list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: Interval(
                        index * 0.1, 
                        (index * 0.1) + 0.7,
                        curve: Curves.easeOutBack,
                      ),
                    )),
                    child: _buildLeaderboardCard(
                      _leaderboardEntries[index],
                      index,
                    ),
                  );
                },
                childCount: _leaderboardEntries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    if (_leaderboardEntries.isEmpty) return const SizedBox();

    final winner = _leaderboardEntries.first;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Trophy animation
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_bounceController.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Winner info
          Text(
            'Family Champion',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.amber,
                  child: Text(
                    winner.child.name.isNotEmpty
                        ? winner.child.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      winner.child.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${winner.child.points} points',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int index) {
    final isCurrentUser = widget.currentChildId == entry.child.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isCurrentUser ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isCurrentUser 
              ? BorderSide(color: Colors.blue, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: entry.rank <= 3
                ? LinearGradient(
                    colors: _getRankGradient(entry.rank),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank badge
                _buildRankBadge(entry.rank),
                
                const SizedBox(width: 16),
                
                // Avatar
                Hero(
                  tag: 'avatar_${entry.child.id}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: entry.badgeColor.withOpacity(0.2),
                    child: Text(
                      entry.child.name.isNotEmpty
                          ? entry.child.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: entry.badgeColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Child info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.child.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: entry.rank <= 3 ? Colors.white : null,
                              ),
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: entry.badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.badge,
                          style: TextStyle(
                            color: entry.rank <= 3 ? Colors.white : entry.badgeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Stats row
                      Row(
                        children: [
                          _buildStatChip(
                            '${entry.child.points}',
                            'points',
                            Icons.star,
                            Colors.amber,
                            entry.rank <= 3,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            '${entry.completedChoresThisWeek}',
                            'this week',
                            Icons.check_circle,
                            Colors.green,
                            entry.rank <= 3,
                          ),
                          if (entry.streak > 0) ...[
                            const SizedBox(width: 8),
                            _buildStatChip(
                              '${entry.streak}',
                              'day streak',
                              Icons.local_fire_department,
                              Colors.red,
                              entry.rank <= 3,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    Widget content;
    
    if (rank == 1) {
      badgeColor = Colors.amber;
      content = const Icon(Icons.emoji_events, color: Colors.white, size: 20);
    } else if (rank == 2) {
      badgeColor = Colors.grey.shade400;
      content = Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16));
    } else if (rank == 3) {
      badgeColor = Colors.brown.shade400;
      content = Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16));
    } else {
      badgeColor = Colors.grey.shade300;
      content = Text('$rank', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 14));
    }
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: rank <= 3 ? [
          BoxShadow(
            color: badgeColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Center(child: content),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon, Color color, bool isTopRank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isTopRank 
            ? Colors.white.withOpacity(0.2)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isTopRank ? Colors.white : color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isTopRank ? Colors.white : color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isTopRank ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [Colors.amber.shade300, Colors.amber.shade600];
      case 2:
        return [Colors.grey.shade300, Colors.grey.shade500];
      case 3:
        return [Colors.brown.shade300, Colors.brown.shade500];
      default:
        return [Colors.blue.shade300, Colors.blue.shade600];
    }
  }
}