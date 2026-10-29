import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/food.dart';

/// A user's favorited foods (`public.favorite_foods`), for quickly
/// re-logging frequently eaten items without searching again.
class FavoriteFoodRepository {
  FavoriteFoodRepository._();
  static final FavoriteFoodRepository instance = FavoriteFoodRepository._();

  SupabaseQueryBuilder get _favorites => Supabase.instance.client.from('favorite_foods');

  Future<List<Food>> list(String userId) async {
    final rows = await _favorites.select('food_id, created_at, foods(*)').eq('user_id', userId).order('created_at', ascending: false);
    return rows.where((r) => r['foods'] != null).map((r) => Food.fromMap(Map<String, dynamic>.from(r['foods'] as Map))).toList();
  }

  Future<Set<String>> favoriteIds(String userId) async {
    final rows = await _favorites.select('food_id').eq('user_id', userId);
    return rows.map((r) => r['food_id'] as String).toSet();
  }

  Future<void> add({required String userId, required String foodId}) {
    return _favorites.upsert({'user_id': userId, 'food_id': foodId}, onConflict: 'user_id,food_id');
  }

  Future<void> remove({required String userId, required String foodId}) {
    return _favorites.delete().eq('user_id', userId).eq('food_id', foodId);
  }
}
