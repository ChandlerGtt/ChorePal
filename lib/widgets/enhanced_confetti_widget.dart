// lib/widgets/enhanced_confetti_widget.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class EnhancedConfettiWidget extends StatefulWidget {
  final Widget child;
  final bool showConfetti;
  final VoidCallback? onConfettiComplete;

  const EnhancedConfettiWidget({
    Key? key,
    required this.child,
    this.showConfetti = false,
    this.onConfettiComplete,
  }) : super(key: key);

  @override
  State<EnhancedConfettiWidget> createState() => _EnhancedConfettiWidgetState();
}

class _EnhancedConfettiWidgetState extends State<EnhancedConfettiWidget>
    with TickerProviderStateMixin {
  late ConfettiController _confettiControllerCenter;
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize confetti controllers
    _confettiControllerCenter = ConfettiController(duration: const Duration(seconds: 3));
    _confettiControllerLeft = ConfettiController(duration: const Duration(seconds: 2));
    _confettiControllerRight = ConfettiController(duration: const Duration(seconds: 2));
    
    // Initialize celebration animation controller
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Scale animation for the celebration effect
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));
    
    // Bounce animation
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));
    
    // Add completion listener
    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onConfettiComplete?.call();
        _celebrationController.reset();
      }
    });
  }

  @override
  void didUpdateWidget(EnhancedConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _startCelebration();
    }
  }

  @override
  void dispose() {
    _confettiControllerCenter.dispose();
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _startCelebration() {
    // Start all confetti controllers with slight delays for a cascading effect
    _confettiControllerCenter.play();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _confettiControllerLeft.play();
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _confettiControllerRight.play();
    });
    
    // Start the celebration animation
    _celebrationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main content with celebration animation
        AnimatedBuilder(
          animation: _celebrationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.translate(
                offset: Offset(0, -20 * _bounceAnimation.value),
                child: widget.child,
              ),
            );
          },
        ),
        
        // Center confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiControllerCenter,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.15,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.red,
              Colors.yellow,
            ],
            strokeWidth: 1,
            strokeColor: Colors.white,
          ),
        ),
        
        // Left confetti cannon
        Positioned(
          left: 0,
          top: MediaQuery.of(context).size.height * 0.3,
          child: ConfettiWidget(
            confettiController: _confettiControllerLeft,
            blastDirection: -3.14 / 4, // 45 degrees to the right
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.amber,
              Colors.deepOrange,
              Colors.teal,
              Colors.indigo,
            ],
          ),
        ),
        
        // Right confetti cannon
        Positioned(
          right: 0,
          top: MediaQuery.of(context).size.height * 0.3,
          child: ConfettiWidget(
            confettiController: _confettiControllerRight,
            blastDirection: -3.14 * 3 / 4, // 45 degrees to the left
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.lightBlue,
              Colors.lightGreen,
              Colors.pinkAccent,
              Colors.deepPurple,
            ],
          ),
        ),
        
        // Success overlay effect
        if (widget.showConfetti)
          AnimatedBuilder(
            animation: _celebrationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.2 * (1 - _celebrationController.value),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
      ],
    );
  }
}