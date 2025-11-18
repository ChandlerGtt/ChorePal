// lib/models/leaderboard.dart
import 'package:flutter/material.dart';
import 'user.dart';

/// Represents a leaderboard entry for a child
class LeaderboardEntry {
  final Child child;
  final int rank;
  final int completedChoresThisWeek;
  final int completedChoresThisMonth;
  final int totalCompletedChores;
  final int streak; // Days in a row with completed chores
  final double weeklyProgress; // Percentage of assigned chores completed this week

  LeaderboardEntry({
    required this.child,
    required this.rank,
    required this.completedChoresThisWeek,
    required this.completedChoresThisMonth,
    required this.totalCompletedChores,
    required this.streak,
    required this.weeklyProgress,
  });

  /// Gets the appropriate badge/title based on rank and performance
  String get badge {
    if (rank == 1) return "🏆 Champion";
    if (rank == 2) return "🥈 Star Player";
    if (rank == 3) return "🥉 Rising Star";
    if (streak >= 7) return "🔥 Hot Streak";
    if (weeklyProgress >= 0.9) return "⭐ Consistent";
    if (completedChoresThisWeek >= 5) return "💪 Hard Worker";
    return "🌟 Helper";
  }

  /// Gets the badge color based on rank
  Color get badgeColor {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.brown.shade400;
    if (streak >= 7) return Colors.red;
    if (weeklyProgress >= 0.9) return Colors.green;
    if (completedChoresThisWeek >= 5) return Colors.blue;
    return Colors.purple;
  }

  /// Gets motivational message based on performance
  String get motivationalMessage {
    if (rank == 1) return "You're the family champion! Keep up the amazing work!";
    if (rank == 2) return "So close to the top! One more push and you'll be #1!";
    if (rank == 3) return "Great job! You're in the top 3 helpers!";
    if (streak >= 7) return "Your consistency is inspiring! $streak days strong!";
    if (weeklyProgress >= 0.9) return "You're crushing your weekly goals!";
    if (completedChoresThisWeek >= 5) return "Your hard work is really showing!";
    return "Every chore counts! Keep being awesome!";
  }
}

/// Manages leaderboard calculations and data
class LeaderboardManager {
  static final LeaderboardManager _instance = LeaderboardManager._internal();
  factory LeaderboardManager() => _instance;
  LeaderboardManager._internal();

  /// Calculates leaderboard entries from a list of children and their chore data
  List<LeaderboardEntry> calculateLeaderboard(
    List<Child> children,
    Map<String, Map<String, dynamic>> choreStats,
  ) {
    List<LeaderboardEntry> entries = [];

    for (final child in children) {
      final stats = choreStats[child.id] ?? {};
      
      entries.add(LeaderboardEntry(
        child: child,
        rank: 0, // Will be calculated after sorting
        completedChoresThisWeek: stats['weeklyCompleted'] ?? 0,
        completedChoresThisMonth: stats['monthlyCompleted'] ?? 0,
        totalCompletedChores: stats['totalCompleted'] ?? 0,
        streak: stats['streak'] ?? 0,
        weeklyProgress: stats['weeklyProgress'] ?? 0.0,
      ));
    }

    // Sort by points first, then by weekly completed chores as tiebreaker
    entries.sort((a, b) {
      int pointsComparison = b.child.points.compareTo(a.child.points);
      if (pointsComparison != 0) return pointsComparison;
      
      int weeklyComparison = b.completedChoresThisWeek.compareTo(a.completedChoresThisWeek);
      if (weeklyComparison != 0) return weeklyComparison;
      
      return b.streak.compareTo(a.streak);
    });

    // Assign ranks
    for (int i = 0; i < entries.length; i++) {
      entries[i] = LeaderboardEntry(
        child: entries[i].child,
        rank: i + 1,
        completedChoresThisWeek: entries[i].completedChoresThisWeek,
        completedChoresThisMonth: entries[i].completedChoresThisMonth,
        totalCompletedChores: entries[i].totalCompletedChores,
        streak: entries[i].streak,
        weeklyProgress: entries[i].weeklyProgress,
      );
    }

    return entries;
  }

  /// Gets rank change indicator (up, down, same, new)
  String getRankChange(String childId, int currentRank, Map<String, int> previousRanks) {
    if (!previousRanks.containsKey(childId)) return "new";
    
    final previousRank = previousRanks[childId]!;
    if (currentRank < previousRank) return "up";
    if (currentRank > previousRank) return "down";
    return "same";
  }

  /// Gets appropriate icon for rank change
  IconData getRankChangeIcon(String change) {
    switch (change) {
      case "up": return Icons.trending_up;
      case "down": return Icons.trending_down;
      case "new": return Icons.fiber_new;
      default: return Icons.trending_flat;
    }
  }

  /// Gets color for rank change
  Color getRankChangeColor(String change) {
    switch (change) {
      case "up": return Colors.green;
      case "down": return Colors.red;
      case "new": return Colors.blue;
      default: return Colors.grey;
    }
  }
}