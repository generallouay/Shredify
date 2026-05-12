import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/food.dart';
import '../../../core/models/recipe.dart';
import '../../../core/providers/foods_provider.dart';
import '../../shared/widgets/food_photo.dart';

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
  double _unitCount = 1.0;
  bool _customMode = false;

  bool get _isCountable => _selectedFood?.isCountable ?? false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      if (init.food != null) {
        _selectedFood = init.food;
        if (init.food!.isCountable && init.food!.canSize != null) {
          _unitCount = (init.weightGrams / init.food!.canSize!).clamp(0.5, 999);
        } else {
          _weightCtrl.text = init.weightGrams.toStringAsFixed(0);
        }
      } else if (init.customName != null) {
        _customMode = true;
        _customNameCtrl.text = init.customName!;
        _weightCtrl.text = init.weightGrams.toStringAsFixed(0);
        if (init.customKcal != null) _kcalCtrl.text = _fmt(init.customKcal!);
        if (init.customProtein != null) {
          _proteinCtrl.text = _fmt(init.customProtein!);
        }
        if (init.customCarbs != null) _carbsCtrl.text = _fmt(init.customCarbs!);
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
    if (_customMode) {
      final name = _customNameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom ingredient needs a name')));
        return;
      }
      final weight = double.tryParse(_weightCtrl.text);
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid weight')));
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

    final double weightGrams;
    if (_isCountable) {
      final canSize = _selectedFood!.canSize;
      if (canSize == null || canSize <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This food has no unit weight set')));
        return;
      }
      weightGrams = _unitCount * canSize;
    } else {
      final w = double.tryParse(_weightCtrl.text);
      if (w == null || w <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid weight')));
        return;
      }
      weightGrams = w;
    }

    Navigator.pop(
        context,
        RecipeIngredient(
          id: widget.initial?.id ?? const Uuid().v4(),
          foodId: _selectedFood!.id,
          food: _selectedFood,
          weightGrams: weightGrams,
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
            if (!_customMode && _isCountable)
              _buildCountStepper()
            else
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

  Widget _buildCountStepper() {
    final food = _selectedFood!;
    final label = food.effectiveUnitLabel;
    final grams = food.canSize != null
        ? (_unitCount * food.canSize!).toStringAsFixed(0)
        : '?';
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepBtn(
              icon: Icons.remove,
              onTap: _unitCount > 0.5
                  ? () => setState(() => _unitCount -= 0.5)
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(
                  _unitCount == _unitCount.truncateToDouble()
                      ? '${_unitCount.toInt()} $label'
                      : '${_unitCount.toStringAsFixed(1)} $label',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
                Text('≈ ${grams}g',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white38)),
              ],
            ),
            const SizedBox(width: 16),
            _StepBtn(
              icon: Icons.add,
              onTap: () => setState(() => _unitCount += 0.5),
            ),
          ],
        ),
      ],
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
            helperText:
                'e.g. 2 for 2× a 100g entry — leave macros blank to skip',
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
            loading: () => const Center(child: CircularProgressIndicator()),
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
                      onTap: () => setState(() {
                        _selectedFood = f;
                        _unitCount = 1.0;
                      }),
                      leading: FoodPhoto(
                          photoPath: f.photoPath, width: 36, height: 36),
                      title: Text(f.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        f.isCountable && f.canSize != null
                            ? '${f.kcal.toStringAsFixed(0)} kcal · P${f.protein.toStringAsFixed(0)} C${f.carbs.toStringAsFixed(0)} F${f.fat.toStringAsFixed(0)} per 100g  ·  ${f.canSize!.toStringAsFixed(0)}g/${f.effectiveUnitLabel}'
                            : '${f.kcal.toStringAsFixed(0)} kcal · P${f.protein.toStringAsFixed(0)} C${f.carbs.toStringAsFixed(0)} F${f.fat.toStringAsFixed(0)} per 100g',
                        style: const TextStyle(fontSize: 11),
                      ),
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

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.15)
              : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap != null ? color : Colors.white24),
      ),
    );
  }
}
