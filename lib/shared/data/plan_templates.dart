import '../models/app_user.dart';

/// One exercise prescribed on a template day, referenced by exercise
/// *name* (resolved against the real `exercises` catalog at plan-creation
/// time, since templates are static Dart data, not database rows).
class TemplateExercise {
  const TemplateExercise({required this.exerciseName, required this.sets, required this.reps});
  final String exerciseName;
  final int sets;
  final String reps;
}

class TemplateDay {
  const TemplateDay({required this.label, required this.exercises});
  final String label;
  final List<TemplateExercise> exercises;
}

class PlanTemplate {
  const PlanTemplate({required this.name, required this.level, required this.durationWeeks, required this.days});
  final String name;
  final String level;
  final int durationWeeks;
  final List<TemplateDay> days;
}

/// A few pre-written plans by goal and days per week. This is what "Use our
/// plan" does: a rule-based pick (no AI call) that falls back to the closest
/// days-per-week template.
class PlanTemplates {
  PlanTemplates._();

  static PlanTemplate pick({required FitnessGoal goal, required int daysPerWeek}) {
    final candidates = _templatesFor(goal);
    candidates.sort((a, b) => (a.days.length - daysPerWeek).abs().compareTo((b.days.length - daysPerWeek).abs()));
    return candidates.first;
  }

