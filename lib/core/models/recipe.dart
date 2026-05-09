import 'food.dart';
import 'macro_totals.dart';

enum RecipeType { highProtein, standard }

class RecipeIngredient {
  final String id;
  final String? foodId;
  final Food? food;
  final String? customName;
  final double weightGrams;

  const RecipeIngredient({
    required this.id,
    this.foodId,
    this.food,
    this.customName,
    required this.weightGrams,
  });

  String get displayName => food?.name ?? customName ?? 'Ingredient';

  MacroTotals get macros {
    final f = food;
    if (f == null) return MacroTotals.zero;
    final factor = weightGrams / 100.0;
    return MacroTotals(
      kcal: f.kcal * factor,
      protein: f.protein * factor,
      fat: f.fat * factor,
      carbs: f.carbs * factor,
    );
  }

  RecipeIngredient copyWith({
    String? id,
    String? foodId,
    Food? food,
    String? customName,
    double? weightGrams,
  }) =>
      RecipeIngredient(
        id: id ?? this.id,
        foodId: foodId ?? this.foodId,
        food: food ?? this.food,
        customName: customName ?? this.customName,
        weightGrams: weightGrams ?? this.weightGrams,
      );
}

class Recipe {
  final String id;
  final String name;
  final RecipeType type;
  final int servings;
  final String? photoPath;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final DateTime createdAt;

  const Recipe({
    required this.id,
    required this.name,
    required this.type,
    this.servings = 1,
    this.photoPath,
    this.ingredients = const [],
    this.steps = const [],
    required this.createdAt,
  });

  MacroTotals get totalMacros => ingredients.fold<MacroTotals>(
      MacroTotals.zero, (acc, i) => acc + i.macros);

  MacroTotals get perServingMacros {
    if (servings <= 0) return totalMacros;
    final t = totalMacros;
    return MacroTotals(
      kcal: t.kcal / servings,
      protein: t.protein / servings,
      fat: t.fat / servings,
      carbs: t.carbs / servings,
    );
  }

  Recipe copyWith({
    String? id,
    String? name,
    RecipeType? type,
    int? servings,
    String? photoPath,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    DateTime? createdAt,
    bool clearPhoto = false,
  }) =>
      Recipe(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        servings: servings ?? this.servings,
        photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        createdAt: createdAt ?? this.createdAt,
      );
}
