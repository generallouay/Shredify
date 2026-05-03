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
  FoodType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(foodsProvider);
    final color = Theme.of(context).colorScheme.primary;

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
              onChanged: (v) =>
                  setState(() => _query = v.toLowerCase().trim()),
              decoration: const InputDecoration(
                hintText: 'Search foods…',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Chip(
                  label: 'All',
                  selected: _typeFilter == null,
                  color: color,
                  onTap: () => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Standard',
                  selected: _typeFilter == FoodType.standard,
                  color: color,
                  onTap: () => setState(() => _typeFilter =
                      _typeFilter == FoodType.standard
                          ? null
                          : FoodType.standard),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Container',
                  selected: _typeFilter == FoodType.container,
                  color: color,
                  onTap: () => setState(() => _typeFilter =
                      _typeFilter == FoodType.container
                          ? null
                          : FoodType.container),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Canister',
                  selected: _typeFilter == FoodType.canister,
                  color: color,
                  onTap: () => setState(() => _typeFilter =
                      _typeFilter == FoodType.canister
                          ? null
                          : FoodType.canister),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: foodsAsync.when(
              data: (foods) {
                var filtered = foods;
                if (_typeFilter != null) {
                  filtered = filtered
                      .where((f) => f.type == _typeFilter)
                      .toList();
                }
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                          (f) => f.name.toLowerCase().contains(_query))
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No foods found',
                          style: TextStyle(color: Colors.white38)));
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF2C2C2E),
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
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
