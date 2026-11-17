import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/snack_item.dart';
import '../providers/pantry_provider.dart';
import '../theme.dart';
import '../widgets/confetti_overlay.dart';
import '../services/speech.dart';
import '../widgets/custom_button.dart';
import '../widgets/reading_tools.dart';

class MysteryGridScreen extends StatefulWidget {
  const MysteryGridScreen({super.key});

  @override
  State<MysteryGridScreen> createState() => _MysteryGridScreenState();
}

class _MysteryGridScreenState extends State<MysteryGridScreen> {
  final _rng = Random();
  final _confetti = GlobalKey<ConfettiOverlayState>();
  // Snacks are dealt from the live pantry when a box is picked.
  List<SnackItem> _dealt = [];
  int? _picked;

  void _pick(int index, List<SnackItem> pool) {
    if (_picked != null || pool.isEmpty) return;
    HapticFeedback.lightImpact();
    final names = <String>{};
    final unique = [for (final i in pool) if (names.add(i.name)) i]..shuffle(_rng);
    // Distinct snacks where the pantry allows; repeat only if fewer than 9.
    final dealt = [for (var i = 0; i < 9; i++) unique[i % unique.length]];
    setState(() {
      _dealt = dealt;
      _picked = index;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        _confetti.currentState?.burst();
        Speech.instance.auto('You got ${dealt[index].name}!');
      }
    });
  }

  void _reset() => setState(() {
        _picked = null;
        _dealt = [];
      });

  @override
  Widget build(BuildContext context) {
    final pool = context.watch<PantryProvider>().pool;

    return ConfettiOverlay(
      key: _confetti,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            TapToHear(
                _picked == null
                    ? 'Pick a box!'
                    : 'You got ${_dealt[_picked!].name}!',
                align: TextAlign.center,
                style: AppText.inter(22, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_picked == null ? 'PICK 1 BOX' : 'YAY!',
                style: AppText.mono(12, color: AppColors.muted)),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < 9; i++)
                        _FlipTile(
                          revealed: _picked == i,
                          snack: _picked == null ? null : _dealt[i],
                          onTap: () => _pick(i, pool),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: _picked == null ? 'Start Over' : 'Play Again',
              icon: CupertinoIcons.arrow_2_circlepath,
              color: AppColors.amber,
              onPressed: _reset,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipTile extends StatelessWidget {
  const _FlipTile({required this.revealed, required this.snack, required this.onTap});

  final bool revealed;
  final SnackItem? snack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: revealed ? pi : 0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        builder: (context, angle, _) {
          final showBack = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _face(
                      color: AppColors.green,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(snack?.emoji ?? '❓',
                              style: const TextStyle(
                                  fontSize: 34, decoration: TextDecoration.none)),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(snack?.name ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.inter(11, weight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  )
                : _face(
                    color: AppColors.coral,
                    child: const Text('🎁',
                        style: TextStyle(fontSize: 38, decoration: TextDecoration.none)),
                  ),
          );
        },
      ),
    );
  }

  Widget _face({required Color color, required Widget child}) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.35), AppColors.surface],
        ),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16)],
      ),
      child: child,
    );
  }
}
