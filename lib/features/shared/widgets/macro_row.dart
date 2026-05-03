import 'package:flutter/material.dart';

class MacroRow extends StatelessWidget {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final bool compact;

  const MacroRow({
    super.key,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = compact
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.labelMedium;
    final valueStyle = style?.copyWith(
        color: Colors.white, fontWeight: FontWeight.w600);
    final labelStyle = style?.copyWith(color: Colors.white54);

    return Wrap(
      spacing: compact ? 10 : 16,
      children: [
        _Macro(value: kcal, unit: 'kcal', valueStyle: valueStyle, labelStyle: labelStyle),
        _Macro(value: protein, unit: 'P', valueStyle: valueStyle, labelStyle: labelStyle),
        _Macro(value: carbs, unit: 'C', valueStyle: valueStyle, labelStyle: labelStyle),
        _Macro(value: fat, unit: 'F', valueStyle: valueStyle, labelStyle: labelStyle),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  final double value;
  final String unit;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  const _Macro(
      {required this.value,
      required this.unit,
      this.valueStyle,
      this.labelStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value.toStringAsFixed(value >= 10 ? 0 : 1), style: valueStyle),
        const SizedBox(width: 2),
        Text(unit, style: labelStyle),
      ],
    );
  }
}
