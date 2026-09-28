import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/workout_card.dart';
import '../../shared/data/dummy_data.dart';
import '../../shared/models/workout.dart';
import 'workout_detail_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String _category = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = DummyData.workouts.where((w) {
      final matchesCategory = _category == 'All' || w.category == _category;
      final matchesQuery = _query.isEmpty || w.name.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Workouts', style: AppTextStyles.h1.copyWith(fontSize: 24)),
                  Material(
                    color: AppColors.surfaceVariant,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.tune_rounded, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search workouts...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: DummyData.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final cat = DummyData.categories[i];
                  final selected = cat == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.card,
                        border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                      ),
                      child: Text(
                        cat,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: selected ? AppColors.background : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No workouts found', style: AppTextStyles.bodyLarge),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final Workout w = filtered[i];
                        return WorkoutCard(
                          workout: w,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: w)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
