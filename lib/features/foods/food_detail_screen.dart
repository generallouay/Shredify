import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/food.dart';
import '../../core/providers/foods_provider.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final String? foodId;
  const FoodDetailScreen({super.key, this.foodId});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _canSizeCtrl = TextEditingController();

  FoodType _type = FoodType.standard;
  String? _photoPath;
  bool _isEditing = false;
  bool _loading = false;
  Food? _original;

  bool get _isNew => widget.foodId == null;

  @override
  void initState() {
    super.initState();
    _isEditing = _isNew;
    if (!_isNew) _loadFood();
  }

  Future<void> _loadFood() async {
    final foods = await ref.read(foodsProvider.future);
    final food = foods.where((f) => f.id == widget.foodId).firstOrNull;
    if (food != null && mounted) {
      setState(() {
        _original = food;
        _nameCtrl.text = food.name;
        _kcalCtrl.text = food.kcal.toStringAsFixed(1);
        _proteinCtrl.text = food.protein.toStringAsFixed(1);
        _fatCtrl.text = food.fat.toStringAsFixed(1);
        _carbsCtrl.text = food.carbs.toStringAsFixed(1);
        _type = food.type;
        _photoPath = food.photoPath;
        if (food.canSize != null) {
          _canSizeCtrl.text = food.canSize!.toStringAsFixed(1);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbsCtrl.dispose();
    _canSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final docs = await getApplicationDocumentsDirectory();
    final imgDir = Directory(p.join(docs.path, 'shredify', 'images'));
    imgDir.createSync(recursive: true);
    final ext = p.extension(picked.path);
    final dest = p.join(imgDir.path, '${const Uuid().v4()}$ext');
    await File(picked.path).copy(dest);
    setState(() => _photoPath = dest);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                context.pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                context.pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  context.pop();
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final food = Food(
      id: _original?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      kcal: double.parse(_kcalCtrl.text),
      protein: double.parse(_proteinCtrl.text),
      fat: double.parse(_fatCtrl.text),
      carbs: double.parse(_carbsCtrl.text),
      type: _type,
      canSize: _type == FoodType.canister && _canSizeCtrl.text.isNotEmpty
          ? double.parse(_canSizeCtrl.text)
          : null,
      photoPath: _photoPath,
    );

    if (_isNew) {
      await ref.read(foodsProvider.notifier).add(food);
    } else {
      await ref.read(foodsProvider.notifier).save(food);
    }

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete food?'),
        content: Text('Remove "${_original?.name}" from your database?'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(foodsProvider.notifier).delete(_original!.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew
            ? 'New Food'
            : _isEditing
                ? 'Edit Food'
                : _original?.name ?? ''),
        actions: [
          if (!_isNew && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isNew && _isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo
            Center(
              child: GestureDetector(
                onTap: _isEditing ? _showImagePicker : null,
                child: _PhotoWidget(photoPath: _photoPath, editable: _isEditing),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            _Field(
              controller: _nameCtrl,
              label: 'Name',
              enabled: _isEditing,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Macros per 100g
            Text('Macros per 100g',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white54)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _Field(
                        controller: _kcalCtrl,
                        label: 'Kcal',
                        enabled: _isEditing,
                        numeric: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _Field(
                        controller: _proteinCtrl,
                        label: 'Protein (g)',
                        enabled: _isEditing,
                        numeric: true)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _Field(
                        controller: _carbsCtrl,
                        label: 'Carbs (g)',
                        enabled: _isEditing,
                        numeric: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _Field(
                        controller: _fatCtrl,
                        label: 'Fat (g)',
                        enabled: _isEditing,
                        numeric: true)),
              ],
            ),
            const SizedBox(height: 20),

            // Type selector
            Text('Food Type',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white54)),
            const SizedBox(height: 8),
            _TypeSelector(
              value: _type,
              enabled: _isEditing,
              onChanged: (t) => setState(() => _type = t),
            ),

            // Canister size
            if (_type == FoodType.canister) ...[
              const SizedBox(height: 12),
              _Field(
                controller: _canSizeCtrl,
                label: 'Canister size (g)',
                enabled: _isEditing,
                numeric: true,
                validator: (v) => v == null || v.isEmpty ? 'Required for canister' : null,
              ),
            ],

            const SizedBox(height: 32),
            if (_isEditing)
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isNew ? 'Save Food' : 'Save Changes'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool numeric;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.enabled,
    this.numeric = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: validator ??
          (numeric
              ? (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                }
              : null),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final FoodType value;
  final bool enabled;
  final ValueChanged<FoodType> onChanged;

  const _TypeSelector(
      {required this.value, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: FoodType.values.map((t) {
        final label = t.name[0].toUpperCase() + t.name.substring(1);
        final selected = value == t;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: enabled ? () => onChanged(t) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(label,
                      style: TextStyle(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white54,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhotoWidget extends StatelessWidget {
  final String? photoPath;
  final bool editable;
  const _PhotoWidget({this.photoPath, required this.editable});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: hasPhoto
              ? Image.file(File(photoPath!),
                  width: 120, height: 120, fit: BoxFit.cover)
              : Container(
                  width: 120,
                  height: 120,
                  color: const Color(0xFF2C2C2E),
                  child: const Icon(Icons.fastfood_outlined,
                      size: 48, color: Colors.white24),
                ),
        ),
        if (editable)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
            ),
          ),
      ],
    );
  }
}
