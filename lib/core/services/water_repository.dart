import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes water intake entries (`public.water_logs`).
class WaterRepository {
  WaterRepository._();
  static final WaterRepository instance = WaterRepository._();

  SupabaseQueryBuilder get _logs => Supabase.instance.client.from('water_logs');

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

  Future<int> totalForDate(String userId, DateTime date) async {
    final rows = await _logs.select('amount_ml').eq('user_id', userId).eq('entry_date', _dateOnly(date));
    return rows.fold<int>(0, (sum, r) => sum + (r['amount_ml'] as int));
  }

  Future<void> addWater({required String userId, required DateTime date, required int amountMl}) {
    return _logs.insert({'user_id': userId, 'entry_date': _dateOnly(date), 'amount_ml': amountMl});
  }
}
