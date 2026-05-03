class QuickEntry {
  final String id;
  final DateTime createdAt;
  final double kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? description;

  const QuickEntry({
    required this.id,
    required this.createdAt,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.description,
  });

  QuickEntry copyWith({
    String? id,
    DateTime? createdAt,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    String? description,
  }) =>
      QuickEntry(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        description: description ?? this.description,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'created_at': createdAt.millisecondsSinceEpoch,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'description': description,
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
      );
}
