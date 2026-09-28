import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Placeholder for the Classes tab -- the real booking flow (schedule,
/// book/cancel/waitlist against seeded classes) lands once the backing
/// Supabase tables exist. Kept visually consistent with the rest of the
/// app rather than a bare "TODO" screen in the meantime.
class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_outlined, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('Classes', style: AppTextStyles.h1, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Class booking is coming soon.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
