/// One entry in the public exercise catalog (`public.exercises`).
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final String equipment;
  final String description;

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as String,
        name: map['name'] as String,
        category: map['category'] as String,
        equipment: map['equipment'] as String,
        description: map['description'] as String? ?? '',
      );
}
