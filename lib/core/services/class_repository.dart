import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/gym_class.dart';

/// Reads the class schedule and manages a user's bookings
/// (`public.classes` + `public.class_bookings`).
class ClassRepository {
  ClassRepository._();
  static final ClassRepository instance = ClassRepository._();

  SupabaseQueryBuilder get _classes => Supabase.instance.client.from('classes');
  SupabaseQueryBuilder get _bookings => Supabase.instance.client.from('class_bookings');

  /// Tops up the next 14 days of classes from the weekly templates before
  /// reading. Safe to call repeatedly (unique index on template + date).
  Future<void> _ensureUpcoming() {
    final target = DateTime.now().add(const Duration(days: 14));
    final targetDate = '${target.year.toString().padLeft(4, '0')}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
    return Supabase.instance.client.rpc('ensure_classes_through', params: {'target_date': targetDate});
  }

  Future<List<GymClass>> upcoming({DateTime? from}) async {
    await _ensureUpcoming();
    final now = from ?? DateTime.now();
    // `starts_at` holds the gym's local wall-clock time labelled as UTC (one
    // location, no per-gym timezone), so the cutoff is built the same way
    // instead of being converted from real UTC.
    final start = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute, now.second).toIso8601String();
    // postgrest's .order() defaults to ascending: false -- explicit here,
    // otherwise this returns latest-first instead of soonest-first.
    final rows = await _classes.select().gte('starts_at', start).order('starts_at', ascending: true);
    return rows.map(GymClass.fromMap).toList();
  }

  Future<List<ClassBooking>> myBookings(String userId) async {
    final rows = await _bookings.select().eq('user_id', userId).neq('status', 'cancelled');
    return rows.map(ClassBooking.fromMap).toList();
  }

  /// Number of `booked` (non-waitlisted, non-cancelled) seats taken per
  /// class id, for computing remaining spots against `GymClass.capacity`.
  Future<Map<String, int>> bookedCounts(List<String> classIds) async {
    if (classIds.isEmpty) return {};
    final rows = await _bookings.select('class_id').inFilter('class_id', classIds).eq('status', 'booked');
    final counts = <String, int>{};
    for (final row in rows) {
      final id = row['class_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> setBooking({required String classId, required String userId, required BookingStatus status}) {
    return _bookings.upsert(
      {'class_id': classId, 'user_id': userId, 'status': status.storageValue},
      onConflict: 'class_id,user_id',
    );
  }
}
