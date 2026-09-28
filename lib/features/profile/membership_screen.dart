import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/services/workout_session_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/workout_session.dart';

/// Real personal-pass QR (encodes the user's id, generated on-device via
/// qr_flutter) plus a real check-in count derived from finished workout
/// sessions this month. No real turnstile/hardware integration, per the
/// redesign plan's scope notes.
class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  AppUser? _profile;
  int _checkInsThisMonth = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final results = await Future.wait([
      UserRepository.instance.getUserProfile(userId),
      WorkoutSessionRepository.instance.history(userId, limit: 200),
    ]);
    if (!mounted) return;
    final profile = results[0] as AppUser?;
    final sessions = results[1] as List<WorkoutSession>;
    final now = DateTime.now();
    final thisMonth = sessions.where((s) => s.isFinished && s.startedAt.year == now.year && s.startedAt.month == now.month).length;
    setState(() {
      _profile = profile;
      _checkInsThisMonth = thisMonth;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Membership', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Container(
                    color: AppColors.textPrimary,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MUSCLE\nFACTORY',
                          style: AppTextStyles.h1.copyWith(color: AppColors.background, fontSize: 20, height: 0.95),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(14),
                          child: Center(
                            child: QrImageView(
                              data: _profile?.uid ?? '',
                              size: 180,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(_profile?.displayName ?? '', style: AppTextStyles.h3.copyWith(color: AppColors.background)),
                        Text(
                          'MF-${(_profile?.uid ?? '').substring(0, 8).toUpperCase()}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.background.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Show this code at the front desk to check in.', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider, width: 2), bottom: BorderSide(color: AppColors.divider, width: 2))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          Text('$_checkInsThisMonth', style: AppTextStyles.h1.copyWith(fontSize: 28)),
                          Text('Check-ins this month', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
