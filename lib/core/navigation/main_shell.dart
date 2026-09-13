import 'package:flutter/material.dart';

import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/workouts/workouts_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Root app shell: bottom navigation with 4 tabs and a center
/// "quick start" floating action button, docked into the notch.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    WorkoutsScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _select(int index) => setState(() => _index = index);

  void _showQuickStart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Quick Start', style: AppTextStyles.h2),
                const SizedBox(height: 16),
                _quickStartTile(Icons.play_circle_fill_rounded, 'Start Empty Workout',
                    'Log sets and reps freely'),
                _quickStartTile(Icons.fitness_center_rounded, 'Choose from Library',
                    'Pick a pre-built routine'),
                _quickStartTile(Icons.timer_rounded, 'Start Timer',
                    'Simple stopwatch / interval timer'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickStartTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: AppColors.primaryGradient),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _showQuickStart,
            child: const Icon(Icons.bolt_rounded, color: AppColors.background, size: 30),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        padding: EdgeInsets.zero,
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Home', selected: _index == 0, onTap: () => _select(0)),
            _NavItem(icon: Icons.fitness_center_rounded, label: 'Workouts', selected: _index == 1, onTap: () => _select(1)),
            const SizedBox(width: 56),
            _NavItem(icon: Icons.show_chart_rounded, label: 'Progress', selected: _index == 2, onTap: () => _select(2)),
            _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: _index == 3, onTap: () => _select(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
