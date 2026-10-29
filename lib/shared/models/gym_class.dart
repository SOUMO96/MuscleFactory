/// A scheduled class instance (`public.classes`).
class GymClass {
  const GymClass({
    required this.id,
    required this.name,
    required this.category,
    required this.coachName,
    required this.location,
    required this.startsAt,
    required this.durationMinutes,
    required this.capacity,
  });

  final String id;
  final String name;
  final String category;
  final String coachName;
  final String location;
  final DateTime startsAt;
  final int durationMinutes;
  final int capacity;

  factory GymClass.fromMap(Map<String, dynamic> map) => GymClass(
        id: map['id'] as String,
        name: map['name'] as String,
        category: map['category'] as String,
        coachName: map['coach_name'] as String,
        location: map['location'] as String,
        // Deliberately not .toLocal(): the schedule stores the gym's wall-clock times
        // labelled as UTC, so everyone sees the same "6:30 PM" regardless of device
        // timezone.
        startsAt: DateTime.parse(map['starts_at'] as String),
        durationMinutes: map['duration_minutes'] as int,
        capacity: map['capacity'] as int,
      );
}

enum BookingStatus { booked, waitlisted, cancelled }

extension BookingStatusX on BookingStatus {
  String get storageValue => name;

  static BookingStatus fromStorage(String? value) {
    for (final status in BookingStatus.values) {
      if (status.storageValue == value) return status;
    }
    return BookingStatus.cancelled;
  }
}

/// A user's booking against a [GymClass] (`public.class_bookings`).
class ClassBooking {
  const ClassBooking({
    required this.id,
    required this.classId,
    required this.userId,
    required this.status,
  });

  final String id;
  final String classId;
  final String userId;
  final BookingStatus status;

  factory ClassBooking.fromMap(Map<String, dynamic> map) => ClassBooking(
        id: map['id'] as String,
        classId: map['class_id'] as String,
        userId: map['user_id'] as String,
        status: BookingStatusX.fromStorage(map['status'] as String?),
      );
}
