import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/food.dart';

/// Reads the shared food catalog (`public.foods`) and proxies USDA
/// FoodData Central searches through the food-search Edge Function, which
/// keeps the USDA API key server-side -- see supabase/functions/food-search.
class FoodRepository {
  FoodRepository._();
  static final FoodRepository instance = FoodRepository._();

  SupabaseQueryBuilder get _foods => Supabase.instance.client.from('foods');

  /// Searches the local catalog first: the seeded Indian dishes plus anything
  /// cached from earlier USDA searches. Fast, and spares the USDA rate limit.
  Future<List<Food>> searchLocal(String query, {int limit = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final rows = await _foods.select().ilike('name', '%$trimmed%').order('name', ascending: true).limit(limit);
    return rows.map(Food.fromMap).toList();
  }

  /// Calls the food-search Edge Function (USDA FoodData Central). The API key
  /// stays server-side, and results are cached into `foods` so [searchLocal]
  /// finds them next time.
  Future<List<Food>> searchUsda(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];
    final res = await Supabase.instance.client.functions.invoke(
      'food-search',
      body: {'query': trimmed},
    );
    final data = res.data;
    if (data is! Map || data['foods'] is! List) return [];
    return (data['foods'] as List).map((m) => Food.fromMap(Map<String, dynamic>.from(m as Map))).toList();
  }

  Future<Food?> getById(String id) async {
    final row = await _foods.select().eq('id', id).maybeSingle();
    return row == null ? null : Food.fromMap(row);
  }
}
