import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';
import 'auth_provider.dart';

class RecipesNotifier extends StreamNotifier<List<Recipe>> {
  @override
  Stream<List<Recipe>> build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream.value(const <Recipe>[]);
    return ref.watch(recipeRepositoryProvider).watchAll();
  }

  Future<void> add(Recipe recipe) =>
      ref.read(recipeRepositoryProvider).insert(recipe);

  Future<void> save(Recipe recipe) =>
      ref.read(recipeRepositoryProvider).update(recipe);

  Future<void> delete(String id) =>
      ref.read(recipeRepositoryProvider).delete(id);
}

final recipesProvider =
    StreamNotifierProvider<RecipesNotifier, List<Recipe>>(RecipesNotifier.new);

final recipeSearchProvider = StateProvider<String>((ref) => '');
final recipeTypeFilterProvider = StateProvider<RecipeType?>((ref) => null);

final filteredRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final recipesAsync = ref.watch(recipesProvider);
  final query = ref.watch(recipeSearchProvider).toLowerCase().trim();
  final typeFilter = ref.watch(recipeTypeFilterProvider);

  return recipesAsync.whenData((recipes) {
    var list = recipes;
    if (typeFilter != null) {
      list = list.where((r) => r.type == typeFilter).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((r) => r.name.toLowerCase().contains(query)).toList();
    }
    return list;
  });
});
