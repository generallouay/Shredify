class MealEntry {
  final String id;
  final String mealId;
  final double kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? description;
  // Original user inputs (pre-multiplier) preserved so editing reopens the
  // entry with the same numbers the user typed. Nullable for backward compat
  // with entries saved before this field existed.
  final double? rawKcal;
  final double? rawProtein;
  final double? rawCarbs;
  final double? rawFat;
  final double? multiplier;

  const MealEntry({
    required this.id,
    required this.mealId,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.description,
    this.rawKcal,
    this.rawProtein,
    this.rawCarbs,
    this.rawFat,
    this.multiplier,
  });

  MealEntry copyWith({
    String? id,
    String? mealId,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    String? description,
    double? rawKcal,
    double? rawProtein,
    double? rawCarbs,
    double? rawFat,
    double? multiplier,
  }) =>
      MealEntry(
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        description: description ?? this.description,
        rawKcal: rawKcal ?? this.rawKcal,
        rawProtein: rawProtein ?? this.rawProtein,
        rawCarbs: rawCarbs ?? this.rawCarbs,
        rawFat: rawFat ?? this.rawFat,
        multiplier: multiplier ?? this.multiplier,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'meal_id': mealId,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'description': description,
        'raw_kcal': rawKcal,
        'raw_protein': rawProtein,
        'raw_carbs': rawCarbs,
        'raw_fat': rawFat,
        'multiplier': multiplier,
      };

  factory MealEntry.fromMap(Map<String, dynamic> m) => MealEntry(
        id: m['id'] as String,
        mealId: m['meal_id'] as String,
        kcal: (m['kcal'] as num).toDouble(),
        protein: (m['protein'] as num?)?.toDouble(),
        carbs: (m['carbs'] as num?)?.toDouble(),
        fat: (m['fat'] as num?)?.toDouble(),
        description: m['description'] as String?,
        rawKcal: (m['raw_kcal'] as num?)?.toDouble(),
        rawProtein: (m['raw_protein'] as num?)?.toDouble(),
        rawCarbs: (m['raw_carbs'] as num?)?.toDouble(),
        rawFat: (m['raw_fat'] as num?)?.toDouble(),
        multiplier: (m['multiplier'] as num?)?.toDouble(),
      );
}
