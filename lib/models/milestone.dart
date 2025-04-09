import 'package:flutter/material.dart';

class Milestone {
  final int pointThreshold;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const Milestone({
    required this.pointThreshold,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Predefined milestones for the app
class MilestoneManager {
  // Singleton pattern
  static final MilestoneManager _instance = MilestoneManager._internal();
  factory MilestoneManager() => _instance;
  MilestoneManager._internal();

  // List of predefined milestones
  final List<Milestone> milestones = [
    const Milestone(
      pointThreshold: 50,
      title: "Task Starter",
      description: "Congratulations! You've earned your first 50 points!",
      icon: Icons.star,
      color: Colors.blue,
    ),
    const Milestone(
      pointThreshold: 100,
      title: "Responsibility Rockstar",
      description: "Amazing! You've reached 100 points!",
      icon: Icons.auto_awesome,
      color: Colors.green,
    ),
    const Milestone(
      pointThreshold: 200,
      title: "Chore Champion",
      description: "Wow! You've hit 200 points! You're unstoppable!",
      icon: Icons.emoji_events,
      color: Colors.amber,
    ),
    const Milestone(
      pointThreshold: 500,
      title: "Task Master",
      description: "500 points! You're a master of responsibility!",
      icon: Icons.military_tech,
      color: Colors.purple,
    ),
    const Milestone(
      pointThreshold: 1000,
      title: "Legendary Helper",
      description: "1000 points! You have achieved legendary status!",
      icon: Icons.workspace_premium,
      color: Colors.deepOrange,
    ),
  ];

  // Get milestone for current points
  Milestone? getCurrentMilestone(int points) {
    // Sort milestones in descending order
    final sortedMilestones = List<Milestone>.from(milestones)
      ..sort((a, b) => b.pointThreshold.compareTo(a.pointThreshold));
    
    // Find the highest milestone achieved
    for (final milestone in sortedMilestones) {
      if (points >= milestone.pointThreshold) {
        return milestone;
      }
    }
    
    return null;
  }

  // Get next milestone to achieve
  Milestone? getNextMilestone(int points) {
    // Sort milestones in ascending order
    final sortedMilestones = List<Milestone>.from(milestones)
      ..sort((a, b) => a.pointThreshold.compareTo(b.pointThreshold));
    
    // Find the next milestone to achieve
    for (final milestone in sortedMilestones) {
      if (points < milestone.pointThreshold) {
        return milestone;
      }
    }
    
    return null; // Already achieved all milestones
  }
  
  // Check if a new milestone has been reached
  Milestone? checkNewMilestone(int oldPoints, int newPoints) {
    // Sort milestones in ascending order
    final sortedMilestones = List<Milestone>.from(milestones)
      ..sort((a, b) => a.pointThreshold.compareTo(b.pointThreshold));
    
    // Find milestones that were crossed between old and new points
    for (final milestone in sortedMilestones) {
      if (oldPoints < milestone.pointThreshold && newPoints >= milestone.pointThreshold) {
        return milestone;
      }
    }
    
    return null; // No new milestone reached
  }
} 