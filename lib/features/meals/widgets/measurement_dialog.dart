import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/food.dart';
import '../../../core/models/meal_food_item.dart';

class MeasurementDialog extends StatefulWidget {
  final Food food;
  const MeasurementDialog({super.key, required this.food});

  @override
  State<MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<MeasurementDialog> {
  late MeasurementMethod _method;
  final _ctrl1 = TextEditingController();
  final _ctrl2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _method = widget.food.type == FoodType.canister
        ? MeasurementMethod.canister
        : widget.food.type == FoodType.container
            ? MeasurementMethod.container
            : MeasurementMethod.standard;
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  void _confirm() {
    final v1 = double.tryParse(_ctrl1.text);
    final v2 = double.tryParse(_ctrl2.text);

    MealFoodItem? item;
    switch (_method) {
      case MeasurementMethod.standard:
        if (v1 == null) {
          _showError('Enter a weight in grams');
          return;
        }
        item = _build(weightGrams: v1);
        break;
      case MeasurementMethod.container:
        if (v1 == null) {
          _showError('Enter the weight before eating');
          return;
        }
        item = _build(weightBefore: v1, weightAfter: v2);
        break;
      case MeasurementMethod.canister:
        if (v1 == null || v1 <= 0) {
          _showError('Enter number of cans');
          return;
        }
        item = _build(canCount: v1);
        break;
    }
    context.pop(item);
  }

  MealFoodItem _build({
    double? weightGrams,
    double? weightBefore,
    double? weightAfter,
    double? canCount,
  }) =>
      MealFoodItem(
        id: '',
        mealId: '',
        foodId: widget.food.id,
        method: _method,
        weightGrams: weightGrams,
        weightBefore: weightBefore,
        weightAfter: weightAfter,
        canCount: canCount,
        food: widget.food,
      );

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.food.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Method selector
            Text('Measurement',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white54)),
            const SizedBox(height: 8),
            Row(
              children: [
                _MethodChip(
                  label: 'Standard',
                  selected: _method == MeasurementMethod.standard,
                  onTap: () =>
                      setState(() => _method = MeasurementMethod.standard),
                ),
                const SizedBox(width: 8),
                _MethodChip(
                  label: 'Container',
                  selected: _method == MeasurementMethod.container,
                  onTap: () =>
                      setState(() => _method = MeasurementMethod.container),
                ),
                if (widget.food.type == FoodType.canister) ...[
                  const SizedBox(width: 8),
                  _MethodChip(
                    label: 'Canister',
                    selected: _method == MeasurementMethod.canister,
                    onTap: () =>
                        setState(() => _method = MeasurementMethod.canister),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Inputs
            if (_method == MeasurementMethod.standard)
              TextField(
                controller: _ctrl1,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Weight (g)', suffixText: 'g'),
              ),
            if (_method == MeasurementMethod.container) ...[
              TextField(
                controller: _ctrl1,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Weight before (g)', suffixText: 'g'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ctrl2,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight after (g) — optional',
                  suffixText: 'g',
                  helperText: 'You can fill this in after eating',
                ),
              ),
            ],
            if (_method == MeasurementMethod.canister)
              TextField(
                controller: _ctrl1,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of cans',
                  helperText:
                      '${widget.food.canSize?.toStringAsFixed(0) ?? '?'}g per can',
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _confirm,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : Colors.white54,
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
