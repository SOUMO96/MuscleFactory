import 'package:flutter/material.dart';

import '../../features/classes/classes_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/train/train_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme_controller.dart';
import 'main_tab_controller.dart';

/// Root shell with five bottom tabs: Home, Train, Classes, Progress, Me.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    TrainScreen(),
    ClassesScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _select(int index) => setState(() => _index = index);

  @override
  void initState() {
    super.initState();
    MainTabController.instance.addListener(_onTabRequested);
    // AppColors is read through static getters, not Theme.of(context), so built
    // widgets can't tell when the theme changes. Keying the IndexedStack on
    // brightness rebuilds the whole subtree and picks up the new colors without
    // touching navigation state.
    AppThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    MainTabController.instance.removeListener(_onTabRequested);
    AppThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onTabRequested() => _select(MainTabController.instance.requestedIndex);
  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey(AppThemeController.instance.resolvedBrightness),
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(icon: Icons.home_outlined, label: 'Home', selected: _index == 0, onTap: () => _select(0)),
                _NavItem(icon: Icons.bolt_outlined, label: 'Train', selected: _index == 1, onTap: () => _select(1)),
                _NavItem(icon: Icons.calendar_month_outlined, label: 'Classes', selected: _index == 2, onTap: () => _select(2)),
                _NavItem(icon: Icons.show_chart_rounded, label: 'Progress', selected: _index == 3, onTap: () => _select(3)),
                _NavItem(icon: Icons.person_outline_rounded, label: 'Me', selected: _index == 4, onTap: () => _select(4)),
              ],
            ),
          ),
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: selected ? AppColors.primary : Colors.transparent, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 9, bottom: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: color, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
