import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/meal_entry.dart';

class MealEntryDialog extends StatefulWidget {
  final MealEntry? initialEntry;
  const MealEntryDialog({super.key, this.initialEntry});

  @override
  State<MealEntryDialog> createState() => _MealEntryDialogState();
}

class _MealEntryDialogState extends State<MealEntryDialog> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  final _multiplierCtrl = TextEditingController(text: '1');

  bool get _isEditing => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _kcalCtrl = TextEditingController(
        text: e != null ? _fmt(e.kcal) : '');
    _proteinCtrl = TextEditingController(
        text: e?.protein != null ? _fmt(e!.protein!) : '');
    _carbsCtrl = TextEditingController(
        text: e?.carbs != null ? _fmt(e!.carbs!) : '');
    _fatCtrl = TextEditingController(
        text: e?.fat != null ? _fmt(e!.fat!) : '');
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

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
    final mul = _isEditing
        ? 1.0
        : (double.tryParse(_multiplierCtrl.text.trim()) ?? 1.0);
    final desc = _descCtrl.text.trim();

    Navigator.of(context).pop(MealEntry(
      id: widget.initialEntry?.id ?? const Uuid().v4(),
      mealId: widget.initialEntry?.mealId ?? '',
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
      title: Text(_isEditing ? 'Edit Entry' : 'Add Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Protein shake',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kcalCtrl,
              autofocus: !_isEditing,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Calories *', suffixText: 'kcal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proteinCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Protein', suffixText: 'g'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carbsCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Carbs', suffixText: 'g'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Fat', suffixText: 'g'),
            ),
            if (!_isEditing) ...[
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
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
