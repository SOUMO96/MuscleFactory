/// A food in the shared catalog (`public.foods`): a seeded local staple (mostly
/// Indian dishes USDA covers poorly) or a cached USDA result. Nutrition fields
/// are per 100g.
class Food {
  const Food({
    required this.id,
    this.fdcId,
    required this.name,
    this.brand,
    this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.saturatedFatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumMgPer100g,
    required this.source,
  });

  final String id;
  final String? fdcId;
  final String name;
  final String? brand;
  final String? category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? saturatedFatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumMgPer100g;

  /// 'usda' or 'local' -- shown in the UI so a user can tell a verified
  /// USDA figure from this app's own reference value for a dish.
  final String source;

  factory Food.fromMap(Map<String, dynamic> map) => Food(
        id: map['id'] as String,
        fdcId: map['fdc_id'] as String?,
        name: map['name'] as String,
        brand: map['brand'] as String?,
        category: map['category'] as String?,
        caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
        proteinPer100g: (map['protein_g_per_100g'] as num?)?.toDouble() ?? 0,
        carbsPer100g: (map['carbs_g_per_100g'] as num?)?.toDouble() ?? 0,
        fatPer100g: (map['fat_g_per_100g'] as num?)?.toDouble() ?? 0,
        saturatedFatPer100g: (map['saturated_fat_g_per_100g'] as num?)?.toDouble(),
        fiberPer100g: (map['fiber_g_per_100g'] as num?)?.toDouble(),
        sugarPer100g: (map['sugar_g_per_100g'] as num?)?.toDouble(),
        sodiumMgPer100g: (map['sodium_mg_per_100g'] as num?)?.toDouble(),
        source: map['source'] as String,
      );

  double caloriesFor(double grams) => caloriesPer100g * grams / 100;
  double proteinFor(double grams) => proteinPer100g * grams / 100;
  double carbsFor(double grams) => carbsPer100g * grams / 100;
  double fatFor(double grams) => fatPer100g * grams / 100;
  double? fiberFor(double grams) => fiberPer100g == null ? null : fiberPer100g! * grams / 100;
  double? sugarFor(double grams) => sugarPer100g == null ? null : sugarPer100g! * grams / 100;
  double? sodiumFor(double grams) => sodiumMgPer100g == null ? null : sodiumMgPer100g! * grams / 100;
}
