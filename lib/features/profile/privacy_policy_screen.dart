import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// Opened from Profile -> Support -> Privacy Policy. Describes what the app
/// actually stores (see supabase/migrations/).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'What we store',
      'Your account email, display name, and the fitness details you enter '
          '(age, height, weight, goals), plus the workouts, sets, classes, '
          'meals, and water you log. All of it is tied to your account and '
          'only your account can read or change it.',
    ),
    (
      'What we don\'t do',
      'We don\'t sell your data, share it with advertisers, or use it to '
          'train anything. There\'s no analytics or tracking SDK in this app.',
    ),
    (
      'Where it lives',
      'Data is stored with Supabase (Postgres) and protected by row-level '
          'security rules that restrict every table to its owner.',
    ),
    (
      'Deleting your data',
      'Email support (Help & Support) to request your account and all '
          'associated data be deleted.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Policy', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            for (final (title, body) in _sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h3),
                    const SizedBox(height: 6),
                    Text(body, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
