import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';

import '../theme.dart';

/// Wraps [child] and lets callers fire a confetti burst via a [GlobalKey].
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay> {
  final _controller = ConfettiController(duration: const Duration(seconds: 2));

  void burst() => _controller.play();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 24,
              maxBlastForce: 28,
              minBlastForce: 8,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                AppColors.coral,
                AppColors.cyan,
                AppColors.amber,
                AppColors.green,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
