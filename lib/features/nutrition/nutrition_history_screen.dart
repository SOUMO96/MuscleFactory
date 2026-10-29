import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/nutrition_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/nutrition_entry.dart';

/// Past 30 days of logged meals, grouped by day with each day's total
/// calories -- "view historical meal records".
class NutritionHistoryScreen extends StatefulWidget {
  const NutritionHistoryScreen({super.key});

  @override
  State<NutritionHistoryScreen> createState() => _NutritionHistoryScreenState();
}

class _NutritionHistoryScreenState extends State<NutritionHistoryScreen> {
  List<NutritionEntry> _entries = [];
  bool _loading = true;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final now = DateTime.now();
    final entries = await NutritionRepository.instance.entriesForRange(
      userId,
      from: now.subtract(const Duration(days: 30)),
      to: now,
    );
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final byDate = <String, List<NutritionEntry>>{};
    final order = <String>[];
    for (final e in _entries) {
      final key = '${e.entryDate.year}-${e.entryDate.month}-${e.entryDate.day}';
      if (!byDate.containsKey(key)) order.add(key);
      byDate.putIfAbsent(key, () => []).add(e);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Nutrition History', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : order.isEmpty
                ? Center(child: Text('No meals logged in the past 30 days.', style: AppTextStyles.bodyMedium))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      for (final key in order) _DaySection(date: byDate[key]!.first.entryDate, entries: byDate[key]!, months: _months),
                    ],
                  ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.date, required this.entries, required this.months});
  final DateTime date;
  final List<NutritionEntry> entries;
  final List<String> months;

  @override
  Widget build(BuildContext context) {
    final totalCalories = entries.fold(0, (sum, e) => sum + e.calories);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${date.day} ${months[date.month - 1]} ${date.year}', style: AppTextStyles.h3),
              Text('$totalCalories kcal', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in entries)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.foodName ?? e.mealLabel, style: AppTextStyles.bodyMedium),
                  ),
                  Text('${e.calories} kcal', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
