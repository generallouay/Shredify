import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/recipe.dart';
import '../../core/providers/recipes_provider.dart';
import '../shared/widgets/food_photo.dart';
import '../shared/widgets/macro_row.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(filteredRecipesProvider);
    final typeFilter = ref.watch(recipeTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/recipes/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Recipe'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search recipes',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(recipeSearchProvider.notifier).state = '';
                        },
                      ),
              ),
              onChanged: (v) =>
                  ref.read(recipeSearchProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _TypeFilterChip(
                  label: 'All',
                  selected: typeFilter == null,
                  onTap: () =>
                      ref.read(recipeTypeFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                _TypeFilterChip(
                  label: 'High Protein',
                  selected: typeFilter == RecipeType.highProtein,
                  onTap: () => ref
                      .read(recipeTypeFilterProvider.notifier)
                      .state = RecipeType.highProtein,
                ),
                const SizedBox(width: 8),
                _TypeFilterChip(
                  label: 'Standard',
                  selected: typeFilter == RecipeType.standard,
                  onTap: () => ref
                      .read(recipeTypeFilterProvider.notifier)
                      .state = RecipeType.standard,
                ),
              ],
            ),
          ),
          Expanded(
            child: recipesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _RecipeCard(recipe: recipes[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final per = recipe.perServingMacros;
    final isHighProtein = recipe.type == RecipeType.highProtein;
    final accent = isHighProtein
        ? const Color(0xFF00BFA5)
        : Colors.blueGrey;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/recipes/${recipe.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FoodPhoto(
                photoPath: recipe.photoPath,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(10),
                placeholder: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.menu_book_outlined,
                      color: accent, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(recipe.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isHighProtein ? 'High Protein' : 'Standard',
                            style: TextStyle(
                                fontSize: 10,
                                color: accent,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    MacroRow(
                      kcal: per.kcal,
                      protein: per.protein,
                      carbs: per.carbs,
                      fat: per.fat,
                      compact: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'per serving  ·  ${recipe.ingredients.length} ingredient${recipe.ingredients.length == 1 ? '' : 's'}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? color : Colors.white70,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.menu_book_outlined, size: 48, color: Colors.white24),
          SizedBox(height: 12),
          Text('No recipes yet',
              style: TextStyle(color: Colors.white38)),
          SizedBox(height: 4),
          Text('Tap "New Recipe" to add your first',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}
