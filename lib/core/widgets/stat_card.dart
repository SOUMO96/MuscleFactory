import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One cell in a [StatRow]: a big number with a small label, and an optional
/// trend string. [StatRow] draws the shared borders between cells.
class StatCell extends StatelessWidget {
  const StatCell({
    super.key,
    required this.value,
    required this.label,
    this.trend,
  });

  final String value;
  final String label;

  /// Optional small trend string, e.g. "+12%".
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppTextStyles.h2.copyWith(fontSize: 24)),
              if (trend != null) ...[
                const SizedBox(width: 6),
                Text(trend!, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Lays out [StatCell]s (or any equal-width children) in a strip: a 2px rule
/// above and below, 1px dividers between cells, no card borders or radius.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 2),
          bottom: BorderSide(color: AppColors.divider, width: 2),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: i == 0 ? Colors.transparent : AppColors.divider, width: 1)),
                ),
                child: children[i],
              ),
            ),
        ],
      ),
    );
  }
}
