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
    final labelStyle = TextStyle(
      fontSize: compact ? 12 : 13,
      color: Colors.white54,
    );
    final valueStyle = TextStyle(
      fontSize: compact ? 12 : 13,
      color: Colors.white70,
      fontWeight: FontWeight.w500,
    );
    final kcalStyle = TextStyle(
      fontSize: compact ? 12 : 13,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${kcal.toStringAsFixed(0)} kcal', style: kcalStyle),
        const SizedBox(height: 2),
        _MacroLine(label: 'Protein', value: protein, labelStyle: labelStyle, valueStyle: valueStyle),
        _MacroLine(label: 'Carbs',   value: carbs,   labelStyle: labelStyle, valueStyle: valueStyle),
        _MacroLine(label: 'Fat',     value: fat,     labelStyle: labelStyle, valueStyle: valueStyle),
      ],
    );
  }
}

class _MacroLine extends StatelessWidget {
  final String label;
  final double value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _MacroLine({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: labelStyle),
        ),
        Text('${value.toStringAsFixed(1)}g', style: valueStyle),
      ],
    );
  }
}
