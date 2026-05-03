import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food.dart';
import 'database_provider.dart';

final foodsProvider =
    AsyncNotifierProvider<FoodsNotifier, List<Food>>(FoodsNotifier.new);

class FoodsNotifier extends AsyncNotifier<List<Food>> {
  @override
  Future<List<Food>> build() => ref.read(foodDaoProvider).getAll();

  Future<void> add(Food food) async {
    await ref.read(foodDaoProvider).insert(food);
    ref.invalidateSelf();
  }

  Future<void> save(Food food) async {
    await ref.read(foodDaoProvider).update(food);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(foodDaoProvider).delete(id);
    ref.invalidateSelf();
  }

  Future<void> reload() async => ref.invalidateSelf();
}

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
