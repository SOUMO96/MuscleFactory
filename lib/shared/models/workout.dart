import 'package:flutter/material.dart';

/// A single exercise entry inside a [Workout].
class ExerciseItem {
  const ExerciseItem({
    required this.name,
    required this.detail,
    required this.icon,
  });

  final String name;

  /// e.g. "4 sets x 12 reps" or "3 sets x 45 sec"
  final String detail;
  final IconData icon;
}

/// A single workout plan shown in Home / Workouts / Detail screens.
class Workout {
  const Workout({
    required this.id,
    required this.name,
    required this.category,
    required this.level,
    required this.durationMinutes,
    required this.calories,
    required this.gradient,
    required this.icon,
    required this.description,
    required this.exercises,
  });

  final String id;
  final String name;
  final String category;
  final String level;
  final int durationMinutes;
  final int calories;
  final List<Color> gradient;
  final IconData icon;
  final String description;
  final List<ExerciseItem> exercises;
}
