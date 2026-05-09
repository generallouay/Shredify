import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import '../repositories/meal_repository.dart';
import 'auth_provider.dart';

class MealsNotifier extends StreamNotifier<List<Meal>> {
  @override
  Stream<List<Meal>> build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream.value(const <Meal>[]);
    return ref.watch(mealRepositoryProvider).watchAll();
  }

  Future<void> add(Meal meal) =>
      ref.read(mealRepositoryProvider).insert(meal);

  Future<void> save(Meal meal) =>
      ref.read(mealRepositoryProvider).update(meal);

  Future<void> delete(String id) =>
      ref.read(mealRepositoryProvider).delete(id);
}

final mealsProvider =
    StreamNotifierProvider<MealsNotifier, List<Meal>>(MealsNotifier.new);

final latestMealProvider = Provider<Meal?>((ref) {
  final meals = ref.watch(mealsProvider);
  return meals.whenOrNull(data: (list) => list.isEmpty ? null : list.first);
});
