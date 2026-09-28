import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/class_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/gym_class.dart';

/// Real class booking: the upcoming schedule (seeded, `public.classes`)
/// with book/cancel/waitlist against `public.class_bookings`.
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  List<GymClass> _classes = [];
  Map<String, BookingStatus> _myStatus = {};
  Map<String, int> _bookedCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    final classes = await ClassRepository.instance.upcoming();
    final myBookings = await ClassRepository.instance.myBookings(userId);
    final counts = await ClassRepository.instance.bookedCounts(classes.map((c) => c.id).toList());
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _myStatus = {for (final b in myBookings) b.classId: b.status};
      _bookedCounts = counts;
      _loading = false;
    });
  }

  Future<void> _toggleBooking(GymClass gymClass) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final current = _myStatus[gymClass.id];
    if (current == BookingStatus.booked || current == BookingStatus.waitlisted) {
      await ClassRepository.instance.setBooking(classId: gymClass.id, userId: userId, status: BookingStatus.cancelled);
    } else {
      final booked = _bookedCounts[gymClass.id] ?? 0;
      final status = booked >= gymClass.capacity ? BookingStatus.waitlisted : BookingStatus.booked;
      await ClassRepository.instance.setBooking(classId: gymClass.id, userId: userId, status: status);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Classes', style: AppTextStyles.h1.copyWith(fontSize: 24)),
                  Text('Factory East', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _classes.isEmpty
                      ? Center(child: Text('No classes scheduled.', style: AppTextStyles.bodyMedium))
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final groups = <String, List<GymClass>>{};
    for (final c in _classes) {
      final key = '${c.startsAt.year}-${c.startsAt.month}-${c.startsAt.day}';
      groups.putIfAbsent(key, () => []).add(c);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(_formatDayHeader(entry.value.first.startsAt), style: AppTextStyles.caption),
          ),
          for (final c in entry.value) _ClassRow(gymClass: c, status: _myStatus[c.id], bookedCount: _bookedCounts[c.id] ?? 0, onTap: () => _toggleBooking(c)),
        ],
      ],
    );
  }

  String _formatDayHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    if (that == today) return 'TODAY';
    if (that == today.add(const Duration(days: 1))) return 'TOMORROW';
    return '${d.day} ${_months[d.month - 1]}'.toUpperCase();
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.gymClass, required this.status, required this.bookedCount, required this.onTap});
  final GymClass gymClass;
  final BookingStatus? status;
  final int bookedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final full = bookedCount >= gymClass.capacity;
    final hh = gymClass.startsAt.hour.toString().padLeft(2, '0');
    final mm = gymClass.startsAt.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$hh:$mm', style: AppTextStyles.h3),
                Text('${gymClass.durationMinutes} min', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gymClass.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  '${gymClass.coachName} · ${full ? 'Full' : '${gymClass.capacity - bookedCount} spots'}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: status == BookingStatus.booked
                  ? BoxDecoration(color: AppColors.primary)
                  : BoxDecoration(border: Border.all(color: AppColors.divider)),
              child: Text(
                status == BookingStatus.booked
                    ? 'Booked'
                    : status == BookingStatus.waitlisted
                        ? 'Waitlisted'
                        : full
                            ? 'Waitlist'
                            : 'Book',
                style: AppTextStyles.bodySmall.copyWith(
                  color: status == BookingStatus.booked ? AppColors.background : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
