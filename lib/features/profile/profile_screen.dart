import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_controller.dart';
import '../../core/widgets/stat_card.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/workout_session.dart';
import '../auth/login_screen.dart';
import 'personal_information_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: user == null
            ? const SizedBox.shrink()
            : StreamBuilder<AppUser?>(
                stream: UserRepository.instance.watchUserProfile(user.id),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final displayName = (profile?.displayName.trim().isNotEmpty ?? false) ? profile!.displayName : 'Athlete';
                  final email = profile?.email ?? user.email ?? '';
                  final initials = displayName
                      .trim()
                      .split(RegExp(r'\s+'))
                      .where((part) => part.isNotEmpty)
                      .take(2)
                      .map((part) => part[0].toUpperCase())
                      .join();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    children: [
                      Text('Me', style: AppTextStyles.h1.copyWith(fontSize: 24)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            color: AppColors.primary,
                            alignment: Alignment.center,
                            child: Text(
                              initials.isEmpty ? '?' : initials,
                              style: AppTextStyles.h1.copyWith(color: AppColors.background, fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: AppTextStyles.h2),
                                const SizedBox(height: 2),
                                Text(email, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          if (profile != null)
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PersonalInformationScreen(profile: profile)),
                              ),
                              child: Text('Edit', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      if (profile != null && profile.surveyCompleted) ...[
                        const SizedBox(height: 28),
                        Text('FITNESS PROFILE', style: AppTextStyles.caption),
                        const SizedBox(height: 10),
                        _FitnessProfileCard(profile: profile),
                      ],
                      const SizedBox(height: 24),
                      _ProfileStatsRow(userId: user.id),
                      const SizedBox(height: 28),
                      Text('ACCOUNT', style: AppTextStyles.caption),
                      const SizedBox(height: 10),
                      _MenuCard(items: [
                        _MenuItemData(
                          icon: Icons.person_outline_rounded,
                          label: 'Personal Information',
                          onTap: profile == null
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => PersonalInformationScreen(profile: profile)),
                                  ),
                        ),
                        const _MenuItemData(icon: Icons.flag_outlined, label: 'Goals & Targets'),
                        const _MenuItemData(icon: Icons.emoji_events_outlined, label: 'Achievements'),
                      ]),
                      const SizedBox(height: 24),
                      Text('PREFERENCES', style: AppTextStyles.caption),
                      const SizedBox(height: 10),
                      if (profile != null) _PreferencesCard(uid: user.id, profile: profile),
                      const SizedBox(height: 24),
                      Text('SUPPORT', style: AppTextStyles.caption),
                      const SizedBox(height: 10),
                      const _MenuCard(items: [
                        _MenuItemData(icon: Icons.help_outline_rounded, label: 'Help & Support'),
                        _MenuItemData(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy'),
                      ]),
                      const SizedBox(height: 28),
                      Material(
                        color: AppColors.card,
                        child: InkWell(
                          onTap: () async {
                            await AuthService.instance.signOut();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Log Out',
                                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Real workout/PR/streak counts computed from logged workout sessions and
/// sets, replacing the old hardcoded-0 "Followers" stat row (which never
/// made sense for a solo fitness app).
class _ProfileStatsRow extends StatefulWidget {
  const _ProfileStatsRow({required this.userId});
  final String userId;

  @override
  State<_ProfileStatsRow> createState() => _ProfileStatsRowState();
}

class _ProfileStatsRowState extends State<_ProfileStatsRow> {
  int _workouts = 0;
  int _prs = 0;
  int _streak = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      WorkoutSessionRepository.instance.history(widget.userId, limit: 500),
      WorkoutSessionRepository.instance.recentSets(widget.userId, since: DateTime.now().subtract(const Duration(days: 366))),
    ]);
    final sessions = results[0] as List<WorkoutSession>;
    final sets = results[1] as List<LoggedSet>;

    final bestByExercise = <String, double>{};
    for (final s in sets) {
      final name = s.exerciseName;
      if (name == null || s.weightKg == null) continue;
      if (s.weightKg! > (bestByExercise[name] ?? 0)) bestByExercise[name] = s.weightKg!;
    }

    final finishedDays = sessions
        .where((s) => s.isFinished)
        .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
        .toSet();
    var streak = 0;
    var day = DateTime.now();
    while (finishedDays.contains(DateTime(day.year, day.month, day.day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    if (!mounted) return;
    setState(() {
      _workouts = sessions.where((s) => s.isFinished).length;
      _prs = bestByExercise.length;
      _streak = streak;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 68);
    return StatRow(
      children: [
        StatCell(value: '$_workouts', label: 'Workouts'),
        StatCell(value: '$_prs', label: 'PRs set'),
        StatCell(value: '$_streak', label: 'Day streak'),
      ],
    );
  }
}

class _FitnessProfileCard extends StatelessWidget {
  const _FitnessProfileCard({required this.profile});
  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final heightCm = profile.heightCm;
    final totalInches = heightCm == null ? null : heightCm / 2.54;
    final heightText = heightCm == null
        ? '—'
        : '${heightCm.round()} cm (${(totalInches! ~/ 12)}\'${(totalInches % 12).round()}")';

    return Container(
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _FactTile(icon: Icons.cake_outlined, label: 'Age', value: '${profile.age ?? '—'}')),
              const _VerticalDivider(),
              Expanded(child: _FactTile(icon: Icons.wc_rounded, label: 'Gender', value: profile.gender ?? '—')),
            ],
          ),
          Divider(height: 1, color: AppColors.divider),
          Row(
            children: [
              Expanded(child: _FactTile(icon: Icons.height_rounded, label: 'Height', value: heightText)),
              const _VerticalDivider(),
              Expanded(
                child: _FactTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Weight',
                  value: profile.currentWeightKg == null ? '—' : '${profile.currentWeightKg!.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
          Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  color: AppColors.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.flag_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.goal?.label ?? '—', style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(
                        profile.targetWeightKg == null
                            ? 'No target set'
                            : 'Target ${profile.targetWeightKg!.toStringAsFixed(1)} kg'
                                '${profile.goalDurationWeeks != null ? ' in ${profile.goalDurationWeeks} weeks' : ''}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.h3),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.divider);
  }
}

class _MenuItemData {
  const _MenuItemData({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.divider)),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        color: AppColors.surfaceVariant,
                        child: Icon(item.icon, size: 19, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(item.label, style: AppTextStyles.bodyLarge)),
                      Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (i != items.length - 1) Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
            ],
          );
        }),
      ),
    );
  }
}

/// Real Settings section: units, appearance (wired to AppThemeController),
/// workout reminders, default rest timer -- all persisted to the profile
/// via UserRepository.updateSettings.
class _PreferencesCard extends StatefulWidget {
  const _PreferencesCard({required this.uid, required this.profile});
  final String uid;
  final AppUser profile;

  @override
  State<_PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<_PreferencesCard> {
  late UnitPreference _unit = widget.profile.unitPreference;
  late ThemePreference _theme = widget.profile.themePreference;
  late bool _reminders = widget.profile.workoutRemindersEnabled;
  late int _restSeconds = widget.profile.defaultRestSeconds;

  static const _restOptions = [30, 60, 90, 120, 150, 180];

  void _setUnit(UnitPreference unit) {
    setState(() => _unit = unit);
    UserRepository.instance.updateSettings(uid: widget.uid, unitPreference: unit);
  }

  void _setTheme(ThemePreference theme) {
    setState(() => _theme = theme);
    UserRepository.instance.updateSettings(uid: widget.uid, themePreference: theme);
    AppThemeController.instance.setMode(switch (theme) {
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.system => ThemeMode.system,
    });
  }

  void _setReminders(bool value) {
    setState(() => _reminders = value);
    UserRepository.instance.updateSettings(uid: widget.uid, workoutRemindersEnabled: value);
  }

  void _cycleRest() {
    final next = _restOptions[(_restOptions.indexOf(_restSeconds) + 1) % _restOptions.length];
    setState(() => _restSeconds = next);
    UserRepository.instance.updateSettings(uid: widget.uid, defaultRestSeconds: next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          _row(
            label: 'Units',
            trailing: _Segmented(
              options: const ['kg', 'lb'],
              selectedIndex: _unit == UnitPreference.kg ? 0 : 1,
              onSelected: (i) => _setUnit(i == 0 ? UnitPreference.kg : UnitPreference.lb),
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          _row(
            label: 'Appearance',
            trailing: _Segmented(
              options: const ['Light', 'Dark', 'Auto'],
              selectedIndex: switch (_theme) { ThemePreference.light => 0, ThemePreference.dark => 1, ThemePreference.system => 2 },
              onSelected: (i) => _setTheme([ThemePreference.light, ThemePreference.dark, ThemePreference.system][i]),
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          _row(
            label: 'Workout reminders',
            trailing: Switch(
              value: _reminders,
              onChanged: _setReminders,
              activeThumbColor: AppColors.background,
              activeTrackColor: AppColors.primary,
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          _row(
            label: 'Default rest timer',
            trailing: GestureDetector(
              onTap: _cycleRest,
              child: Text('${_restSeconds}s', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({required String label, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          trailing,
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.options, required this.selectedIndex, required this.onSelected});
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: selected ? AppColors.primary : Colors.transparent,
              child: Text(
                options[i],
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.background : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
