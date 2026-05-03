enum FoodType { standard, container, canister }

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
  });

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
    bool clearPhoto = false,
    bool clearCanSize = false,
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
