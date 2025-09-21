// lib/widgets/enhanced_milestone_dialog.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/milestone.dart';

class EnhancedMilestoneCelebrationDialog extends StatefulWidget {
  final Milestone milestone;
  final int currentPoints;

  const EnhancedMilestoneCelebrationDialog({
    Key? key,
    required this.milestone,
    required this.currentPoints,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, 
    Milestone milestone, 
    int currentPoints
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedMilestoneCelebrationDialog(
        milestone: milestone,
        currentPoints: currentPoints,
      ),
    );
  }

  @override
  State<EnhancedMilestoneCelebrationDialog> createState() => _EnhancedMilestoneCelebrationDialogState();
}

class _EnhancedMilestoneCelebrationDialogState extends State<EnhancedMilestoneCelebrationDialog>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 8));
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _scaleController.forward();
      _rotationController.repeat();
      _sparkleController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background overlay
        Container(
          color: Colors.black.withValues(alpha: 0.7),
        ),
        
        // Multiple confetti widgets for different effects
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.03,
            numberOfParticles: 100,
            gravity: 0.1,
            colors: [
              widget.milestone.color,
              widget.milestone.color.withValues(alpha: 0.7),
              Colors.yellow,
              Colors.orange,
              Colors.pink,
              Colors.purple,
            ],
            strokeWidth: 2,
            strokeColor: Colors.white,
          ),
        ),
        
        // Dialog content
        Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.milestone.color.withValues(alpha: 0.9),
                          widget.milestone.color.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.milestone.color.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Celebration header
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Sparkle effects around the icon
                            AnimatedBuilder(
                              animation: _sparkleAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _sparkleAnimation.value,
                                  child: _buildSparkles(),
                                );
                              },
                            ),
                            
                            // Main milestone icon
                            AnimatedBuilder(
                              animation: _rotationAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotationAnimation.value * 3.14159,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.milestone.color.withValues(alpha: 0.5),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      widget.milestone.icon,
                                      size: 64,
                                      color: widget.milestone.color,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Celebration text
                        Text(
                          '🎉 Milestone Achieved! 🎉',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          widget.milestone.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.milestone.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Points display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade300,
                                Colors.amber.shade500,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Total Points: ${widget.currentPoints}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: widget.milestone.color,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Amazing! 🌟',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSparkles() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 20,
            child: _buildSparkle(Colors.yellow, 8),
          ),
          Positioned(
            top: 30,
            right: 15,
            child: _buildSparkle(Colors.pink, 6),
          ),
          Positioned(
            bottom: 20,
            left: 15,
            child: _buildSparkle(Colors.blue, 10),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: _buildSparkle(Colors.purple, 7),
          ),
          Positioned(
            top: 60,
            left: 5,
            child: _buildSparkle(Colors.orange, 5),
          ),
          Positioned(
            bottom: 60,
            right: 5,
            child: _buildSparkle(Colors.green, 9),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSparkle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}