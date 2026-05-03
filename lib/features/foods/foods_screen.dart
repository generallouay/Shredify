import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/food.dart';
import '../../core/providers/foods_provider.dart';
import 'widgets/food_card.dart';

class FoodsScreen extends ConsumerWidget {
  const FoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredFoodsProvider);
    final query = ref.watch(foodSearchProvider);
    final typeFilter = ref.watch(foodTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foods', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/foods/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => ref.read(foodSearchProvider.notifier).state = v,
              decoration: const InputDecoration(
                hintText: 'Search foods…',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: typeFilter == null,
                  onTap: () =>
                      ref.read(foodTypeFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Standard',
                  selected: typeFilter == FoodType.standard,
                  onTap: () => ref.read(foodTypeFilterProvider.notifier).state =
                      typeFilter == FoodType.standard
                          ? null
                          : FoodType.standard,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Container',
                  selected: typeFilter == FoodType.container,
                  onTap: () => ref.read(foodTypeFilterProvider.notifier).state =
                      typeFilter == FoodType.container
                          ? null
                          : FoodType.container,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Canister',
                  selected: typeFilter == FoodType.canister,
                  onTap: () => ref.read(foodTypeFilterProvider.notifier).state =
                      typeFilter == FoodType.canister
                          ? null
                          : FoodType.canister,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredAsync.when(
              data: (foods) => foods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant_outlined,
                              size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            query.isNotEmpty
                                ? 'No foods match "$query"'
                                : 'No foods yet',
                            style: const TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: foods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => FoodCard(
                        food: foods[i],
                        onTap: () => context.push('/foods/${foods[i].id}'),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white70,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
