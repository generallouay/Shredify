import 'food.dart';
import 'macro_totals.dart';

enum MeasurementMethod { standard, container, canister }

class MealFoodItem {
  final String id;
  final String mealId;
  final String foodId;
  final MeasurementMethod method;
  final double? weightGrams;
  final double? weightBefore;
  final double? weightAfter;
  final int? canCount;
  final Food? food;

  const MealFoodItem({
    required this.id,
    required this.mealId,
    required this.foodId,
    required this.method,
    this.weightGrams,
    this.weightBefore,
    this.weightAfter,
    this.canCount,
    this.food,
  });

  double? get consumedGrams {
    switch (method) {
      case MeasurementMethod.standard:
        return weightGrams;
      case MeasurementMethod.container:
        if (weightBefore != null && weightAfter != null) {
          return (weightBefore! - weightAfter!).clamp(0, double.infinity);
        }
        return null;
      case MeasurementMethod.canister:
        if (canCount != null && food?.canSize != null) {
          return canCount! * food!.canSize!;
        }
        return null;
    }
  }

  MacroTotals? get macros {
    final grams = consumedGrams;
    final f = food;
    if (grams == null || f == null) return null;
    final factor = grams / 100.0;
    return MacroTotals(
      kcal: f.kcal * factor,
      protein: f.protein * factor,
      fat: f.fat * factor,
      carbs: f.carbs * factor,
    );
  }

  MealFoodItem copyWith({
    String? id,
    String? mealId,
    String? foodId,
    MeasurementMethod? method,
    double? weightGrams,
    double? weightBefore,
    double? weightAfter,
    int? canCount,
    Food? food,
    bool clearWeightAfter = false,
  }) =>
      MealFoodItem(
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        foodId: foodId ?? this.foodId,
        method: method ?? this.method,
        weightGrams: weightGrams ?? this.weightGrams,
        weightBefore: weightBefore ?? this.weightBefore,
        weightAfter: clearWeightAfter ? null : (weightAfter ?? this.weightAfter),
        canCount: canCount ?? this.canCount,
        food: food ?? this.food,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'meal_id': mealId,
        'food_id': foodId,
        'method': method.name,
        'weight_grams': weightGrams,
        'weight_before': weightBefore,
        'weight_after': weightAfter,
        'can_count': canCount,
      };

  factory MealFoodItem.fromMap(Map<String, dynamic> map, {Food? food}) =>
      MealFoodItem(
        id: map['id'] as String,
        mealId: map['meal_id'] as String,
        foodId: map['food_id'] as String,
        method: MeasurementMethod.values
            .byName((map['method'] as String?) ?? 'standard'),
        weightGrams: map['weight_grams'] != null
            ? (map['weight_grams'] as num).toDouble()
            : null,
        weightBefore: map['weight_before'] != null
            ? (map['weight_before'] as num).toDouble()
            : null,
        weightAfter: map['weight_after'] != null
            ? (map['weight_after'] as num).toDouble()
            : null,
        canCount: map['can_count'] as int?,
        food: food,
      );
}
