import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/food.dart';
import '../../../core/models/recipe.dart';
import '../../../core/providers/foods_provider.dart';
import '../../shared/widgets/food_photo.dart';

/// Bottom sheet that lets the user pick a food (existing in their library) and
/// enter a weight, or add a custom ingredient (name + weight + optional macros
/// with a multiplier, no need to add to the foods library).
/// Returns the resulting [RecipeIngredient] via Navigator.pop.
class IngredientPickerSheet extends ConsumerStatefulWidget {
  final RecipeIngredient? initial;
  const IngredientPickerSheet({super.key, this.initial});

  @override
  ConsumerState<IngredientPickerSheet> createState() =>
      _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends ConsumerState<IngredientPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _customNameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _multiplierCtrl = TextEditingController(text: '1');
  Food? _selectedFood;
  bool _customMode = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _weightCtrl.text = init.weightGrams.toStringAsFixed(0);
      if (init.food != null) {
        _selectedFood = init.food;
      } else if (init.customName != null) {
        _customMode = true;
        _customNameCtrl.text = init.customName!;
        if (init.customKcal != null) _kcalCtrl.text = _fmt(init.customKcal!);
        if (init.customProtein != null) {
          _proteinCtrl.text = _fmt(init.customProtein!);
        }
        if (init.customCarbs != null) {
          _carbsCtrl.text = _fmt(init.customCarbs!);
        }
        if (init.customFat != null) _fatCtrl.text = _fmt(init.customFat!);
      }
    }
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _weightCtrl.dispose();
    _customNameCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _multiplierCtrl.dispose();
    super.dispose();
  }

  double? _scaled(String text, double mul) {
    final v = double.tryParse(text.trim());
    if (v == null) return null;
    return v * mul;
  }

  void _confirm() {
    final weight = double.tryParse(_weightCtrl.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid weight')));
      return;
    }
    if (_customMode) {
      final name = _customNameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom ingredient needs a name')));
        return;
      }
      final mul = double.tryParse(_multiplierCtrl.text.trim()) ?? 1.0;
      Navigator.pop(
          context,
          RecipeIngredient(
            id: widget.initial?.id ?? const Uuid().v4(),
            customName: name,
            weightGrams: weight,
            customKcal: _scaled(_kcalCtrl.text, mul),
            customProtein: _scaled(_proteinCtrl.text, mul),
            customCarbs: _scaled(_carbsCtrl.text, mul),
            customFat: _scaled(_fatCtrl.text, mul),
          ));
      return;
    }
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick a food or switch to custom')));
      return;
    }
    Navigator.pop(
        context,
        RecipeIngredient(
          id: widget.initial?.id ?? const Uuid().v4(),
          foodId: _selectedFood!.id,
          food: _selectedFood,
          weightGrams: weight,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null ? 'Add ingredient' : 'Edit ingredient',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _customMode = !_customMode),
                  icon: Icon(_customMode
                      ? Icons.search
                      : Icons.edit_note_outlined,
                      size: 18),
                  label: Text(_customMode ? 'Pick food' : 'Custom'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_customMode) _buildCustomMode() else _buildPickMode(),
            const SizedBox(height: 12),
            TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'g',
              ),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _confirm,
                child: Text(widget.initial == null ? 'Add' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _customNameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Ingredient name',
            hintText: 'e.g. Eggs, vanilla extract',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _kcalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Kcal', suffixText: 'kcal'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _proteinCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Protein', suffixText: 'g'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _carbsCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Carbs', suffixText: 'g'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _fatCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Fat', suffixText: 'g'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _multiplierCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Multiplier',
            hintText: '1',
            helperText: 'e.g. 2 for 2× a 100g entry — leave macros blank to skip',
          ),
        ),
      ],
    );
  }

  Widget _buildPickMode() {
    final foodsAsync = ref.watch(foodsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search foods',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _searchCtrl.clear()),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: foodsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (foods) {
              final query = _searchCtrl.text.toLowerCase().trim();
              final filtered = query.isEmpty
                  ? foods
                  : foods
                      .where((f) => f.name.toLowerCase().contains(query))
                      .toList();
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No matching foods',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final f = filtered[i];
                  final selected = _selectedFood?.id == f.id;
                  return Material(
                    color: selected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15)
                        : Colors.transparent,
                    child: ListTile(
                      onTap: () => setState(() => _selectedFood = f),
                      leading:
                          FoodPhoto(photoPath: f.photoPath, width: 36, height: 36),
                      title: Text(f.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${f.kcal.toStringAsFixed(0)} kcal · P${f.protein.toStringAsFixed(0)} C${f.carbs.toStringAsFixed(0)} F${f.fat.toStringAsFixed(0)} per 100g',
                          style: const TextStyle(fontSize: 11)),
                      trailing: selected
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                      dense: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
