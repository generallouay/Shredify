import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/food.dart';
import '../../core/models/meal_food_item.dart';
import '../../core/providers/foods_provider.dart';
import 'widgets/measurement_dialog.dart';

class FoodSelectorPage extends ConsumerStatefulWidget {
  const FoodSelectorPage({super.key});

  @override
  ConsumerState<FoodSelectorPage> createState() =>
      _FoodSelectorPageState();
}

class _FoodSelectorPageState extends ConsumerState<FoodSelectorPage> {
  String _query = '';
  FoodType? _typeFilter;

  // canister foods: foodId → count
  final Map<String, int> _canisterCounts = {};

  // standard/container foods: list of added items (same food can appear multiple times)
  final List<MealFoodItem> _nonCanisterItems = [];

  List<MealFoodItem> get _allPending {
    final canisterItems = _canisterCounts.entries.map((e) {
      final food = _foodById(e.key);
      return MealFoodItem(
        id: const Uuid().v4(),
        mealId: '',
        foodId: e.key,
        method: MeasurementMethod.canister,
        canCount: e.value,
        food: food,
      );
    }).toList();
    return [...canisterItems, ..._nonCanisterItems];
  }

  Food? _foodById(String id) {
    final foods = ref.read(foodsProvider).valueOrNull;
    return foods?.where((f) => f.id == id).firstOrNull;
  }

  void _incrementCanister(Food food) {
    setState(() {
      _canisterCounts[food.id] = (_canisterCounts[food.id] ?? 0) + 1;
    });
  }

  void _decrementCanister(Food food) {
    setState(() {
      final current = _canisterCounts[food.id] ?? 0;
      if (current <= 1) {
        _canisterCounts.remove(food.id);
      } else {
        _canisterCounts[food.id] = current - 1;
      }
    });
  }

  Future<void> _addStandardContainer(Food food) async {
    final item = await showDialog<MealFoodItem>(
      context: context,
      builder: (_) => MeasurementDialog(food: food),
    );
    if (item == null) return;
    setState(() {
      _nonCanisterItems.add(item.copyWith(
        id: const Uuid().v4(),
        mealId: '',
      ));
    });
  }

  void _confirm() {
    context.pop(_allPending);
  }

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(foodsProvider);
    final totalAdded = _allPending.length;
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Foods',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: totalAdded > 0 ? _confirm : null,
            child: Text(
              totalAdded > 0 ? 'Done ($totalAdded)' : 'Done',
              style: TextStyle(
                color: totalAdded > 0 ? color : Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _query = v.toLowerCase().trim()),
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
                _FilterChip(label: 'All', selected: _typeFilter == null, color: color,
                    onTap: () => setState(() => _typeFilter = null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Standard', selected: _typeFilter == FoodType.standard, color: color,
                    onTap: () => setState(() => _typeFilter =
                        _typeFilter == FoodType.standard ? null : FoodType.standard)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Container', selected: _typeFilter == FoodType.container, color: color,
                    onTap: () => setState(() => _typeFilter =
                        _typeFilter == FoodType.container ? null : FoodType.container)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Canister', selected: _typeFilter == FoodType.canister, color: color,
                    onTap: () => setState(() => _typeFilter =
                        _typeFilter == FoodType.canister ? null : FoodType.canister)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: foodsAsync.when(
              data: (foods) {
                var filtered = foods;
                if (_typeFilter != null) {
                  filtered = filtered.where((f) => f.type == _typeFilter).toList();
                }
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where((f) => f.name.toLowerCase().contains(_query))
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No foods found',
                          style: TextStyle(color: Colors.white38)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final food = filtered[i];
                    final canCount = _canisterCounts[food.id] ?? 0;
                    final addedCount = _nonCanisterItems
                        .where((item) => item.foodId == food.id)
                        .length;
                    return _FoodTile(
                      food: food,
                      canisterCount: canCount,
                      addedCount: addedCount,
                      onAdd: () => food.type == FoodType.canister
                          ? _incrementCanister(food)
                          : _addStandardContainer(food),
                      onDecrement: food.type == FoodType.canister && canCount > 0
                          ? () => _decrementCanister(food)
                          : null,
                    );
                  },
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
  final int canisterCount;
  final int addedCount;
  final VoidCallback onAdd;
  final VoidCallback? onDecrement;

  const _FoodTile({
    required this.food,
    required this.canisterCount,
    required this.addedCount,
    required this.onAdd,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isCanister = food.type == FoodType.canister;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                _MacroColumn(food: food),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Controls
          if (isCanister) ...[
            if (canisterCount > 0) ...[
              GestureDetector(
                onTap: onDecrement,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.remove, size: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$canisterCount',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color),
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(Icons.add, size: 16, color: color),
              ),
            ),
          ] else ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Icon(Icons.add, size: 16, color: color),
                  ),
                ),
                if (addedCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$addedCount',
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  final Food food;
  const _MacroColumn({required this.food});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: Colors.white54);
    const valueStyle = TextStyle(
        fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${food.kcal.toStringAsFixed(0)} kcal',
            style: valueStyle.copyWith(color: Colors.white)),
        const SizedBox(height: 2),
        _MacroLine(label: 'Protein', value: food.protein, style: style, valueStyle: valueStyle),
        _MacroLine(label: 'Carbs', value: food.carbs, style: style, valueStyle: valueStyle),
        _MacroLine(label: 'Fat', value: food.fat, style: style, valueStyle: valueStyle),
      ],
    );
  }
}

class _MacroLine extends StatelessWidget {
  final String label;
  final double value;
  final TextStyle style;
  final TextStyle valueStyle;

  const _MacroLine(
      {required this.label,
      required this.value,
      required this.style,
      required this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: style),
        ),
        Text('${value.toStringAsFixed(1)}g', style: valueStyle),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : Colors.white70,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
