enum FoodType { standard, container, canister, unit }

class Food {
  final String id;
  final String name;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final FoodType type;
  final double? canSize;
  final String? photoPath;
  final String? unitLabel;

  const Food({
    required this.id,
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.type,
    this.canSize,
    this.photoPath,
    this.unitLabel,
  });

  /// Whether this food is measured in discrete units (canister or unit type).
  bool get isCountable => type == FoodType.canister || type == FoodType.unit;

  /// The label for one unit, e.g. "egg", "tsp", "can". Falls back by type.
  String get effectiveUnitLabel {
    if (unitLabel != null && unitLabel!.isNotEmpty) return unitLabel!;
    return type == FoodType.canister ? 'can' : 'unit';
  }

  Food copyWith({
    String? id,
    String? name,
    double? kcal,
    double? protein,
    double? fat,
    double? carbs,
    FoodType? type,
    double? canSize,
    String? photoPath,
    String? unitLabel,
    bool clearPhoto = false,
    bool clearCanSize = false,
    bool clearUnitLabel = false,
  }) =>
      Food(
        id: id ?? this.id,
        name: name ?? this.name,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        fat: fat ?? this.fat,
        carbs: carbs ?? this.carbs,
        type: type ?? this.type,
        canSize: clearCanSize ? null : (canSize ?? this.canSize),
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
        unitLabel: clearUnitLabel ? null : (unitLabel ?? this.unitLabel),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'kcal': kcal,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'type': type.name,
        'can_size': canSize,
        'photo_path': photoPath,
      };

  factory Food.fromMap(Map<String, dynamic> map) => Food(
        id: map['id'] as String,
        name: map['name'] as String,
        kcal: (map['kcal'] as num).toDouble(),
        protein: (map['protein'] as num).toDouble(),
        fat: (map['fat'] as num).toDouble(),
        carbs: (map['carbs'] as num).toDouble(),
        type: FoodType.values.byName((map['type'] as String?) ?? 'standard'),
        canSize: map['can_size'] != null ? (map['can_size'] as num).toDouble() : null,
        photoPath: map['photo_path'] as String?,
      );
}
