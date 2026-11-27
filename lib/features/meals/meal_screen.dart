import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/meal.dart';
import '../../core/models/meal_entry.dart';
import '../../core/models/meal_food_item.dart';
import '../../core/models/macro_totals.dart';
import '../../core/providers/foods_provider.dart';
import '../../core/providers/meals_provider.dart';
import '../../core/repositories/meal_repository.dart';
import 'widgets/meal_food_item_card.dart';
import 'widgets/meal_entry_card.dart';
import 'widgets/meal_entry_dialog.dart';
import 'widgets/measurement_dialog.dart';

class MealScreen extends ConsumerStatefulWidget {
  final String? mealId;

  /// When set (and [mealId] is null), the new meal starts as a copy of this
  /// meal's foods and entries, timestamped now.
  final String? copyFromId;
  const MealScreen({super.key, this.mealId, this.copyFromId});

  @override
  ConsumerState<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends ConsumerState<MealScreen> {
  List<MealFoodItem> _items = [];
  List<MealEntry> _entries = [];
  DateTime _createdAt = DateTime.now();
  bool _loading = true;
  Meal? _original;

  // Focus nodes for the inline "weight after" inputs, keyed by item id, so we
  // can hop focus to the next container item awaiting a weight.
  final Map<String, FocusNode> _weightAfterNodes = {};

  bool get _isNew => widget.mealId == null;
  bool get _isCopy => _isNew && widget.copyFromId != null;

  FocusNode _weightAfterNode(String id) =>
      _weightAfterNodes.putIfAbsent(id, () => FocusNode());

  @override
  void dispose() {
    for (final node in _weightAfterNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_isCopy) {
      _loadCopy();
    } else if (_isNew) {
      _loading = false;
    } else {
      _loadMeal();
    }
  }

  Future<void> _loadMeal() async {
    final meal = await ref.read(mealRepositoryProvider).getById(widget.mealId!);
    final items = meal == null ? null : await _withLiveUnitLabels(meal.items);
    if (meal != null && mounted) {
      setState(() {
        _original = meal;
        _items = items!;
        _entries = List.from(meal.entries);
        _createdAt = meal.createdAt;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCopy() async {
    final source =
        await ref.read(mealRepositoryProvider).getById(widget.copyFromId!);
    final items = source == null ? null : await _withLiveUnitLabels(source.items);
    if (!mounted) return;
    setState(() {
      if (source != null) {
        const uuid = Uuid();
        _items = items!
            .map((i) => i.copyWith(id: uuid.v4(), mealId: ''))
            .toList();
        _entries = source.entries
            .map((e) => e.copyWith(id: uuid.v4(), mealId: ''))
            .toList();
      }
      _createdAt = DateTime.now();
      _loading = false;
    });
  }

  /// Meals saved before the unit label was stored in the food snapshot show
  /// "unit"/"can" instead of e.g. "scoop". Fill the label in from the live
  /// food when the snapshot is missing it.
  Future<List<MealFoodItem>> _withLiveUnitLabels(
      List<MealFoodItem> items) async {
    if (!items.any((i) => i.food != null && i.food!.unitLabel == null)) {
      return List.from(items);
    }
    var foods = ref.read(foodsProvider).valueOrNull;
    foods ??= await ref
        .read(foodsProvider.future)
        .timeout(const Duration(seconds: 3), onTimeout: () => const []);
    final byId = {for (final f in foods) f.id: f};
    return items.map((i) {
      final snap = i.food;
      final live = byId[i.foodId];
      if (snap == null || snap.unitLabel != null || live?.unitLabel == null) {
        return i;
      }
      return i.copyWith(food: snap.copyWith(unitLabel: live!.unitLabel));
    }).toList();
  }

  void _copyMeal() {
    context.pushReplacement('/meals/new?copyFrom=${_original!.id}');
  }

  Future<void> _addFood() async {
    final items = await context.push<List<MealFoodItem>>('/food-selector');
    if (items == null || items.isEmpty || !mounted) return;
    setState(() {
      _items.addAll(items.map(
        (i) => i.copyWith(id: const Uuid().v4(), mealId: _original?.id ?? ''),
      ));
    });
  }

  Future<void> _addEntry() async {
    final entry = await showDialog<MealEntry>(
      context: context,
      builder: (_) => const MealEntryDialog(),
    );
    if (entry == null || !mounted) return;
    setState(() => _entries.add(entry));
  }

  Future<void> _editEntry(int index) async {
    final edited = await showDialog<MealEntry>(
      context: context,
      builder: (_) => MealEntryDialog(initialEntry: _entries[index]),
    );
    if (edited == null || !mounted) return;
    setState(() => _entries[index] = edited);
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    if (item.food == null) return;
    final edited = await showDialog<MealFoodItem>(
      context: context,
      builder: (_) =>
          MeasurementDialog(food: item.food!, initialItem: item),
    );
    if (edited == null || !mounted) return;
    setState(() => _items[index] = edited);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  void _updateWeightAfter(int index, double weightAfter) {
    setState(() {
      _items[index] = _items[index].copyWith(weightAfter: weightAfter);
    });
    // After the list rebuilds, jump to the next container item that still
    // needs a weight-after so the user can keep typing without tapping around.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nextId = _nextWeightAfterItemId(after: index);
      if (nextId != null) {
        _weightAfterNodes[nextId]?.requestFocus();
      }
    });
  }

  String? _nextWeightAfterItemId({required int after}) {
    bool needsWeight(MealFoodItem it) =>
        it.method == MeasurementMethod.container && it.weightAfter == null;
    // Look forward first, then wrap to the start.
    for (var i = after + 1; i < _items.length; i++) {
      if (needsWeight(_items[i])) return _items[i].id;
    }
    for (var i = 0; i <= after && i < _items.length; i++) {
      if (needsWeight(_items[i])) return _items[i].id;
    }
    return null;
  }

  Future<void> _save() async {
    if (_items.isEmpty && _entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one food or entry')));
      return;
    }
    final mealId = _original?.id ?? const Uuid().v4();
    final meal = Meal(
      id: mealId,
      createdAt: _createdAt,
      items: _items.map((i) => i.copyWith(mealId: mealId)).toList(),
      entries: _entries.map((e) => e.copyWith(mealId: mealId)).toList(),
    );
    try {
      if (_isNew) {
        await ref.read(mealsProvider.notifier).add(meal);
      } else {
        await ref.read(mealsProvider.notifier).save(meal);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save meal: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete meal?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(mealsProvider.notifier).delete(_original!.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete meal: $e')));
      }
    }
  }

  MacroTotals get _totals {
    final itemTotals = _items.fold(
        MacroTotals.zero,
        (acc, item) => item.macros != null ? acc + item.macros! : acc);
    final entryTotals = _entries.fold(
        MacroTotals.zero,
        (acc, e) => acc +
            MacroTotals(
                kcal: e.kcal,
                protein: e.protein ?? 0,
                carbs: e.carbs ?? 0,
                fat: e.fat ?? 0));
    return itemTotals + entryTotals;
  }

  bool get _hasContent => _items.isNotEmpty || _entries.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build a unified list: food items first, then entries
    final totalCount = _items.length + _entries.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCopy ? 'Copy Meal' : _isNew ? 'New Meal' : 'Edit Meal'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copy to today',
              onPressed: _copyMeal,
            ),
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _save,
            child: Text(_isNew ? 'Save' : 'Update'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !_hasContent
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline,
                            size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text('Nothing added yet',
                            style: TextStyle(color: Colors.white38)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _addEntry,
                              icon: const Icon(Icons.bolt_outlined, size: 18),
                              label: const Text('Add Entry'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _addFood,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Food'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: totalCount,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i < _items.length) {
                        return MealFoodItemCard(
                          item: _items[i],
                          showMacros: true,
                          onTap: () => _editItem(i),
                          onWeightAfterChanged: (v) =>
                              _updateWeightAfter(i, v),
                          weightAfterFocusNode:
                              _weightAfterNode(_items[i].id),
                          onDelete: () => _removeItem(i),
                        );
                      }
                      final ei = i - _items.length;
                      return MealEntryCard(
                        entry: _entries[ei],
                        onTap: () => _editEntry(ei),
                        onDelete: () => _removeEntry(ei),
                      );
                    },
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
                if (_hasContent) _TotalsCard(totals: _totals),
                if (_hasContent) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addEntry,
                        icon: const Icon(Icons.bolt_outlined, size: 18),
                        label: const Text('Add Entry'),
                      ),
                    ),
                    const SizedBox(width: 10),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
