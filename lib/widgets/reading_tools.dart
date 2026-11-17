import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../services/speech.dart';
import '../theme.dart';

/// Big words with a dot under each one. Tap a word to hear it; tap the
/// speaker to hear the whole line, with the dots lighting up one by one.
class TapToHear extends StatefulWidget {
  const TapToHear(this.text, {super.key, this.style, this.say, this.align, this.showSpeaker = true, this.minSize = 20});

  final String text;
  final TextStyle? style;
  final String? say;
  final TextAlign? align;
  final bool showSpeaker;
  final double minSize;

  @override
  State<TapToHear> createState() => _TapToHearState();
}

class _TapToHearState extends State<TapToHear> {
  int _active = -1;
  int _run = 0;

  List<String> get _words =>
      widget.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  String _clean(String w) => w.replaceAll(RegExp(r"[^A-Za-z0-9']"), '');

  Future<void> _word(int i) async {
    final run = ++_run;
    HapticFeedback.selectionClick();
    setState(() => _active = i);
    await Speech.instance.speak(_clean(_words[i]));
    if (mounted && run == _run) setState(() => _active = -1);
  }

  Future<void> _all() async {
    final run = ++_run;
    HapticFeedback.selectionClick();
    final words = _words;
    for (var i = 0; i < words.length; i++) {
      if (!mounted || run != _run) return;
      setState(() => _active = i);
      await Speech.instance.speak(_clean(words[i]), rate: 0.38);
    }
    if (mounted && run == _run) setState(() => _active = -1);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style ?? AppText.inter(20, weight: FontWeight.w700);
    final style = base.copyWith(fontSize: (base.fontSize ?? 18).clamp(widget.minSize, 40));
    final words = _words;
    final wrapAlign = widget.align == TextAlign.center
        ? WrapAlignment.center
        : WrapAlignment.start;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Wrap(
            alignment: wrapAlign,
            spacing: 10,
            runSpacing: 4,
            children: [
              for (var i = 0; i < words.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _word(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(words[i],
                          maxLines: 1,
                          softWrap: false,
                          style: style.copyWith(
                              color: _active == i ? AppColors.amber : null)),
                      const SizedBox(height: 2),
                      _Dot(on: _active == i, size: 10),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (widget.showSpeaker)
          CupertinoButton(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(44, 44),
          onPressed: _all,
          child: const Icon(CupertinoIcons.speaker_2_fill,
              size: 26, color: AppColors.cyan),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.on, required this.size});
  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: on ? size * 1.5 : size,
      height: on ? size * 1.5 : size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColors.amber : AppColors.cyan,
      ),
    );
  }
}

/// A big picture and word with a dot under each word. "Sound it out" says
/// each letter, then the whole word.
class WordCard extends StatefulWidget {
  const WordCard({super.key, required this.emoji, required this.word});

  final String emoji;
  final String word;

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  int _active = -1;
  int _run = 0;

  Future<void> _soundOut() async {
    final run = ++_run;
    HapticFeedback.selectionClick();
    for (var i = 0; i < widget.word.length; i++) {
      if (!mounted || run != _run) return;
      if (widget.word[i] == ' ') continue;
      setState(() => _active = i);
      await Speech.instance.speak(widget.word[i], rate: 0.3);
    }
    if (!mounted || run != _run) return;
    setState(() => _active = -1);
    await Speech.instance.speak(widget.word, rate: 0.4);
  }

  Future<void> _say() async {
    ++_run;
    HapticFeedback.selectionClick();
    setState(() => _active = -1);
    await Speech.instance.speak(widget.word, rate: 0.4);
  }

  Widget _pill(String label, IconData icon, Color color, VoidCallback onTap) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: const Size(44, 44),
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(22),
      onPressed: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
    );
  }

  // Whole words, one dot under each; the active letter lights up in amber.
  Widget _words(String word) {
    var offset = 0;
    final parts = word.split(' ');
    final kids = <Widget>[];
    for (final w in parts) {
      final start = offset;
      offset += w.length + 1;
      kids.add(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(children: [
              for (var i = 0; i < w.length; i++)
                TextSpan(
                    text: w[i],
                    style: TextStyle(
                        color: _active == start + i
                            ? AppColors.amber
                            : AppColors.text)),
            ]),
            maxLines: 1,
            softWrap: false,
            style: AppText.inter(30, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          _Dot(on: _active >= start && _active < start + w.length, size: 10),
        ],
      ));
    }
    return Wrap(spacing: 12, runSpacing: 4, children: kids);
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.emoji,
                style: const TextStyle(
                    fontSize: 40, decoration: TextDecoration.none)),
            const SizedBox(width: 14),
            Expanded(child: _words(word)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _pill('Say it', CupertinoIcons.speaker_2_fill, AppColors.cyan, _say),
            const SizedBox(width: 10),
            _pill('Sound it out', CupertinoIcons.ellipsis, AppColors.amber,
                _soundOut),
          ],
        ),
      ],
    );
  }
}

/// Header switch for automatic read-aloud.
class ReadToMeButton extends StatelessWidget {
  const ReadToMeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Speech.instance,
      builder: (context, _) {
        final on = Speech.instance.autoRead;
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onPressed: () {
            HapticFeedback.selectionClick();
            Speech.instance.toggleAutoRead();
          },
          child: Icon(
            on ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_slash_fill,
            size: 28,
            color: on ? AppColors.cyan : AppColors.muted,
          ),
        );
      },
    );
  }
}
