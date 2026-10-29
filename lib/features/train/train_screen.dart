import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'history_view.dart';
import 'library_view.dart';
import 'plans_view.dart';

/// The Train tab: Plans (default), Library and History.
class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  int _tab = 0;
  static const _labels = ['Plans', 'Library', 'History'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text('Train', style: AppTextStyles.h1.copyWith(fontSize: 24)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                child: Row(
                  children: List.generate(_labels.length, (i) {
                    final selected = i == _tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          color: selected ? AppColors.primary : Colors.transparent,
                          child: Text(
                            _labels[i],
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: selected ? AppColors.background : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => const PlansView(),
                1 => const LibraryView(),
                _ => const HistoryView(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
