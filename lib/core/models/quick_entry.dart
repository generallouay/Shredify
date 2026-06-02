class QuickEntry {
  final String id;
  final DateTime createdAt;
  final double kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? description;
  // Original user inputs (pre-multiplier) preserved so editing reopens the
  // entry with the same numbers the user typed.
  final double? rawKcal;
  final double? rawProtein;
  final double? rawCarbs;
  final double? rawFat;
  final double? multiplier;

  const QuickEntry({
    required this.id,
    required this.createdAt,
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

  QuickEntry copyWith({
    String? id,
    DateTime? createdAt,
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
      QuickEntry(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
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
        'created_at': createdAt.millisecondsSinceEpoch,
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

  factory QuickEntry.fromMap(Map<String, dynamic> m) => QuickEntry(
        id: m['id'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
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
