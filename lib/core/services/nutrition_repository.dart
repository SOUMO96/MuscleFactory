import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/nutrition_entry.dart';

/// Reads and writes manually-logged meals (`public.nutrition_entries`).
class NutritionRepository {
  NutritionRepository._();
  static final NutritionRepository instance = NutritionRepository._();

  SupabaseQueryBuilder get _entries => Supabase.instance.client.from('nutrition_entries');

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

  Future<List<NutritionEntry>> entriesForDate(String userId, DateTime date) async {
    final rows = await _entries.select().eq('user_id', userId).eq('entry_date', _dateOnly(date)).order('logged_at');
    return rows.map(NutritionEntry.fromMap).toList();
  }

  Future<void> addEntry({
    required String userId,
    required DateTime entryDate,
    required String mealLabel,
    required int calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) {
    return _entries.insert({
      'user_id': userId,
      'entry_date': _dateOnly(entryDate),
      'meal_label': mealLabel,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
    });
  }

  Future<void> deleteEntry(String id) => _entries.delete().eq('id', id);
}
