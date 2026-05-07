import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/quick_entry.dart';

class QuickEntryDialog extends StatefulWidget {
  const QuickEntryDialog({super.key});

  @override
  State<QuickEntryDialog> createState() => _QuickEntryDialogState();
}

class _QuickEntryDialogState extends State<QuickEntryDialog> {
  final _descCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _multiplierCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _descCtrl.dispose();
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

  void _submit() {
    final kcalRaw = double.tryParse(_kcalCtrl.text.trim());
    if (kcalRaw == null || kcalRaw <= 0) return;
    final mul = double.tryParse(_multiplierCtrl.text.trim()) ?? 1.0;

    final desc = _descCtrl.text.trim();
    Navigator.of(context).pop(QuickEntry(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      kcal: kcalRaw * mul,
      protein: _scaled(_proteinCtrl.text, mul),
      carbs: _scaled(_carbsCtrl.text, mul),
      fat: _scaled(_fatCtrl.text, mul),
      description: desc.isEmpty ? null : desc,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Afternoon snack',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kcalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Calories *',
                suffixText: 'kcal',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proteinCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Protein',
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carbsCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Carbs',
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Fat',
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _multiplierCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Multiplier',
                hintText: '1',
                helperText: 'e.g. 2.5 for 250g of a 100g entry',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
