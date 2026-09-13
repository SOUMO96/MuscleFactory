import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/workout.dart';

/// Static placeholder data used to give the skeleton screens something
/// realistic to render. Replace with real data sources later.
class DummyData {
  DummyData._();

  static const List<String> categories = [
    'All',
    'Strength',
    'Cardio',
    'HIIT',
    'Yoga',
    'Stretching',
  ];

  static final List<Workout> workouts = [
    Workout(
      id: 'w1',
      name: 'Full Body Burn',
      category: 'Strength',
      level: 'Advanced',
      durationMinutes: 45,
      calories: 420,
      gradient: AppColors.workoutGradients[0],
      icon: Icons.fitness_center_rounded,
      description:
          'A high-intensity full body session hitting every major muscle group. '
          'Focus on controlled form and progressive overload.',
      exercises: const [
        ExerciseItem(name: 'Barbell Squat', detail: '4 sets x 10 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Bench Press', detail: '4 sets x 8 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Bent Over Row', detail: '3 sets x 12 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Overhead Press', detail: '3 sets x 10 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Plank Hold', detail: '3 sets x 45 sec', icon: Icons.timer_outlined),
      ],
    ),
    Workout(
      id: 'w2',
      name: 'Morning HIIT Blast',
      category: 'HIIT',
      level: 'Intermediate',
      durationMinutes: 25,
      calories: 310,
      gradient: AppColors.workoutGradients[2],
      icon: Icons.bolt_rounded,
      description:
          'Fast-paced interval circuit to spike your heart rate and torch '
          'calories before the day even starts.',
      exercises: const [
        ExerciseItem(name: 'Jumping Jacks', detail: '4 rounds x 40 sec', icon: Icons.directions_run_rounded),
        ExerciseItem(name: 'Mountain Climbers', detail: '4 rounds x 40 sec', icon: Icons.directions_run_rounded),
        ExerciseItem(name: 'Burpees', detail: '4 rounds x 30 sec', icon: Icons.whatshot_rounded),
        ExerciseItem(name: 'High Knees', detail: '4 rounds x 40 sec', icon: Icons.directions_run_rounded),
      ],
    ),
    Workout(
      id: 'w3',
      name: 'Leg Day Domination',
      category: 'Strength',
      level: 'Advanced',
      durationMinutes: 50,
      calories: 480,
      gradient: AppColors.workoutGradients[1],
      icon: Icons.fitness_center_rounded,
      description: 'Build raw lower-body power with heavy compound lifts and finishers.',
      exercises: const [
        ExerciseItem(name: 'Deadlift', detail: '5 sets x 6 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Leg Press', detail: '4 sets x 12 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Walking Lunges', detail: '3 sets x 20 steps', icon: Icons.directions_walk_rounded),
        ExerciseItem(name: 'Calf Raises', detail: '4 sets x 15 reps', icon: Icons.fitness_center_rounded),
      ],
    ),
    Workout(
      id: 'w4',
      name: 'Steady State Run',
      category: 'Cardio',
      level: 'Beginner',
      durationMinutes: 30,
      calories: 280,
      gradient: AppColors.workoutGradients[2],
      icon: Icons.directions_run_rounded,
      description: 'A relaxed pace endurance run to build your aerobic base.',
      exercises: const [
        ExerciseItem(name: 'Warm-up Walk', detail: '5 min', icon: Icons.directions_walk_rounded),
        ExerciseItem(name: 'Steady Jog', detail: '20 min', icon: Icons.directions_run_rounded),
        ExerciseItem(name: 'Cool-down Walk', detail: '5 min', icon: Icons.directions_walk_rounded),
      ],
    ),
    Workout(
      id: 'w5',
      name: 'Flexibility & Flow',
      category: 'Yoga',
      level: 'Beginner',
      durationMinutes: 35,
      calories: 150,
      gradient: AppColors.workoutGradients[3],
      icon: Icons.self_improvement_rounded,
      description: 'A gentle vinyasa flow to improve mobility and reduce stress.',
      exercises: const [
        ExerciseItem(name: 'Sun Salutation', detail: '3 rounds', icon: Icons.self_improvement_rounded),
        ExerciseItem(name: 'Warrior II', detail: '2 sets x 30 sec / side', icon: Icons.self_improvement_rounded),
        ExerciseItem(name: 'Downward Dog', detail: '2 sets x 45 sec', icon: Icons.self_improvement_rounded),
        ExerciseItem(name: 'Child\'s Pose', detail: '1 set x 60 sec', icon: Icons.self_improvement_rounded),
      ],
    ),
    Workout(
      id: 'w6',
      name: 'Post-Workout Stretch',
      category: 'Stretching',
      level: 'Beginner',
      durationMinutes: 15,
      calories: 60,
      gradient: AppColors.workoutGradients[4],
      icon: Icons.accessibility_new_rounded,
      description: 'Cool down and improve recovery with a full-body stretch routine.',
      exercises: const [
        ExerciseItem(name: 'Hamstring Stretch', detail: '2 sets x 30 sec / side', icon: Icons.accessibility_new_rounded),
        ExerciseItem(name: 'Quad Stretch', detail: '2 sets x 30 sec / side', icon: Icons.accessibility_new_rounded),
        ExerciseItem(name: 'Shoulder Stretch', detail: '2 sets x 20 sec / side', icon: Icons.accessibility_new_rounded),
      ],
    ),
    Workout(
      id: 'w7',
      name: 'Upper Body Pump',
      category: 'Strength',
      level: 'Intermediate',
      durationMinutes: 40,
      calories: 360,
      gradient: AppColors.workoutGradients[5],
      icon: Icons.fitness_center_rounded,
      description: 'Chest, back, shoulders and arms — a balanced upper body split.',
      exercises: const [
        ExerciseItem(name: 'Incline Dumbbell Press', detail: '4 sets x 10 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Lat Pulldown', detail: '4 sets x 12 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Lateral Raise', detail: '3 sets x 15 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Bicep Curl', detail: '3 sets x 12 reps', icon: Icons.fitness_center_rounded),
        ExerciseItem(name: 'Tricep Pushdown', detail: '3 sets x 12 reps', icon: Icons.fitness_center_rounded),
      ],
    ),
  ];

  /// Mon..Sun relative calories burned, used by the Progress bar chart.
  static const List<double> weeklyCalories = [320, 450, 280, 510, 390, 600, 210];

  static const List<Achievement> achievements = [
    Achievement(label: '7 Day\nStreak', icon: Icons.local_fire_department_rounded, unlocked: true),
    Achievement(label: 'First\nWorkout', icon: Icons.emoji_events_rounded, unlocked: true),
    Achievement(label: '10 Workouts', icon: Icons.military_tech_rounded, unlocked: true),
    Achievement(label: '5K Run', icon: Icons.directions_run_rounded, unlocked: false),
    Achievement(label: '30 Day\nStreak', icon: Icons.local_fire_department_rounded, unlocked: false),
  ];
}

class Achievement {
  const Achievement({required this.label, required this.icon, required this.unlocked});
  final String label;
  final IconData icon;
  final bool unlocked;
}
