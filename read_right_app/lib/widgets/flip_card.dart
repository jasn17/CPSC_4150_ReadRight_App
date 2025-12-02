import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlipCard extends StatefulWidget {
  final String word;
  final String sentence1;
  final String sentence2;

  final VoidCallback? onFrontTap; // NEW
  final VoidCallback? onBackTap; // NEW

  const FlipCard({
    super.key,
    required this.word,
    required this.sentence1,
    required this.sentence2,
    this.onFrontTap,
    this.onBackTap,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  bool _isShowingFront = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flip() async {
    if (_animationController.isAnimating) return;

    final wasFront = _isShowingFront;

    // Trigger the speech callback
    if (wasFront) {
      widget.onFrontTap?.call();
    } else {
      widget.onBackTap?.call();
    }

    // Different wait times
    final waitTime = wasFront ? 1 : 4;
    await Future.delayed(Duration(seconds: waitTime));

    // Flip
    if (wasFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    _isShowingFront = !_isShowingFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isShowingFront = _flipAnimation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flipAnimation.value * math.pi),
            child: Card(
              elevation: 8,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isShowingFront
                      ? Theme.of(context).colorScheme.inversePrimary
                      : Theme.of(context).colorScheme.secondary,
                ),
                child: isShowingFront ? _buildFrontSide() : _buildBackSide(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.word,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to hear word and see sentences',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.format_quote,
                size: 32,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                widget.sentence1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                widget.sentence2,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap to hear and go back',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
