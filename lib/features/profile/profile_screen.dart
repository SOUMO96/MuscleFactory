import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/app_user.dart';
import '../auth/login_screen.dart';

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
                stream: UserRepository.instance.watchUserProfile(user.uid),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final displayName = (profile?.displayName.trim().isNotEmpty ?? false)
                      ? profile!.displayName
                      : ((user.displayName?.trim().isNotEmpty ?? false) ? user.displayName! : 'Athlete');
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Profile', style: AppTextStyles.h1.copyWith(fontSize: 24)),
                          Material(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.settings_outlined, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: AppColors.primaryGradient),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials.isEmpty ? '?' : initials,
                                    style: AppTextStyles.display.copyWith(color: AppColors.background, fontSize: 30),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.background, width: 3),
                                    ),
                                    child: const Icon(Icons.edit_rounded, size: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(displayName, style: AppTextStyles.h2),
                            const SizedBox(height: 2),
                            Text(email, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      if (profile != null && profile.surveyCompleted) ...[
                        const SizedBox(height: 28),
                        Text('FITNESS PROFILE', style: AppTextStyles.caption),
                        const SizedBox(height: 10),
                        _FitnessProfileCard(profile: profile),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Row(
                          children: [
                            Expanded(child: _ProfileStat(value: '0', label: 'Workouts')),
                            _VerticalDivider(),
                            Expanded(child: _ProfileStat(value: '0', label: 'Day Streak')),
                            _VerticalDivider(),
                            Expanded(child: _ProfileStat(value: '0', label: 'Followers')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('ACCOUNT', style: AppTextStyles.caption),
                      const SizedBox(height: 10),
                      const _MenuCard(items: [
                        _MenuItemData(icon: Icons.person_outline_rounded, label: 'Personal Information'),
                        _MenuItemData(icon: Icons.flag_outlined, label: 'Goals & Targets'),
                        _MenuItemData(icon: Icons.emoji_events_outlined, label: 'Achievements'),
                      ]),
                      const SizedBox(height: 24),
                      Text('PREFERENCES', style: AppTextStyles.caption),
                      const SizedBox(height: 10),
                      const _MenuCard(items: [
                        _MenuItemData(icon: Icons.notifications_none_rounded, label: 'Notifications'),
                        _MenuItemData(icon: Icons.link_rounded, label: 'Connected Apps'),
                        _MenuItemData(icon: Icons.dark_mode_outlined, label: 'Appearance'),
                      ]),
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
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            await AuthService.instance.signOut();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _FactTile(icon: Icons.cake_outlined, label: 'Age', value: '${profile.age ?? '—'}')),
              const _VerticalDivider(),
              Expanded(child: _FactTile(icon: Icons.wc_rounded, label: 'Gender', value: profile.gender ?? '—')),
            ],
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
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
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flag_rounded, color: AppColors.primary, size: 20),
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h1.copyWith(fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodySmall),
      ],
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
  const _MenuItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(item.icon, size: 19, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(item.label, style: AppTextStyles.bodyLarge)),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (i != items.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}
