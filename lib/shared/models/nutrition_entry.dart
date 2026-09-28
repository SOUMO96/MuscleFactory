/// One manually-logged meal (`public.nutrition_entries`).
class NutritionEntry {
  const NutritionEntry({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.mealLabel,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.loggedAt,
  });

  final String id;
  final String userId;
  final DateTime entryDate;
  final String mealLabel;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final DateTime loggedAt;

  factory NutritionEntry.fromMap(Map<String, dynamic> map) => NutritionEntry(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        entryDate: DateTime.parse(map['entry_date'] as String),
        mealLabel: map['meal_label'] as String,
        calories: map['calories'] as int,
        proteinG: (map['protein_g'] as num?)?.toDouble(),
        carbsG: (map['carbs_g'] as num?)?.toDouble(),
        fatG: (map['fat_g'] as num?)?.toDouble(),
        loggedAt: DateTime.parse(map['logged_at'] as String),
      );
}
