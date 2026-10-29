import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Opened from Profile -> Support -> Help & Support.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I change my active plan?',
      'Go to Train -> Plans and tap "Choose a different plan" below your current one.',
    ),
    (
      'Can I use lb instead of kg?',
      'Yes -- Me -> Preferences lets you switch units.',
    ),
    (
      'My workout didn\'t count toward my streak.',
      'A session only counts once at least one set is logged. Closing Active Workout before logging anything discards it on purpose, so an accidental tap doesn\'t fake a workout.',
    ),
    (
      'How do I cancel a class booking?',
      'Open Classes and tap the class again -- "Booked"/"Waitlisted" toggles back to open.',
    ),
  ];

  Future<void> _emailSupport() async {
    final uri = Uri(scheme: 'mailto', path: 'nobody98837@gmail.com', query: 'subject=Muscle Factory support');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help & Support', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text('FAQ', style: AppTextStyles.caption),
            const SizedBox(height: 10),
            for (final (q, a) in _faqs)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(a, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Material(
              color: AppColors.card,
              child: InkWell(
                onTap: _emailSupport,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                  child: Row(
                    children: [
                      Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email support', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                            Text('Usually replies within a day', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
