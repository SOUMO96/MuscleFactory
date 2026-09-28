import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/workout_session.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _range = 0; // 0 = Week, 1 = Month, 2 = Year
  static const _ranges = ['Week', 'Month', 'Year'];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String? _loadedForUserId;
  List<LoggedSet> _sets = [];
  List<WorkoutSession> _sessions = [];
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null && userId != _loadedForUserId) {
      _loadedForUserId = userId;
      _load(userId);
    }
  }

  Future<void> _load(String userId) async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        WorkoutSessionRepository.instance.recentSets(userId, since: DateTime.now().subtract(const Duration(days: 366))),
        WorkoutSessionRepository.instance.history(userId, limit: 200),
      ]);
      if (!mounted) return;
      setState(() {
        _sets = results[0] as List<LoggedSet>;
        _sessions = results[1] as List<WorkoutSession>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Duration get _totalTime {
    var total = Duration.zero;
    for (final s in _sessions) {
      if (s.endedAt != null) total += s.endedAt!.difference(s.startedAt);
    }
    return total;
  }

  double _volume(LoggedSet s) => (s.weightKg ?? 0) * (s.reps ?? 0);

  /// Daily volume for the last 7 days (Week) or weekly totals for the last
  /// ~4/12 buckets (Month/Year) -- simple client-side aggregation over the
  /// already-fetched year of sets.
  List<double> get _chartBars {
    final now = DateTime.now();
    if (_range == 0) {
      return List.generate(7, (i) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
        return _sets
            .where((s) => s.completedAt.year == day.year && s.completedAt.month == day.month && s.completedAt.day == day.day)
            .fold(0.0, (sum, s) => sum + _volume(s));
      });
    }
    final weeks = _range == 1 ? 4 : 12;
    return List.generate(weeks, (i) {
      final bucketsAgo = weeks - 1 - i;
      final start = now.subtract(Duration(days: (bucketsAgo + 1) * 7));
      final end = now.subtract(Duration(days: bucketsAgo * 7));
      return _sets.where((s) => s.completedAt.isAfter(start) && !s.completedAt.isAfter(end)).fold(0.0, (sum, s) => sum + _volume(s));
    });
  }

  List<MapEntry<String, double>> get _personalRecords {
    final best = <String, double>{};
    for (final s in _sets) {
      final name = s.exerciseName;
      if (name == null || s.weightKg == null) continue;
      if (s.weightKg! > (best[name] ?? 0)) best[name] = s.weightKg!;
    }
    final entries = best.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

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
                  return _buildContent(context, profile);
                },
              ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppUser? profile) {
    final bars = _chartBars;
    final maxBar = bars.fold(0.0, (m, v) => v > m ? v : m);
    final totalVolume = _sets.fold(0.0, (sum, s) => sum + _volume(s));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Text('Your Progress', style: AppTextStyles.h1.copyWith(fontSize: 24)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.divider)),
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
                    color: selected ? AppColors.primary : Colors.transparent,
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
          decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Volume', style: AppTextStyles.h3),
              const SizedBox(height: 2),
              Text('${_ranges[_range]} · ${totalVolume.round()} kg total', style: AppTextStyles.bodySmall),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxBar <= 0 ? 100 : maxBar * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      show: _range == 0,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: _range == 0,
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
                    barGroups: List.generate(bars.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: bars[i],
                            width: _range == 0 ? 18 : 10,
                            color: bars[i] > 0 ? AppColors.primary : AppColors.surfaceVariant,
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
        StatRow(
          children: [
            StatCell(value: profile?.currentWeightKg == null ? '—' : '${profile!.currentWeightKg!.toStringAsFixed(1)} kg', label: 'Current weight'),
            StatCell(value: profile?.targetWeightKg == null ? '—' : '${profile!.targetWeightKg!.toStringAsFixed(1)} kg', label: 'Target weight'),
          ],
        ),
        const SizedBox(height: 14),
        StatRow(
          children: [
            StatCell(value: '${_sessions.where((s) => s.isFinished).length}', label: 'Total workouts'),
            StatCell(value: '${_totalTime.inHours}h', label: 'Total time'),
          ],
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Personal Records'),
        const SizedBox(height: 14),
        if (_loading)
          Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (_personalRecords.isEmpty)
          Text('Log a workout to start tracking PRs.', style: AppTextStyles.bodyMedium)
        else
          Column(
            children: [
              for (final entry in _personalRecords)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700))),
                      Text(entry.value.toStringAsFixed(1), style: AppTextStyles.h3),
                      const SizedBox(width: 4),
                      Text('kg', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
