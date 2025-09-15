// lib/widgets/enhanced_chore_card.dart
import 'package:flutter/material.dart';
import '../models/chore.dart';
import 'enhanced_confetti_widget.dart';
import 'error_widget.dart';

class EnhancedChoreCard extends StatefulWidget {
  final Chore chore;
  final bool isChild;
  final Function(String)? onToggleComplete;
  final Function(String, String, int)? onApprove;
  final Function(Chore)? onAssign;

  const EnhancedChoreCard({
    Key? key,
    required this.chore,
    this.isChild = false,
    this.onToggleComplete,
    this.onApprove,
    this.onAssign,
  }) : super(key: key);

  @override
  State<EnhancedChoreCard> createState() => _EnhancedChoreCardState();
}

class _EnhancedChoreCardState extends State<EnhancedChoreCard> 
    with TickerProviderStateMixin {
  bool _showConfetti = false;
  late AnimationController _pulseController;
  late AnimationController _completionController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.green.withOpacity(0.1),
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeOut,
    ));
    
    // Start pulse animation for high priority chores
    if (widget.chore.priority == 'high' && !widget.chore.isCompleted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  void _handleChoreCompletion() {
    setState(() {
      _showConfetti = true;
    });
    
    _completionController.forward();
    _pulseController.stop();
    
    // Call the completion callback after a brief delay to show the animation
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        widget.onToggleComplete?.call(widget.chore.id);
              } catch (e) {
          if (mounted) {
            AppSnackBar.showError(context, 'Failed to update chore. Please try again.');
          }
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedConfettiWidget(
      showConfetti: _showConfetti,
      onConfettiComplete: () {
        setState(() {
          _showConfetti = false;
        });
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _completionController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: widget.chore.priority == 'high' ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _getBorderColor(),
                    width: widget.chore.priority == 'high' ? 2.0 : 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      if (widget.chore.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.chore.description,
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.chore.priority == 'high')
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.priority_high,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.chore.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  if (widget.chore.priority == 'high') _buildPriorityTag(),
                  if (widget.chore.isPendingApproval) _buildStatusTag(
                    'Awaiting Approval',
                    Colors.orange,
                    Icons.hourglass_top,
                  ),
                  if (widget.chore.assignedTo.isNotEmpty && !widget.chore.isPendingApproval && !widget.chore.isCompleted)
                    _buildStatusTag(
                      'Assigned: ${widget.chore.assignedTo.length}',
                      Colors.blue,
                      Icons.person,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildActionButton(),
      ],
    );
  }

  Widget _buildPriorityTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.flash_on,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          const Text(
            'High Priority',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final bool isPastDue = widget.chore.deadline.isBefore(DateTime.now());
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.chore.pointValue > 0) 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade100, Colors.amber.shade200],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.chore.pointValue} points',
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),
          
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isPastDue ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPastDue ? Colors.red.shade200 : Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isPastDue ? Colors.red.shade700 : Colors.blue.shade700,
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Due: ${widget.chore.deadline.year}-${widget.chore.deadline.month.toString().padLeft(2, '0')}-${widget.chore.deadline.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isPastDue ? Colors.red.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: isPastDue ? Colors.red.shade700 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.chore.deadline.hour.toString().padLeft(2, '0')}:${widget.chore.deadline.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isPastDue ? Colors.red.shade700 : Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    // If it's the child view and chore is not completed or pending approval
    if (widget.isChild && !widget.chore.isCompleted && !widget.chore.isPendingApproval) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          tooltip: 'Mark as completed',
          onPressed: _handleChoreCompletion,
        ),
      );
    }
    
    // If it's the parent view and chore is pending approval
    if (!widget.isChild && widget.chore.isPendingApproval && widget.onApprove != null) {
      return ElevatedButton.icon(
        onPressed: () {
          try {
            widget.onApprove!(widget.chore.id, widget.chore.completedBy!, widget.chore.pointValue);
                     } catch (e) {
             if (mounted) {
               AppSnackBar.showError(context, 'Failed to approve chore. Please try again.');
             }
           }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 3,
        ),
        icon: const Icon(Icons.approval, size: 16),
        label: const Text('Approve'),
      );
    }
    
    // If it's the parent view and chore is not completed or pending
    if (!widget.isChild && !widget.chore.isCompleted && !widget.chore.isPendingApproval && widget.onAssign != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: IconButton(
          icon: Icon(Icons.person_add, color: Colors.blue.shade700),
          tooltip: 'Assign to child',
          onPressed: () => widget.onAssign!(widget.chore),
        ),
      );
    }
    
    // For completed chores or pending chores in child view
    if (widget.chore.isPendingApproval && widget.isChild) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Icon(Icons.hourglass_top, color: Colors.orange.shade700),
      );
    }
    
    if (widget.chore.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Icon(Icons.check_circle, color: Colors.green.shade700),
      );
    }
    
    return const SizedBox.shrink();
  }

  Color _getBorderColor() {
    if (widget.chore.isCompleted) {
      return Colors.green;
    }
    
    if (widget.chore.isPendingApproval) {
      return Colors.orange;
    }
    
    if (widget.chore.priority == 'high') {
      return Colors.red;
    }
    
    return Colors.grey;
  }
}