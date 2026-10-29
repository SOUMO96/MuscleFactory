enum MealCategory { breakfast, lunch, dinner, snack }

extension MealCategoryX on MealCategory {
  String get storageValue => name;

  String get label => switch (this) {
        MealCategory.breakfast => 'Breakfast',
        MealCategory.lunch => 'Lunch',
        MealCategory.dinner => 'Dinner',
        MealCategory.snack => 'Snacks',
      };

  static MealCategory fromStorage(String? value) {
    for (final c in MealCategory.values) {
      if (c.storageValue == value) return c;
    }
    return MealCategory.snack;
  }
}

/// A logged food entry (`public.nutrition_entries`). Either linked to a food
/// and quantity (calories/macros computed from per-100g values) or a manual
/// entry with foodId and quantityG null.
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
    this.mealCategory = MealCategory.snack,
    this.foodId,
    this.quantityG,
    this.foodName,
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
  final MealCategory mealCategory;
  final String? foodId;
  final double? quantityG;

  /// Joined from `foods.name` when this entry is linked to a real food.
  final String? foodName;

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
        mealCategory: MealCategoryX.fromStorage(map['meal_category'] as String?),
        foodId: map['food_id'] as String?,
        quantityG: (map['quantity_g'] as num?)?.toDouble(),
        foodName: (map['foods'] as Map<String, dynamic>?)?['name'] as String?,
      );
}
