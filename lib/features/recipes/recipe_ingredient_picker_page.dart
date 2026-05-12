import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/food.dart';
import '../../core/models/recipe.dart';
import '../../core/providers/foods_provider.dart';
import '../shared/widgets/food_photo.dart';
import '../shared/widgets/macro_row.dart';

/// Full-screen ingredient picker for recipes, mirroring the meal food
/// selector UX — search, filter chips, usage-sorted list.
///
/// Tapping a food opens a measurement sheet appropriate for its type.
/// A "Custom" button opens an ad-hoc macro entry sheet.
///
/// Returns a [RecipeIngredient] via [Navigator.pop].
class RecipeIngredientPickerPage extends ConsumerStatefulWidget {
  final RecipeIngredient? initial;
  const RecipeIngredientPickerPage({super.key, this.initial});

  @override
  ConsumerState<RecipeIngredientPickerPage> createState() =>
      _RecipeIngredientPickerPageState();
}

class _RecipeIngredientPickerPageState
    extends ConsumerState<RecipeIngredientPickerPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  FoodType? _typeFilter;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      if (init.customName != null) {
        // Custom ingredient — open custom sheet immediately after first frame
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openCustomSheet(initial: init);
        });
      } else if (init.food != null) {
        // Food ingredient — open measurement sheet immediately after first frame
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openMeasurementSheet(init.food!, initial: init);
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMeasurementSheet(Food food,
      {RecipeIngredient? initial}) async {
    final result = await showModalBottomSheet<RecipeIngredient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MeasurementSheet(food: food, initial: initial),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  Future<void> _openCustomSheet({RecipeIngredient? initial}) async {
    final result = await showModalBottomSheet<RecipeIngredient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CustomIngredientSheet(initial: initial),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(foodsProvider);
    final usageCounts = ref.watch(foodUsageCountProvider);
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Add Ingredient' : 'Change Ingredient',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => _openCustomSheet(
                initial: widget.initial?.food == null ? widget.initial : null),
            icon: const Icon(Icons.edit_note_outlined, size: 18),
            label: const Text('Custom'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
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
                _Chip(label: 'All', selected: _typeFilter == null, color: color,
                    onTap: () => setState(() => _typeFilter = null)),
                const SizedBox(width: 8),
                _Chip(label: 'Standard', selected: _typeFilter == FoodType.standard, color: color,
                    onTap: () => setState(() => _typeFilter =
                        _typeFilter == FoodType.standard ? null : FoodType.standard)),
                const SizedBox(width: 8),
                _Chip(label: 'Container', selected: _typeFilter == FoodType.container, color: color,
                    onTap: () => setState(() => _typeFilter =
                        _typeFilter == FoodType.container ? null : FoodType.container)),
                const SizedBox(width: 8),
                _Chip(label: 'Canister', selected: _typeFilter == FoodType.canister, color: color,
                    onTap: () => setState(() => _typeFilter =
                        _typeFilter == FoodType.canister ? null : FoodType.canister)),
                const SizedBox(width: 8),
                _Chip(label: 'Unit', selected: _typeFilter == FoodType.unit, color: color,
                    onTap: () => setState(() => _typeFilter =
                        _typeFilter == FoodType.unit ? null : FoodType.unit)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: foodsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
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
                filtered = List.of(filtered)
                  ..sort((a, b) {
                    final ca = usageCounts[a.id] ?? 0;
                    final cb = usageCounts[b.id] ?? 0;
                    if (cb != ca) return cb.compareTo(ca);
                    return a.name.compareTo(b.name);
                  });
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No foods found',
                          style: TextStyle(color: Colors.white38)));
                }
                final selectedId = widget.initial?.food?.id;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final food = filtered[i];
                    final isSelected = food.id == selectedId;
                    return _FoodRow(
                      food: food,
                      isSelected: isSelected,
                      onTap: () => _openMeasurementSheet(food,
                          initial: isSelected ? widget.initial : null),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Food row ──────────────────────────────────────────────────────────────────

class _FoodRow extends StatelessWidget {
  final Food food;
  final bool isSelected;
  final VoidCallback onTap;
  const _FoodRow(
      {required this.food, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          child: Row(
            children: [
              FoodPhoto(photoPath: food.photoPath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    MacroRow(
                      kcal: food.kcal,
                      protein: food.protein,
                      carbs: food.carbs,
                      fat: food.fat,
                      compact: true,
                    ),
                    if (food.isCountable && food.canSize != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${food.canSize!.toStringAsFixed(0)}g / ${food.effectiveUnitLabel}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Measurement sheet (shown after tapping a food) ────────────────────────────

class _MeasurementSheet extends StatefulWidget {
  final Food food;
  final RecipeIngredient? initial;
  const _MeasurementSheet({required this.food, this.initial});

  @override
  State<_MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends State<_MeasurementSheet> {
  final _weightCtrl = TextEditingController();
  double _unitCount = 1.0;
  bool _byWeight = false; // countable foods can switch to grams

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      if (widget.food.isCountable && widget.food.canSize != null) {
        // Detect if the original was stored by weight (not a clean multiple)
        final count = init.weightGrams / widget.food.canSize!;
        final isCleanCount = (count * 2).round() == (count * 2);
        if (isCleanCount) {
          _unitCount = count.clamp(0.5, 9999);
        } else {
          _byWeight = true;
          _weightCtrl.text = init.weightGrams.toStringAsFixed(0);
        }
      } else {
        _weightCtrl.text = init.weightGrams.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final double weightGrams;
    if (widget.food.isCountable && !_byWeight) {
      final canSize = widget.food.canSize;
      if (canSize == null || canSize <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No unit weight set for this food')));
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
          foodId: widget.food.id,
          food: widget.food,
          weightGrams: weightGrams,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FoodPhoto(
                  photoPath: widget.food.photoPath,
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.food.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (widget.food.isCountable) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _ModeChip(
                  label: 'By ${widget.food.effectiveUnitLabel}',
                  selected: !_byWeight,
                  color: color,
                  onTap: () => setState(() => _byWeight = false),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: 'By weight',
                  selected: _byWeight,
                  color: color,
                  onTap: () => setState(() => _byWeight = true),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (widget.food.isCountable && !_byWeight) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  color: color,
                  enabled: _unitCount > 0.5,
                  onTap: () => setState(() => _unitCount -= 0.5),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      _unitCount == _unitCount.truncateToDouble()
                          ? '${_unitCount.toInt()} ${widget.food.effectiveUnitLabel}'
                          : '${_unitCount.toStringAsFixed(1)} ${widget.food.effectiveUnitLabel}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                    if (widget.food.canSize != null)
                      Text(
                        '≈ ${(_unitCount * widget.food.canSize!).toStringAsFixed(0)}g',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white38),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                _StepBtn(
                  icon: Icons.add,
                  color: color,
                  enabled: true,
                  onTap: () => setState(() => _unitCount += 0.5),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _weightCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                  labelText: 'Weight', suffixText: 'g'),
              onSubmitted: (_) => _confirm(),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _confirm,
            child: Text(widget.initial == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ModeChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : Colors.white54,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn(
      {required this.icon,
      required this.color,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: enabled ? color : Colors.transparent, width: 1.5),
        ),
        child: Icon(icon,
            size: 20, color: enabled ? color : Colors.white24),
      ),
    );
  }
}

// ── Custom ingredient sheet ───────────────────────────────────────────────────

class _CustomIngredientSheet extends StatefulWidget {
  final RecipeIngredient? initial;
  const _CustomIngredientSheet({this.initial});

  @override
  State<_CustomIngredientSheet> createState() => _CustomIngredientSheetState();
}

class _CustomIngredientSheetState extends State<_CustomIngredientSheet> {
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _multiplierCtrl = TextEditingController(text: '1');

  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    for (final c in [_kcalCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl, _multiplierCtrl]) {
      c.addListener(_rebuild);
    }
    final init = widget.initial;
    if (init != null) {
      _nameCtrl.text = init.customName ?? '';
      _weightCtrl.text = init.weightGrams.toStringAsFixed(0);
      if (init.customKcal != null) _kcalCtrl.text = _fmt(init.customKcal!);
      if (init.customProtein != null) _proteinCtrl.text = _fmt(init.customProtein!);
      if (init.customCarbs != null) _carbsCtrl.text = _fmt(init.customCarbs!);
      if (init.customFat != null) _fatCtrl.text = _fmt(init.customFat!);
    }
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [_kcalCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl, _multiplierCtrl]) {
      c.removeListener(_rebuild);
    }
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _multiplierCtrl.dispose();
    super.dispose();
  }

  double? _scaled(String text, double mul) {
    final v = double.tryParse(text.trim());
    return v == null ? null : v * mul;
  }

  void _confirm() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name is required')));
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Custom ingredient',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Vanilla extract, baking powder'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                  labelText: 'Weight', suffixText: 'g'),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Multiplier',
                hintText: '1',
                helperText: 'Scale macros — e.g. 2 for double the amount',
              ),
            ),
            _LivePreviewRow(
              kcalText: _kcalCtrl.text,
              proteinText: _proteinCtrl.text,
              carbsText: _carbsCtrl.text,
              fatText: _fatCtrl.text,
              multiplierText: _multiplierCtrl.text,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _confirm,
              child: Text(widget.initial == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live macro preview ────────────────────────────────────────────────────────

class _LivePreviewRow extends StatelessWidget {
  final String kcalText;
  final String proteinText;
  final String carbsText;
  final String fatText;
  final String multiplierText;

  const _LivePreviewRow({
    required this.kcalText,
    required this.proteinText,
    required this.carbsText,
    required this.fatText,
    required this.multiplierText,
  });

  static String _fmtVal(double? v) {
    if (v == null) return '—';
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final mul = double.tryParse(multiplierText.trim()) ?? 1.0;
    final kcal = double.tryParse(kcalText.trim());
    final protein = double.tryParse(proteinText.trim());
    final carbs = double.tryParse(carbsText.trim());
    final fat = double.tryParse(fatText.trim());

    // Only show when multiplier isn't 1 or any macro field has a value
    final hasAny = kcal != null || protein != null || carbs != null || fat != null;
    if (!hasAny) return const SizedBox.shrink();

    final scaledKcal = kcal == null ? null : kcal * mul;
    final scaledProtein = protein == null ? null : protein * mul;
    final scaledCarbs = carbs == null ? null : carbs * mul;
    final scaledFat = fat == null ? null : fat * mul;

    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total (×${mul == mul.truncateToDouble() ? mul.toInt() : mul.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
            Row(
              children: [
                _MacroChip('${_fmtVal(scaledKcal)} kcal', color),
                const SizedBox(width: 8),
                _MacroChip('P ${_fmtVal(scaledProtein)}g', Colors.green),
                const SizedBox(width: 8),
                _MacroChip('C ${_fmtVal(scaledCarbs)}g', Colors.orange),
                const SizedBox(width: 8),
                _MacroChip('F ${_fmtVal(scaledFat)}g', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600));
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

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
