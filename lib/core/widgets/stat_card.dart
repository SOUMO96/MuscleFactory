import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A compact metric tile — icon, big value, small label.
/// Used in grids on Home / Progress screens.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor,
    this.trend,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? accentColor;

  /// Optional small trend string, e.g. "+2.4%"
  final String? trend;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend != null)
                Text(
                  trend!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.success),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: AppTextStyles.h2),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
