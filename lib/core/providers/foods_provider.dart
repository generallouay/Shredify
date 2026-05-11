import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food.dart';
import '../repositories/food_repository.dart';
import 'auth_provider.dart';
import 'meals_provider.dart';

class FoodsNotifier extends StreamNotifier<List<Food>> {
  @override
  Stream<List<Food>> build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream.value(const <Food>[]);
    return ref.watch(foodRepositoryProvider).watchAll();
  }

  Future<void> add(Food food) =>
      ref.read(foodRepositoryProvider).insert(food);

  Future<void> save(Food food) =>
      ref.read(foodRepositoryProvider).update(food);

  Future<void> delete(String id) =>
      ref.read(foodRepositoryProvider).delete(id);
}

final foodsProvider =
    StreamNotifierProvider<FoodsNotifier, List<Food>>(FoodsNotifier.new);

/// foodId → number of times that food has appeared across all logged meals.
/// Used to sort the food selector by most-used first.
final foodUsageCountProvider = Provider<Map<String, int>>((ref) {
  final meals = ref.watch(mealsProvider).valueOrNull ?? const [];
  final counts = <String, int>{};
  for (final meal in meals) {
    for (final item in meal.items) {
      counts[item.foodId] = (counts[item.foodId] ?? 0) + 1;
    }
  }
  return counts;
});

final foodSearchProvider = StateProvider<String>((ref) => '');

final foodTypeFilterProvider = StateProvider<FoodType?>((ref) => null);

final filteredFoodsProvider = Provider<AsyncValue<List<Food>>>((ref) {
  final foodsAsync = ref.watch(foodsProvider);
  final query = ref.watch(foodSearchProvider).toLowerCase().trim();
  final typeFilter = ref.watch(foodTypeFilterProvider);

  return foodsAsync.whenData((foods) {
    var list = foods;
    if (typeFilter != null) {
      list = list.where((f) => f.type == typeFilter).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((f) => f.name.toLowerCase().contains(query)).toList();
    }
    return list;
  });
});
