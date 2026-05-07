import 'meal_food_item.dart';
import 'meal_entry.dart';
import 'macro_totals.dart';

class Meal {
  final String id;
  final DateTime createdAt;
  final List<MealFoodItem> items;
  final List<MealEntry> entries;

  const Meal({
    required this.id,
    required this.createdAt,
    this.items = const [],
    this.entries = const [],
  });

  MacroTotals get totals {
    final itemTotals = items.fold(
        MacroTotals.zero,
        (acc, item) => item.macros != null ? acc + item.macros! : acc);
    final entryTotals = entries.fold(
        MacroTotals.zero,
        (acc, e) => acc +
            MacroTotals(
                kcal: e.kcal,
                protein: e.protein ?? 0,
                carbs: e.carbs ?? 0,
                fat: e.fat ?? 0));
    return itemTotals + entryTotals;
  }

  bool get isCalculated =>
      items.isNotEmpty && items.every((item) => item.consumedGrams != null);

  Meal copyWith({
    String? id,
    DateTime? createdAt,
    List<MealFoodItem>? items,
    List<MealEntry>? entries,
  }) =>
      Meal(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        items: items ?? this.items,
        entries: entries ?? this.entries,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Meal.fromMap(Map<String, dynamic> map,
          {List<MealFoodItem> items = const [],
          List<MealEntry> entries = const []}) =>
      Meal(
        id: map['id'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        items: items,
        entries: entries,
      );
}
