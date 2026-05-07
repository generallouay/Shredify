import 'package:flutter/material.dart';
import '../../../core/models/meal_entry.dart';

class MealEntryCard extends StatelessWidget {
  final MealEntry entry;
  final VoidCallback? onDelete;

  const MealEntryCard({super.key, required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bolt_outlined, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description ?? 'Entry',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _macroLabel(),
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500),
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
    );
  }

  String _macroLabel() {
    final parts = ['${entry.kcal.toStringAsFixed(0)} kcal'];
    if (entry.protein != null)
      parts.add('P ${entry.protein!.toStringAsFixed(1)}g');
    if (entry.carbs != null)
      parts.add('C ${entry.carbs!.toStringAsFixed(1)}g');
    if (entry.fat != null) parts.add('F ${entry.fat!.toStringAsFixed(1)}g');
    return parts.join('  ·  ');
  }
}
