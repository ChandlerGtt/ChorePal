import 'package:flutter/material.dart';
import '../models/milestone.dart';
import 'package:confetti/confetti.dart';

class MilestoneCelebrationDialog extends StatefulWidget {
  final Milestone milestone;
  final int currentPoints;

  const MilestoneCelebrationDialog({
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
      builder: (context) => MilestoneCelebrationDialog(
        milestone: milestone,
        currentPoints: currentPoints,
      ),
    );
  }

  @override
  State<MilestoneCelebrationDialog> createState() => _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    // Start the confetti animation when the dialog appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti animation
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            colors: [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.purple,
              Colors.orange,
            ],
          ),
        ),
        // Dialog content
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              '🎉 Milestone Achieved! 🎉',
              style: TextStyle(
                color: widget.milestone.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.milestone.icon,
                size: 64,
                color: widget.milestone.color,
              ),
              const SizedBox(height: 16),
              Text(
                widget.milestone.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.milestone.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Current Points: ${widget.currentPoints}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.milestone.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 