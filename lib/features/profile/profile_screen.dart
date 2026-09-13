import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
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
                          'AJ',
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
                  Text('Alex Johnson', style: AppTextStyles.h2),
                  const SizedBox(height: 2),
                  Text('alex.johnson@email.com', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
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
                  Expanded(child: _ProfileStat(value: '42', label: 'Workouts')),
                  _VerticalDivider(),
                  Expanded(child: _ProfileStat(value: '6', label: 'Day Streak')),
                  _VerticalDivider(),
                  Expanded(child: _ProfileStat(value: '128', label: 'Followers')),
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
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                ),
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
        ),
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