  static List<PlanTemplate> _templatesFor(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.gainWeight:
        return [_hypertrophy3, _hypertrophy4, _hypertrophy5];
      case FitnessGoal.loseWeight:
        return [_conditioning3, _conditioning4, _fullBody5];
      case FitnessGoal.stayFit:
        return [_fullBody3, _fullBody4, _fullBody5];
    }
  }

  static const _hypertrophy3 = PlanTemplate(
    name: 'Hypertrophy 12',
    level: 'Intermediate',
    durationWeeks: 12,
    days: [
      TemplateDay(label: 'Push', exercises: [
        TemplateExercise(exerciseName: 'Barbell Bench Press', sets: 4, reps: '8'),
        TemplateExercise(exerciseName: 'Overhead Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Incline Dumbbell Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Triceps Pushdown', sets: 3, reps: '12'),
      ]),
      TemplateDay(label: 'Pull', exercises: [
        TemplateExercise(exerciseName: 'Deadlift', sets: 3, reps: '5'),
        TemplateExercise(exerciseName: 'Barbell Row', sets: 4, reps: '8'),
        TemplateExercise(exerciseName: 'Lat Pulldown', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Barbell Curl', sets: 3, reps: '12'),
      ]),
      TemplateDay(label: 'Legs', exercises: [
        TemplateExercise(exerciseName: 'Back Squat', sets: 4, reps: '6'),
        TemplateExercise(exerciseName: 'Romanian Deadlift', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Leg Press', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Standing Calf Raise', sets: 3, reps: '15'),
      ]),
    ],
  );

  static const _hypertrophy4 = PlanTemplate(
    name: 'Hypertrophy 12',
    level: 'Intermediate',
    durationWeeks: 12,
    days: [
      TemplateDay(label: 'Push A', exercises: [
        TemplateExercise(exerciseName: 'Barbell Bench Press', sets: 4, reps: '8'),
        TemplateExercise(exerciseName: 'Overhead Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Dumbbell Fly', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Triceps Pushdown', sets: 3, reps: '12'),
      ]),
      TemplateDay(label: 'Pull A', exercises: [
        TemplateExercise(exerciseName: 'Deadlift', sets: 3, reps: '5'),
        TemplateExercise(exerciseName: 'Barbell Row', sets: 4, reps: '8'),
        TemplateExercise(exerciseName: 'Lat Pulldown', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Barbell Curl', sets: 3, reps: '12'),
      ]),
      TemplateDay(label: 'Legs A', exercises: [
        TemplateExercise(exerciseName: 'Back Squat', sets: 4, reps: '6'),
        TemplateExercise(exerciseName: 'Leg Press', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Lying Leg Curl', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Standing Calf Raise', sets: 3, reps: '15'),
      ]),
      TemplateDay(label: 'Upper', exercises: [
        TemplateExercise(exerciseName: 'Incline Barbell Press', sets: 4, reps: '8'),
        TemplateExercise(exerciseName: 'Cable Row', sets: 4, reps: '10'),
        TemplateExercise(exerciseName: 'Lateral Raise', sets: 3, reps: '15'),
        TemplateExercise(exerciseName: 'Hammer Curl', sets: 3, reps: '12'),
      ]),
    ],
  );

  static const _hypertrophy5 = PlanTemplate(
    name: 'Hypertrophy 12',
    level: 'Advanced',
    durationWeeks: 12,
    days: [
      TemplateDay(label: 'Chest & Triceps', exercises: [
        TemplateExercise(exerciseName: 'Barbell Bench Press', sets: 4, reps: '8'),
        TemplateExercise(exerciseName: 'Incline Dumbbell Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Cable Crossover', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Close-Grip Bench Press', sets: 3, reps: '10'),
      ]),
      TemplateDay(label: 'Back & Biceps', exercises: [
        TemplateExercise(exerciseName: 'Deadlift', sets: 3, reps: '5'),
        TemplateExercise(exerciseName: 'Pull-Up', sets: 4, reps: '8'),
        TemplateExercise(exerciseName: 'Barbell Row', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Barbell Curl', sets: 3, reps: '12'),
      ]),
      TemplateDay(label: 'Legs', exercises: [
        TemplateExercise(exerciseName: 'Back Squat', sets: 4, reps: '6'),
        TemplateExercise(exerciseName: 'Romanian Deadlift', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Leg Extension', sets: 3, reps: '15'),
        TemplateExercise(exerciseName: 'Seated Calf Raise', sets: 3, reps: '15'),
      ]),
      TemplateDay(label: 'Shoulders', exercises: [
        TemplateExercise(exerciseName: 'Overhead Press', sets: 4, reps: '8'),
        TemplateExercise(exerciseName: 'Lateral Raise', sets: 4, reps: '15'),
        TemplateExercise(exerciseName: 'Rear Delt Fly', sets: 3, reps: '15'),
        TemplateExercise(exerciseName: 'Shrug', sets: 3, reps: '12'),
      ]),
      TemplateDay(label: 'Arms & Core', exercises: [
        TemplateExercise(exerciseName: 'Preacher Curl', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Skull Crusher', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Hanging Leg Raise', sets: 3, reps: '15'),
        TemplateExercise(exerciseName: 'Plank', sets: 3, reps: '45s'),
      ]),
    ],
  );

  static const _fullBody3 = PlanTemplate(
    name: 'Full Body Foundations',
    level: 'Beginner',
    durationWeeks: 8,
    days: [
      TemplateDay(label: 'Full Body A', exercises: [
        TemplateExercise(exerciseName: 'Goblet Squat', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Push-Up', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Dumbbell Row', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Plank', sets: 3, reps: '30s'),
      ]),
      TemplateDay(label: 'Full Body B', exercises: [
        TemplateExercise(exerciseName: 'Leg Press', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Machine Chest Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Lat Pulldown', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Russian Twist', sets: 3, reps: '20'),
      ]),
      TemplateDay(label: 'Full Body C', exercises: [
        TemplateExercise(exerciseName: 'Walking Lunge', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Seated Dumbbell Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Cable Row', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Mountain Climber', sets: 3, reps: '20'),
      ]),
    ],
  );

  static const _fullBody4 = PlanTemplate(
    name: 'Full Body Foundations',
    level: 'Beginner',
    durationWeeks: 8,
    days: [
      TemplateDay(label: 'Full Body A', exercises: [
        TemplateExercise(exerciseName: 'Goblet Squat', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Push-Up', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Dumbbell Row', sets: 3, reps: '10'),
      ]),
      TemplateDay(label: 'Full Body B', exercises: [
        TemplateExercise(exerciseName: 'Leg Press', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Machine Chest Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Lat Pulldown', sets: 3, reps: '10'),
      ]),
      TemplateDay(label: 'Full Body C', exercises: [
        TemplateExercise(exerciseName: 'Walking Lunge', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Seated Dumbbell Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Cable Row', sets: 3, reps: '10'),
      ]),
      TemplateDay(label: 'Core & Conditioning', exercises: [
        TemplateExercise(exerciseName: 'Kettlebell Swing', sets: 4, reps: '15'),
        TemplateExercise(exerciseName: 'Plank', sets: 3, reps: '40s'),
        TemplateExercise(exerciseName: 'Russian Twist', sets: 3, reps: '20'),
      ]),
    ],
  );

  static const _fullBody5 = PlanTemplate(
    name: 'Full Body Foundations',
    level: 'Intermediate',
    durationWeeks: 8,
    days: [
      TemplateDay(label: 'Full Body A', exercises: [
        TemplateExercise(exerciseName: 'Back Squat', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Push-Up', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Dumbbell Row', sets: 3, reps: '10'),
      ]),
      TemplateDay(label: 'Full Body B', exercises: [
        TemplateExercise(exerciseName: 'Leg Press', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Machine Chest Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Lat Pulldown', sets: 3, reps: '10'),
      ]),
      TemplateDay(label: 'Full Body C', exercises: [
        TemplateExercise(exerciseName: 'Walking Lunge', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Seated Dumbbell Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Cable Row', sets: 3, reps: '10'),
      ]),
      TemplateDay(label: 'Conditioning', exercises: [
        TemplateExercise(exerciseName: 'Rowing Machine', sets: 1, reps: '15 min'),
        TemplateExercise(exerciseName: 'Kettlebell Swing', sets: 4, reps: '15'),
        TemplateExercise(exerciseName: 'Plank', sets: 3, reps: '45s'),
      ]),
      TemplateDay(label: 'Core & Mobility', exercises: [
        TemplateExercise(exerciseName: 'Hanging Leg Raise', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Side Plank', sets: 3, reps: '30s'),
        TemplateExercise(exerciseName: 'Back Extension', sets: 3, reps: '15'),
      ]),
    ],
  );

  static const _conditioning3 = PlanTemplate(
    name: 'Lean & Conditioned',
    level: 'Intermediate',
    durationWeeks: 8,
    days: [
      TemplateDay(label: 'Full Body + HIIT', exercises: [
        TemplateExercise(exerciseName: 'Goblet Squat', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Push-Up', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Kettlebell Swing', sets: 4, reps: '15'),
        TemplateExercise(exerciseName: 'Jump Rope', sets: 1, reps: '5 min'),
      ]),
      TemplateDay(label: 'Upper + Core', exercises: [
        TemplateExercise(exerciseName: 'Dumbbell Row', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Machine Chest Press', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Plank', sets: 3, reps: '40s'),
        TemplateExercise(exerciseName: 'Mountain Climber', sets: 3, reps: '20'),
      ]),
      TemplateDay(label: 'Lower + Cardio', exercises: [
        TemplateExercise(exerciseName: 'Leg Press', sets: 3, reps: '15'),
        TemplateExercise(exerciseName: 'Walking Lunge', sets: 3, reps: '12'),
        TemplateExercise(exerciseName: 'Battle Ropes', sets: 4, reps: '30s'),
        TemplateExercise(exerciseName: 'Treadmill Run', sets: 1, reps: '15 min'),
      ]),
    ],
  );

  static const _conditioning4 = PlanTemplate(
    name: 'Lean & Conditioned',
    level: 'Intermediate',
    durationWeeks: 8,
    days: [
      TemplateDay(label: 'Upper Strength', exercises: [
        TemplateExercise(exerciseName: 'Barbell Bench Press', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Barbell Row', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Overhead Press', sets: 3, reps: '10'),
      ]),
      TemplateDay(label: 'HIIT Conditioning', exercises: [
        TemplateExercise(exerciseName: 'Burpee', sets: 4, reps: '15'),
        TemplateExercise(exerciseName: 'Kettlebell Swing', sets: 4, reps: '15'),
        TemplateExercise(exerciseName: 'Jump Rope', sets: 1, reps: '8 min'),
      ]),
      TemplateDay(label: 'Lower Strength', exercises: [
        TemplateExercise(exerciseName: 'Back Squat', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Romanian Deadlift', sets: 3, reps: '10'),
        TemplateExercise(exerciseName: 'Walking Lunge', sets: 3, reps: '12'),
      ]),
      TemplateDay(label: 'Cardio + Core', exercises: [
        TemplateExercise(exerciseName: 'Rowing Machine', sets: 1, reps: '20 min'),
        TemplateExercise(exerciseName: 'Hanging Leg Raise', sets: 3, reps: '15'),
        TemplateExercise(exerciseName: 'Plank', sets: 3, reps: '45s'),
      ]),
    ],
  );
}
