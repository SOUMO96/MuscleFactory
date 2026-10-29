import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/nutrition_entry.dart';

/// Reads and writes logged meals (`public.nutrition_entries`) -- either
/// linked to a real food + quantity (see FoodRepository) or fully manual.
class NutritionRepository {
  NutritionRepository._();
  static final NutritionRepository instance = NutritionRepository._();

  SupabaseQueryBuilder get _entries => Supabase.instance.client.from('nutrition_entries');

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

  Future<List<NutritionEntry>> entriesForDate(String userId, DateTime date) async {
    final rows = await _entries
        .select('*, foods(name)')
        .eq('user_id', userId)
        .eq('entry_date', _dateOnly(date))
        .order('logged_at', ascending: true);
    return rows.map(NutritionEntry.fromMap).toList();
  }

  /// All entries between [from] and [to] (inclusive), most recent day
  /// first -- backs the nutrition history view.
  Future<List<NutritionEntry>> entriesForRange(String userId, {required DateTime from, required DateTime to}) async {
    final rows = await _entries
        .select('*, foods(name)')
        .eq('user_id', userId)
        .gte('entry_date', _dateOnly(from))
        .lte('entry_date', _dateOnly(to))
        .order('entry_date', ascending: false)
        .order('logged_at', ascending: true);
    return rows.map(NutritionEntry.fromMap).toList();
  }

  Future<String> addEntry({
    required String userId,
    required DateTime entryDate,
    required String mealLabel,
    required int calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    MealCategory mealCategory = MealCategory.snack,
    String? foodId,
    double? quantityG,
  }) async {
    final row = await _entries
        .insert({
          'user_id': userId,
          'entry_date': _dateOnly(entryDate),
          'meal_label': mealLabel,
          'calories': calories,
          'protein_g': proteinG,
          'carbs_g': carbsG,
          'fat_g': fatG,
          'meal_category': mealCategory.storageValue,
          'food_id': foodId,
          'quantity_g': quantityG,
        })
        .select()
        .single();
    return row['id'] as String;
  }

  /// Rewrites an existing food-linked entry's quantity and recalculated
  /// macros -- used when editing a logged food's amount instead of
  /// deleting and re-adding it.
  Future<void> updateQuantity({
    required String id,
    required double quantityG,
    required int calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) {
    return _entries.update({
      'quantity_g': quantityG,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
    }).eq('id', id);
  }

  Future<void> deleteEntry(String id) => _entries.delete().eq('id', id);

  /// Duplicates every entry from [fromDate] into [toDate] -- "copy a
  /// previous meal" -- as brand new rows (not references), so editing or
  /// deleting the copy never touches the original day's log.
  Future<void> copyDay({required String userId, required DateTime fromDate, required DateTime toDate}) async {
    final source = await entriesForDate(userId, fromDate);
    for (final e in source) {
      await addEntry(
        userId: userId,
        entryDate: toDate,
        mealLabel: e.mealLabel,
        calories: e.calories,
        proteinG: e.proteinG,
        carbsG: e.carbsG,
        fatG: e.fatG,
        mealCategory: e.mealCategory,
        foodId: e.foodId,
        quantityG: e.quantityG,
      );
    }
  }
}
