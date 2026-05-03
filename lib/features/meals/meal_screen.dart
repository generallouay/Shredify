import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/food.dart';
import '../../core/models/meal.dart';
import '../../core/models/meal_food_item.dart';
import '../../core/models/macro_totals.dart';
import '../../core/providers/meals_provider.dart';
import '../../core/providers/database_provider.dart';
import 'widgets/food_selector_sheet.dart';
import 'widgets/meal_food_item_card.dart';
import 'widgets/measurement_dialog.dart';

class MealScreen extends ConsumerStatefulWidget {
  final String? mealId;
  const MealScreen({super.key, this.mealId});

  @override
  ConsumerState<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends ConsumerState<MealScreen> {
  List<MealFoodItem> _items = [];
  DateTime _createdAt = DateTime.now();
  bool _calculated = false;
  bool _loading = true;
  Meal? _original;

  bool get _isNew => widget.mealId == null;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _loading = false;
    } else {
      _loadMeal();
    }
  }

  Future<void> _loadMeal() async {
    final meal = await ref.read(mealDaoProvider).getById(widget.mealId!);
    if (meal != null && mounted) {
      setState(() {
        _original = meal;
        _items = List.from(meal.items);
        _createdAt = meal.createdAt;
        _calculated = meal.isCalculated;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addFood() async {
    final food = await showModalBottomSheet<Food>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const FoodSelectorSheet(),
    );
    if (food == null || !mounted) return;

    final item = await showDialog<MealFoodItem>(
      context: context,
      builder: (_) => MeasurementDialog(food: food),
    );
    if (item == null) return;

    setState(() {
      _items.add(item.copyWith(
        id: const Uuid().v4(),
        mealId: _original?.id ?? '',
      ));
      _calculated = false;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculated = false;
    });
  }

  void _updateWeightAfter(int index, double weightAfter) {
    setState(() {
      _items[index] = _items[index].copyWith(weightAfter: weightAfter);
    });
  }

  void _calculate() {
    setState(() => _calculated = true);
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one food')));
      return;
    }
    final mealId = _original?.id ?? const Uuid().v4();
    final meal = Meal(
      id: mealId,
      createdAt: _createdAt,
      items: _items.map((i) => i.copyWith(mealId: mealId)).toList(),
    );
    if (_isNew) {
      await ref.read(mealsProvider.notifier).add(meal);
    } else {
      await ref.read(mealsProvider.notifier).save(meal);
    }
    if (mounted) context.pop();
  }

  MacroTotals get _totals => _items.fold(
        MacroTotals.zero,
        (acc, item) => item.macros != null ? acc + item.macros! : acc,
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Meal' : 'Edit Meal'),
        actions: [
          TextButton(
            onPressed: _save,
            child:
                Text(_isNew ? 'Save' : 'Update'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline,
                            size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text('No foods added yet',
                            style: TextStyle(color: Colors.white38)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _addFood,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Food'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => MealFoodItemCard(
                      item: _items[i],
                      showMacros: _calculated,
                      onWeightAfterChanged: (v) => _updateWeightAfter(i, v),
                      onDelete: () => _removeItem(i),
                    ),
                  ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              border: Border(top: BorderSide(color: Color(0xFF2C2C2E))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_calculated && _items.isNotEmpty)
                  _TotalsCard(totals: _totals),
                if (_calculated && _items.isNotEmpty)
                  const SizedBox(height: 10),
                Row(
                  children: [
                    if (_items.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _calculate,
                          icon: const Icon(Icons.calculate_outlined, size: 18),
                          label: const Text('Calculate'),
                        ),
                      ),
                    if (_items.isNotEmpty) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _addFood,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Food'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final MacroTotals totals;
  const _TotalsCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Total(label: 'kcal', value: totals.kcal, decimals: 0),
          _Total(label: 'Protein', value: totals.protein),
          _Total(label: 'Carbs', value: totals.carbs),
          _Total(label: 'Fat', value: totals.fat),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final double value;
  final int decimals;
  const _Total(
      {required this.label, required this.value, this.decimals = 1});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final text = value.toStringAsFixed(decimals);
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label copied: $text')));
      },
      child: Column(
        children: [
          Text(value.toStringAsFixed(decimals),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }
}
