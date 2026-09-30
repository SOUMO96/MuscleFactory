import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/exercise.dart';

/// Reads the public exercise catalog (`public.exercises`) -- read-only,
/// seeded by a migration, no per-user data.
class ExerciseRepository {
  ExerciseRepository._();
  static final ExerciseRepository instance = ExerciseRepository._();

  SupabaseQueryBuilder get _exercises => Supabase.instance.client.from('exercises');

  Future<List<Exercise>> search({String? query, String? category}) async {
    var builder = _exercises.select();
    if (category != null && category != 'All') {
      builder = builder.eq('category', category);
    }
    if (query != null && query.trim().isNotEmpty) {
      builder = builder.ilike('name', '%${query.trim()}%');
    }
    final rows = await builder.order('name');
    return rows.map(Exercise.fromMap).toList();
  }

  Future<List<String>> listCategories() async {
    final rows = await _exercises.select('category');
    final categories = rows.map((r) => r['category'] as String).toSet().toList()..sort();
    return categories;
  }
}
