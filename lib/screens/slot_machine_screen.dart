import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/slot_reel.dart';
import '../models/snack_item.dart';
import '../providers/pantry_provider.dart';
import '../theme.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/custom_button.dart';
import '../services/speech.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/reading_tools.dart';

class SlotMachineScreen extends StatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  State<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends State<SlotMachineScreen> {
  final _rng = Random();
  final _confetti = GlobalKey<ConfettiOverlayState>();
  final _reelKeys = List.generate(3, (_) => GlobalKey<_ReelViewState>());
  bool _spinning = false;
  List<SnackItem>? _result;
  int _spins = 0;

  Future<void> _spin(List<List<SnackItem>> pools) async {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _result = null;
    });
    final picks = [for (final p in pools) _rng.nextInt(p.length)];
    await Future.wait([
      for (var i = 0; i < 3; i++)
        _reelKeys[i].currentState!.spinTo(
              picks[i],
              Duration(milliseconds: 1800 + i * 700),
            ),
    ]);
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _spinning = false;
      _spins++;
      _result = [for (var i = 0; i < 3; i++) pools[i][picks[i]]];
    });
    Speech.instance.auto('Your snack! ${_result!.map((e) => e.name).join(', ')}');
  }

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    final pools = [for (final r in SlotReel.reels) pantry.itemsFor(r.category)];
    final canSpin = pools.every((p) => p.isNotEmpty);

    return ConfettiOverlay(
      key: _confetti,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassmorphicCard(
            glow: AppColors.cyan,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        TapToHear(SlotReel.reels[i].title,
                            showSpeaker: false,
                            minSize: 20,
                            align: TextAlign.center,
                            style: AppText.inter(22,
                                weight: FontWeight.w800,
                                color: AppColors.cyan)),
                        const SizedBox(height: 8),
                        _ReelView(
                          key: _reelKeys[i],
                          items: pools[i],
                          fallbackEmoji: SlotReel.reels[i].icon,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!canSpin)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Add a snack to each one in the Pantry ⚙️',
                  textAlign: TextAlign.center,
                  style: AppText.inter(13, color: AppColors.amber)),
            ),
          CustomButton(
            label: _spinning ? 'SPIN…' : 'SPIN!',
            icon: CupertinoIcons.sparkles,
            onPressed: canSpin && !_spinning ? () => _spin(pools) : null,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('SPINS ${_spins.toString().padLeft(3, '0')}',
                style: AppText.mono(12, color: AppColors.muted)),
          ),
          const SizedBox(height: 16),
          if (_result != null)
            _ResultCard(
              result: _result!,
              onEat: () {
                HapticFeedback.heavyImpact();
                _confetti.currentState?.burst();
              },
            ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.elasticOut).fadeIn(duration: 200.ms),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onEat});

  final List<SnackItem> result;
  final VoidCallback onEat;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      glow: AppColors.green,
      child: Column(
        children: [
          Text('🎉 Your Snack!', style: AppText.inter(20, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(result.map((e) => e.emoji).join('  '),
              style: const TextStyle(fontSize: 40, decoration: TextDecoration.none)),
          const SizedBox(height: 12),
          for (final s in result)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: WordCard(emoji: s.emoji, word: s.name),
            ),
          const SizedBox(height: 16),
          CustomButton(
              label: "Let's Eat!", color: AppColors.green, onPressed: onEat),
        ],
      ),
    );
  }
}

class _ReelView extends StatefulWidget {
  const _ReelView({super.key, required this.items, required this.fallbackEmoji});

  final List<SnackItem> items;
  final String fallbackEmoji;

  @override
  State<_ReelView> createState() => _ReelViewState();
}

class _ReelViewState extends State<_ReelView>
    with SingleTickerProviderStateMixin {
  static const double _itemH = 104;
  static const double _windowH = _itemH * 3;

  late final AnimationController _c =
      AnimationController(vsync: this);
  double _pos = 0;
  double _from = 0;
  double _to = 0;
  Curve _curve = Curves.linear;
  int _lastTick = 0;
  

  int get _n => max(widget.items.length, 1);

  Future<void> spinTo(int index, Duration duration) {
    final n = _n;
    var target = _pos.ceil() + n * (3 + (duration.inMilliseconds ~/ 700));
    target += ((index - target) % n + n) % n;
    _from = _pos;
    _to = target.toDouble();
    _curve = Curves.easeOutBack;
    _lastTick = _pos.floor();
    final completer = Completer<void>();

    _c.duration = duration;
    _c.forward(from: 0).whenComplete(() {
      _pos = _to;
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
      if (mounted) setState(() {});
      completer.complete();
    });
    return completer.future;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        if (_c.isAnimating) {
          _pos = _from + (_to - _from) * _curve.transform(t);
          final tick = _pos.floor();
          if (tick != _lastTick) {
            _lastTick = tick;
            HapticFeedback.selectionClick();
          }
        }
        final blur = _c.isAnimating ? 5.0 * (1 - t).clamp(0.0, 1.0) : 0.0;
        final items = widget.items;
        final base = _pos.floor();

        Widget strip = Stack(
          children: [
            for (var i = base - 2; i <= base + 2; i++)
              Positioned(
                left: 0,
                right: 0,
                top: _windowH / 2 - _itemH / 2 + (i - _pos) * _itemH,
                height: _itemH,
                child: _cell(items, i, (i - _pos).abs()),
              ),
          ],
        );
        if (blur > 0.2) {
          strip = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaY: blur, sigmaX: 0),
            child: strip,
          );
        }

        return Container(
          height: _windowH,
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: _itemH,
                  height: _itemH,
                  child: Container(color: AppColors.cyan.withValues(alpha: 0.12)),
                ),
                strip,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cell(List<SnackItem> items, int i, double dist) {
    final opacity = (1 - dist * 0.45).clamp(0.15, 1.0);
    if (items.isEmpty) {
      return Center(
          child: Text(widget.fallbackEmoji,
              style: const TextStyle(fontSize: 30, decoration: TextDecoration.none)));
    }
    final item = items[((i % items.length) + items.length) % items.length];
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji,
              style: const TextStyle(fontSize: 34, decoration: TextDecoration.none)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(item.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: AppText.inter(16, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
