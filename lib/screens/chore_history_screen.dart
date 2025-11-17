import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chore.dart';
import '../models/chore_state.dart';
import '../models/user_state.dart';
/* unused
import '../models/user.dart';
*/
import 'package:intl/intl.dart';

class ChoreHistoryScreen extends StatelessWidget {
  final String? childId; // Optional - if passed, shows only this child's history

  const ChoreHistoryScreen({Key? key, this.childId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(childId != null ? 'My Chore History' : 'Family Chore History'),
      ),
      body: Consumer2<ChoreState, UserState>(
        builder: (context, choreState, userState, child) {
          final completedChores = _getCompletedChores(choreState);
          
          if (completedChores.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No chore history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Completed chores will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          // Group chores by month
          final groupedChores = _groupChoresByMonth(completedChores);
          
          return RefreshIndicator(
            onRefresh: () async {
              await choreState.loadChores();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedChores.length,
              itemBuilder: (context, index) {
                final monthKey = groupedChores.keys.elementAt(index);
                final monthChores = groupedChores[monthKey]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month header
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0),
                      child: Text(
                        monthKey,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Month chores
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: monthChores.length,
                      itemBuilder: (context, choreIndex) {
                        return _buildCompactHistoryItem(
                          context, 
                          monthChores[choreIndex], 
                          userState,
                        );
                      },
                    ),
                    // Add some space between months
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  // Get completed chores, filtering by childId if provided
  List<Chore> _getCompletedChores(ChoreState choreState) {
    if (childId != null) {
      return choreState.completedChores
          .where((chore) => chore.completedBy == childId)
          .toList();
    } else {
      return choreState.completedChores;
    }
  }
  
  // Group chores by month
  Map<String, List<Chore>> _groupChoresByMonth(List<Chore> chores) {
    final Map<String, List<Chore>> grouped = {};
    
    for (final chore in chores) {
      if (chore.completedAt != null) {
        final monthKey = DateFormat('MMMM yyyy').format(chore.completedAt!);
        
        if (!grouped.containsKey(monthKey)) {
          grouped[monthKey] = [];
        }
        
        grouped[monthKey]!.add(chore);
      }
    }
    
    // Sort the map keys by date (most recent first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aDate = DateFormat('MMMM yyyy').parse(a);
        final bDate = DateFormat('MMMM yyyy').parse(b);
        return bDate.compareTo(aDate); // Descending order
      });
    
    // Create a new map with the sorted keys
    final Map<String, List<Chore>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    
    return sortedGrouped;
  }

  Widget _buildCompactHistoryItem(
    BuildContext context, 
    Chore chore, 
    UserState userState
  ) {
    // Find the child name if available
    String? childName;
    if (chore.completedBy != null) {
      final child = userState.getChildById(chore.completedBy!);
      childName = child?.name;
    }
    
    // Get priority color
    final priorityColor = _getPriorityColor(chore.priority);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withOpacity(0.2),
          child: Icon(
            Icons.check_circle,
            color: priorityColor,
          ),
        ),
        title: Text(
          chore.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chore.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                chore.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '${chore.pointValue} points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                if (chore.completedAt != null) ...[
                  Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d').format(chore.completedAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
            if (childName != null && childId == null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.purple.shade700),
                  const SizedBox(width: 4),
                  Text(
                    childName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8, 
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            chore.priority.toUpperCase(),
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
} 