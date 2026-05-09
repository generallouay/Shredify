import 'package:flutter/material.dart';
import '../../../core/models/meal_food_item.dart';
import '../../shared/widgets/food_photo.dart';
import '../../shared/widgets/macro_row.dart';

class MealFoodItemCard extends StatelessWidget {
  final MealFoodItem item;
  final bool showMacros;
  final VoidCallback? onTap;
  final ValueChanged<double>? onWeightAfterChanged;
  final VoidCallback? onDelete;

  const MealFoodItemCard({
    super.key,
    required this.item,
    this.showMacros = false,
    this.onTap,
    this.onWeightAfterChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final macros = item.macros;
    final food = item.food;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FoodPhoto(photoPath: food?.photoPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food?.name ?? 'Unknown food',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _MeasurementInfo(item: item),
                  // Weight-after input for container mode
                  if (item.method == MeasurementMethod.container &&
                      item.weightAfter == null &&
                      onWeightAfterChanged != null) ...[
                    const SizedBox(height: 8),
                    _WeightAfterInput(onSubmit: onWeightAfterChanged!),
                  ],
                  // Macros
                  if (showMacros && macros != null) ...[
                    const SizedBox(height: 6),
                    _MacroLine(macros: macros),
                  ],
                  if (showMacros && macros == null && item.method == MeasurementMethod.container)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Enter weight after to calculate',
                          style: TextStyle(
                              fontSize: 11, color: Colors.orange)),
                    ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.white38),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

String _fmtCount(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class _MeasurementInfo extends StatelessWidget {
  final MealFoodItem item;
  const _MeasurementInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    final style =
        const TextStyle(fontSize: 12, color: Colors.white54);
    return switch (item.method) {
      MeasurementMethod.standard => Text(
          '${item.weightGrams?.toStringAsFixed(0) ?? '?'}g',
          style: style),
      MeasurementMethod.container => Text(
          'Before: ${item.weightBefore?.toStringAsFixed(0) ?? '?'}g'
          '${item.weightAfter != null ? '  •  After: ${item.weightAfter!.toStringAsFixed(0)}g  •  Consumed: ${item.consumedGrams?.toStringAsFixed(0) ?? '?'}g' : ''}',
          style: style),
      MeasurementMethod.canister => Text(
          '${item.canCount != null ? _fmtCount(item.canCount!) : '?'} can${(item.canCount ?? 0) != 1 ? 's' : ''}  •  ${item.consumedGrams?.toStringAsFixed(0) ?? '?'}g',
          style: style),
    };
  }
}

class _WeightAfterInput extends StatefulWidget {
  final ValueChanged<double> onSubmit;
  const _WeightAfterInput({required this.onSubmit});

  @override
  State<_WeightAfterInput> createState() => _WeightAfterInputState();
}

class _WeightAfterInputState extends State<_WeightAfterInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Weight after eating (g)',
              suffixText: 'g',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            final v = double.tryParse(_ctrl.text);
            if (v != null) widget.onSubmit(v);
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}

class _MacroLine extends StatelessWidget {
  final dynamic macros;
  const _MacroLine({required this.macros});

  @override
  Widget build(BuildContext context) {
    return MacroRow(
      kcal: macros.kcal,
      protein: macros.protein,
      carbs: macros.carbs,
      fat: macros.fat,
      compact: true,
    );
  }
}
