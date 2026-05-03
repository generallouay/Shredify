import 'meal_food_item.dart';
import 'macro_totals.dart';

class Meal {
  final String id;
  final DateTime createdAt;
  final List<MealFoodItem> items;

  const Meal({
    required this.id,
    required this.createdAt,
    this.items = const [],
  });

  MacroTotals get totals => items.fold(
        MacroTotals.zero,
        (acc, item) => item.macros != null ? acc + item.macros! : acc,
      );

  bool get isCalculated =>
      items.isNotEmpty && items.every((item) => item.consumedGrams != null);

  Meal copyWith({
    String? id,
    DateTime? createdAt,
    List<MealFoodItem>? items,
  }) =>
      Meal(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        items: items ?? this.items,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Meal.fromMap(Map<String, dynamic> map,
          {List<MealFoodItem> items = const []}) =>
      Meal(
        id: map['id'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        items: items,
      );
}
