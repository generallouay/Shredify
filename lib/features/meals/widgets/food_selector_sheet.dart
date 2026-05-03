import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/food.dart';
import '../../../core/providers/foods_provider.dart';

class FoodSelectorSheet extends ConsumerStatefulWidget {
  const FoodSelectorSheet({super.key});

  @override
  ConsumerState<FoodSelectorSheet> createState() => _FoodSelectorSheetState();
}

class _FoodSelectorSheetState extends ConsumerState<FoodSelectorSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(foodsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
              decoration: const InputDecoration(
                hintText: 'Search foods…',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: foodsAsync.when(
              data: (foods) {
                final filtered = _query.isEmpty
                    ? foods
                    : foods
                        .where(
                            (f) => f.name.toLowerCase().contains(_query))
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No foods found',
                          style: TextStyle(color: Colors.white38)));
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _FoodTile(food: filtered[i]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  final Food food;
  const _FoodTile({required this.food});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(food.name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        '${food.kcal.toStringAsFixed(0)} kcal  •  P ${food.protein.toStringAsFixed(1)}g  •  C ${food.carbs.toStringAsFixed(1)}g  •  F ${food.fat.toStringAsFixed(1)}g',
        style: const TextStyle(fontSize: 12, color: Colors.white54),
      ),
      trailing: Icon(Icons.add_circle_outline,
          color: Theme.of(context).colorScheme.primary),
      onTap: () => context.pop(food),
    );
  }
}
