import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/quick_entry.dart';

class QuickEntryDialog extends StatefulWidget {
  final QuickEntry? initialEntry;
  const QuickEntryDialog({super.key, this.initialEntry});

  @override
  State<QuickEntryDialog> createState() => _QuickEntryDialogState();
}

class _QuickEntryDialogState extends State<QuickEntryDialog> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _multiplierCtrl;

  bool get _isEditing => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;
    final kcalSeed = e?.rawKcal ?? e?.kcal;
    final proteinSeed = e?.rawProtein ?? e?.protein;
    final carbsSeed = e?.rawCarbs ?? e?.carbs;
    final fatSeed = e?.rawFat ?? e?.fat;
    final mulSeed = e?.multiplier ?? 1.0;

    _descCtrl = TextEditingController(text: e?.description ?? '');
    _kcalCtrl = TextEditingController(
        text: kcalSeed != null ? _fmt(kcalSeed) : '');
    _proteinCtrl = TextEditingController(
        text: proteinSeed != null ? _fmt(proteinSeed) : '');
    _carbsCtrl = TextEditingController(
        text: carbsSeed != null ? _fmt(carbsSeed) : '');
    _fatCtrl = TextEditingController(
        text: fatSeed != null ? _fmt(fatSeed) : '');
    _multiplierCtrl = TextEditingController(text: _fmt(mulSeed));
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

  double? _parse(String text) => double.tryParse(text.trim());

  void _submit() {
    final kcalRaw = _parse(_kcalCtrl.text);
    if (kcalRaw == null || kcalRaw <= 0) return;
    final mul = _parse(_multiplierCtrl.text) ?? 1.0;
    final proteinRaw = _parse(_proteinCtrl.text);
    final carbsRaw = _parse(_carbsCtrl.text);
    final fatRaw = _parse(_fatCtrl.text);
    final desc = _descCtrl.text.trim();

    Navigator.of(context).pop(QuickEntry(
      id: widget.initialEntry?.id ?? const Uuid().v4(),
      createdAt: widget.initialEntry?.createdAt ?? DateTime.now(),
      kcal: kcalRaw * mul,
      protein: proteinRaw == null ? null : proteinRaw * mul,
      carbs: carbsRaw == null ? null : carbsRaw * mul,
      fat: fatRaw == null ? null : fatRaw * mul,
      description: desc.isEmpty ? null : desc,
      rawKcal: kcalRaw,
      rawProtein: proteinRaw,
      rawCarbs: carbsRaw,
      rawFat: fatRaw,
      multiplier: mul,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Entry' : 'Quick Entry'),
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
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
