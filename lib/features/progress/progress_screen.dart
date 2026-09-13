import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../shared/data/dummy_data.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _range = 0; // 0 = Week, 1 = Month, 2 = Year

  static const _ranges = ['Week', 'Month', 'Year'];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text('Your Progress', style: AppTextStyles.h1.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: List.generate(_ranges.length, (i) {
                  final selected = i == _range;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _range = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _ranges[i],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: selected ? AppColors.background : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calories Burned', style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text('This week · 2,760 kcal total', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 700,
                        barTouchData: BarTouchData(enabled: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= _days.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(_days[i], style: AppTextStyles.bodySmall),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(DummyData.weeklyCalories.length, (i) {
                          final value = DummyData.weeklyCalories[i];
                          final isPeak = value == DummyData.weeklyCalories.reduce((a, b) => a > b ? a : b);
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: value,
                                width: 18,
                                borderRadius: BorderRadius.circular(6),
                                color: isPeak ? AppColors.primary : AppColors.surfaceVariant,
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.monitor_weight_outlined,
                    value: '78.4 kg',
                    label: 'Current weight',
                    accentColor: AppColors.primary,
                    trend: '-1.2 kg',
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: StatCard(
                    icon: Icons.percent_rounded,
                    value: '17.2%',
                    label: 'Body fat',
                    accentColor: Color(0xFF2E7CF6),
                    trend: '-0.8%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.fitness_center_rounded,
                    value: '42',
                    label: 'Total workouts',
                    accentColor: AppColors.secondary,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: StatCard(
                    icon: Icons.schedule_rounded,
                    value: '31.5 hrs',
                    label: 'Total time',
                    accentColor: Color(0xFF9B5CFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(title: 'Achievements', actionLabel: 'See all', onAction: () {}),
            const SizedBox(height: 14),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DummyData.achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final a = DummyData.achievements[i];
                  return SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: a.unlocked ? AppColors.primary.withValues(alpha: 0.15) : AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: a.unlocked ? AppColors.primary : AppColors.divider,
                            ),
                          ),
                          child: Icon(
                            a.icon,
                            color: a.unlocked ? AppColors.primary : AppColors.textMuted,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: AppTextStyles.caption.copyWith(
                            color: a.unlocked ? AppColors.textSecondary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeader(title: 'Body Measurements'),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                children: [
                  _MeasurementRow(label: 'Chest', value: '102 cm', delta: '+1.0 cm'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  _MeasurementRow(label: 'Waist', value: '84 cm', delta: '-2.0 cm'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  _MeasurementRow(label: 'Arms', value: '38 cm', delta: '+0.5 cm'),
                  Divider(height: 1, indent: 16, endIndent: 16),
                  _MeasurementRow(label: 'Legs', value: '58 cm', delta: '+1.2 cm'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.label, required this.value, required this.delta});
  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    final positive = delta.startsWith('+');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          Row(
            children: [
              Text(value, style: AppTextStyles.h3),
              const SizedBox(width: 8),
              Text(
                delta,
                style: AppTextStyles.bodySmall.copyWith(
                  color: positive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
