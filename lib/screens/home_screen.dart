import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/reading_tools.dart';
import 'mystery_grid_screen.dart';
import 'pantry_settings_screen.dart';
import 'slot_machine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg, AppColors.bg2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🍎 SnackQuest',
                              style: AppText.inter(26, weight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Snack Game',
                                style: AppText.inter(11, color: AppColors.cyan)),
                          ),
                        ],
                      ),
                    ),
                    const ReadToMeButton(),
                    CupertinoButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        showPantrySheet(context);
                      },
                      child: const Icon(CupertinoIcons.gear_alt_fill,
                          size: 28, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _mode,
                    backgroundColor: AppColors.surface,
                    thumbColor: AppColors.coral,
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('🎰 Slot Machine', style: AppText.inter(14)),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('🎁 Mystery Grid', style: AppText.inter(14)),
                      ),
                    },
                    onValueChanged: (v) {
                      if (v == null) return;
                      HapticFeedback.selectionClick();
                      setState(() => _mode = v);
                    },
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _mode,
                  children: const [SlotMachineScreen(), MysteryGridScreen()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
