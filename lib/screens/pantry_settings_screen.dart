import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/snack_item.dart';
import '../providers/pantry_provider.dart';
import '../theme.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/reading_tools.dart';

Future<void> showPantrySheet(BuildContext context) {
  final pantry = context.read<PantryProvider>();
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: pantry,
      child: const PantrySettingsScreen(),
    ),
  );
}

class PantrySettingsScreen extends StatefulWidget {
  const PantrySettingsScreen({super.key});

  @override
  State<PantrySettingsScreen> createState() => _PantrySettingsScreenState();
}

class _PantrySettingsScreenState extends State<PantrySettingsScreen> {
  final _controller = TextEditingController();
  SnackCategory _category = SnackCategory.crunch;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final pantry = context.read<PantryProvider>();
    final allergen = await pantry.add(text, _category);
    if (!mounted) return;
    if (allergen != null) {
      HapticFeedback.heavyImpact();
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Stop! ⚠️'),
          content: Text('${text.trim()} has $allergen in it. '
              'It is not safe to eat.'),
          actions: [
            CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    final height = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _confirmReset(context),
                    child: Text('Put Back',
                        style: AppText.inter(15, color: AppColors.amber)),
                  ),
                  Expanded(
                    child: Text('🧺 Pantry',
                        textAlign: TextAlign.center,
                        style: AppText.inter(18, weight: FontWeight.w800)),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Done',
                        style: AppText.inter(15, color: AppColors.cyan)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  CupertinoSlidingSegmentedControl<SnackCategory>(
                    groupValue: _category,
                    backgroundColor: AppColors.surface,
                    thumbColor: AppColors.cyan,
                    children: {
                      for (final c in SnackCategory.values)
                        c: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: Text(c.label, style: AppText.inter(12)),
                        ),
                    },
                    onValueChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _controller,
                          placeholder: 'Add a snack',
                          placeholderStyle: AppText.inter(15,
                              weight: FontWeight.w400, color: AppColors.muted),
                          style: AppText.inter(15, weight: FontWeight.w500),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _add(),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.only(left: 8),
                        onPressed: _add,
                        child: const Icon(CupertinoIcons.add_circled_solid,
                            size: 34, color: AppColors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  for (final c in SnackCategory.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text('${c.defaultEmoji}  ${c.label}'.toUpperCase(),
                          style: AppText.inter(12,
                              weight: FontWeight.w800, color: AppColors.muted)),
                    ),
                    GlassmorphicCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      radius: 16,
                      child: Column(
                        children: [
                          if (pantry.itemsFor(c).isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text('No snacks yet',
                                  style: AppText.inter(14,
                                      weight: FontWeight.w400,
                                      color: AppColors.muted)),
                            ),
                          for (final item in pantry.itemsFor(c))
                            Row(
                              children: [
                                Text(item.emoji,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        decoration: TextDecoration.none)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: TapToHear(item.name,
                                        style: AppText.inter(17,
                                            weight: FontWeight.w500))),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 4),
                                  minimumSize: Size.zero,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    pantry.remove(item.id);
                                  },
                                  child: const Icon(
                                      CupertinoIcons.minus_circle_fill,
                                      color: AppColors.coral),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Put back the first snacks?'),
        content: const Text('This will take away your new snacks.'),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              context.read<PantryProvider>().resetToDefaults();
              Navigator.pop(ctx);
            },
            child: const Text('Put Back'),
          ),
        ],
      ),
    );
  }
}
