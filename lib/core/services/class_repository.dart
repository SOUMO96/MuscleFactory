import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/gym_class.dart';

/// Reads the class schedule and manages a user's bookings
/// (`public.classes` + `public.class_bookings`).
class ClassRepository {
  ClassRepository._();
  static final ClassRepository instance = ClassRepository._();

  SupabaseQueryBuilder get _classes => Supabase.instance.client.from('classes');
  SupabaseQueryBuilder get _bookings => Supabase.instance.client.from('class_bookings');

  Future<List<GymClass>> upcoming({DateTime? from}) async {
    final start = (from ?? DateTime.now()).toUtc().toIso8601String();
    final rows = await _classes.select().gte('starts_at', start).order('starts_at');
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
