class MealEntry {
  final String id;
  final String mealId;
  final double kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? description;

  const MealEntry({
    required this.id,
    required this.mealId,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.description,
  });

  MealEntry copyWith({
    String? id,
    String? mealId,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    String? description,
  }) =>
      MealEntry(
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        description: description ?? this.description,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'meal_id': mealId,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'description': description,
      };

  factory MealEntry.fromMap(Map<String, dynamic> m) => MealEntry(
        id: m['id'] as String,
        mealId: m['meal_id'] as String,
        kcal: (m['kcal'] as num).toDouble(),
        protein: (m['protein'] as num?)?.toDouble(),
        carbs: (m['carbs'] as num?)?.toDouble(),
        fat: (m['fat'] as num?)?.toDouble(),
        description: m['description'] as String?,
      );
}
