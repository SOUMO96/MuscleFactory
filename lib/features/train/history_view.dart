import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/workout_session.dart';
import 'workout_session_detail_screen.dart';

/// Past workout sessions, most recent first.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<WorkoutSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final sessions = await WorkoutSessionRepository.instance.history(userId);
    if (!mounted) return;
    setState(() {
      _sessions = sessions.where((s) => s.isFinished).toList();
      _loading = false;
    });
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No finished workouts yet.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, i) {
        final s = _sessions[i];
        final duration = s.endedAt!.difference(s.startedAt);
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WorkoutSessionDetailScreen(session: s)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.planDayLabel ?? 'Freestyle workout', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(_formatDate(s.startedAt), style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Text('${duration.inMinutes} min', style: AppTextStyles.h3),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
