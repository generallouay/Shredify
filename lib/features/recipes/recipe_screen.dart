import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/macro_totals.dart';
import '../../core/services/image_pick_service.dart';
import '../../core/models/meal.dart';
import '../../core/models/meal_entry.dart';
import '../../core/models/meal_food_item.dart';
import '../../core/models/recipe.dart';
import '../../core/providers/meals_provider.dart';
import '../../core/providers/recipes_provider.dart';
import '../../core/repositories/recipe_repository.dart';
import '../shared/widgets/food_photo.dart';
import 'recipe_ingredient_picker_page.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  final String? recipeId;
  const RecipeScreen({super.key, this.recipeId});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  final _nameCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController(text: '1');
  RecipeType _type = RecipeType.highProtein;
  String? _photoPath;
  final List<RecipeIngredient> _ingredients = [];
  final List<String> _steps = [];
  bool _loading = true;
  Recipe? _original;
  DateTime _createdAt = DateTime.now();

  bool get _isNew => widget.recipeId == null;

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await ref.read(recipeRepositoryProvider).getById(widget.recipeId!);
    if (r != null && mounted) {
      setState(() {
        _original = r;
        _nameCtrl.text = r.name;
        _servingsCtrl.text = r.servings.toString();
        _type = r.type;
        _photoPath = r.photoPath;
        _ingredients
          ..clear()
          ..addAll(r.ingredients);
        _steps
          ..clear()
          ..addAll(r.steps);
        _createdAt = r.createdAt;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await pickAndCropSquare(source);
    if (path == null || !mounted) return;
    setState(() => _photoPath = path);
  }

  void _showPhotoSheet() {
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
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addIngredient() async {
    final result = await Navigator.push<RecipeIngredient>(
      context,
      MaterialPageRoute(
          builder: (_) => const RecipeIngredientPickerPage()),
    );
    if (result == null || !mounted) return;
    setState(() => _ingredients.add(result));
  }

  Future<void> _editIngredient(int index) async {
    final result = await Navigator.push<RecipeIngredient>(
      context,
      MaterialPageRoute(
          builder: (_) => RecipeIngredientPickerPage(
              initial: _ingredients[index])),
    );
    if (result == null || !mounted) return;
    setState(() => _ingredients[index] = result);
  }

  void _removeIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
  }

  Future<void> _addStep() async {
    final text = await _editStepDialog(null);
    if (text == null || text.isEmpty || !mounted) return;
    setState(() => _steps.add(text));
  }

  Future<void> _editStep(int index) async {
    final text = await _editStepDialog(_steps[index]);
    if (text == null || !mounted) return;
    setState(() {
      if (text.isEmpty) {
        _steps.removeAt(index);
      } else {
        _steps[index] = text;
      }
    });
  }

  Future<String?> _editStepDialog(String? initial) async {
    final ctrl = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initial == null ? 'Add step' : 'Edit step'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
              hintText: 'e.g. Whisk eggs and cottage cheese'),
        ),
        actions: [
          if (initial != null)
            TextButton(
                onPressed: () => Navigator.pop(ctx, ''),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent))),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }

  MacroTotals get _totalMacros => _ingredients.fold<MacroTotals>(
      MacroTotals.zero, (acc, i) => acc + i.macros);

  MacroTotals get _perServingMacros {
    final s = int.tryParse(_servingsCtrl.text) ?? 1;
    if (s <= 0) return _totalMacros;
    final t = _totalMacros;
    return MacroTotals(
      kcal: t.kcal / s,
      protein: t.protein / s,
      fat: t.fat / s,
      carbs: t.carbs / s,
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe name is required')));
      return;
    }
    final servings = int.tryParse(_servingsCtrl.text) ?? 1;
    final recipe = Recipe(
      id: _original?.id ?? const Uuid().v4(),
      name: name,
      type: _type,
      servings: servings < 1 ? 1 : servings,
      photoPath: _photoPath,
      ingredients: _ingredients,
      steps: _steps,
      createdAt: _createdAt,
    );
    try {
      if (_isNew) {
        await ref.read(recipesProvider.notifier).add(recipe);
      } else {
        await ref.read(recipesProvider.notifier).save(recipe);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _delete() async {
    if (_original == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(recipesProvider.notifier).delete(_original!.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _logAsMeal() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add ingredients first')));
      return;
    }
    final servings = int.tryParse(_servingsCtrl.text) ?? 1;
    final consumed = await showDialog<double>(
      context: context,
      builder: (_) => _ServingsDialog(totalServings: servings),
    );
    if (consumed == null || consumed <= 0 || !mounted) return;

    final factor = servings <= 0 ? 1.0 : consumed / servings;
    final mealId = const Uuid().v4();
    final items = <MealFoodItem>[];
    final entries = <MealEntry>[];
    for (final ing in _ingredients) {
      if (ing.food != null) {
        items.add(MealFoodItem(
          id: const Uuid().v4(),
          mealId: mealId,
          foodId: ing.foodId ?? ing.food!.id,
          method: MeasurementMethod.standard,
          weightGrams: ing.weightGrams * factor,
          food: ing.food,
        ));
      } else if (ing.hasCustomMacros) {
        final m = ing.macros;
        entries.add(MealEntry(
          id: const Uuid().v4(),
          mealId: mealId,
          kcal: m.kcal * factor,
          protein: m.protein * factor,
          carbs: m.carbs * factor,
          fat: m.fat * factor,
          description: ing.displayName,
        ));
      }
    }
    if (items.isEmpty && entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No ingredients with macros to log')));
      return;
    }
    final meal = Meal(
        id: mealId, createdAt: DateTime.now(), items: items, entries: entries);
    try {
      await ref.read(mealsProvider.notifier).add(meal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged as a new meal')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to log: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Recipe' : 'Edit Recipe'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _save,
            child: Text(_isNew ? 'Save' : 'Update'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Photo + name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showPhotoSheet,
                child: FoodPhoto(
                  photoPath: _photoPath,
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(12),
                  placeholder: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_camera_outlined,
                        color: Colors.white38, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Recipe name',
                          hintText: 'e.g. High protein pancakes'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _servingsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Servings', isDense: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type toggle
          SegmentedButton<RecipeType>(
            segments: const [
              ButtonSegment(
                value: RecipeType.highProtein,
                label: Text('High Protein'),
                icon: Icon(Icons.bolt_outlined, size: 16),
              ),
              ButtonSegment(
                value: RecipeType.standard,
                label: Text('Standard'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),

          // Macros summary
          _MacrosCard(
            total: _totalMacros,
            perServing: _perServingMacros,
            servings: int.tryParse(_servingsCtrl.text) ?? 1,
          ),
          const SizedBox(height: 20),

          // Ingredients
          _SectionHeader(
            title: 'Ingredients',
            action: TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
          if (_ingredients.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No ingredients yet',
                  style: TextStyle(color: Colors.white38)),
            )
          else
            ..._ingredients.asMap().entries.map((e) => _IngredientTile(
                  ingredient: e.value,
                  onTap: () => _editIngredient(e.key),
                  onDelete: () => _removeIngredient(e.key),
                )),
          const SizedBox(height: 20),

          // Steps
          _SectionHeader(
            title: 'Method',
            action: TextButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
          if (_steps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No steps yet',
                  style: TextStyle(color: Colors.white38)),
            )
          else
            ..._steps.asMap().entries.map((e) => _StepTile(
                  index: e.key + 1,
                  text: e.value,
                  onTap: () => _editStep(e.key),
                )),
          const SizedBox(height: 24),

          // Log as meal
          if (!_isNew)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logAsMeal,
                icon: const Icon(Icons.restaurant_outlined, size: 18),
                label: const Text('Log as a meal'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

String _ingredientSubtitle(RecipeIngredient ing, MacroTotals m) {
  final food = ing.food;
  if (food != null && food.isCountable && food.canSize != null) {
    final count = ing.weightGrams / food.canSize!;
    final countStr = count == count.truncateToDouble()
        ? count.toInt().toString()
        : count.toStringAsFixed(1);
    final macros =
        '${m.kcal.toStringAsFixed(0)} kcal  ·  P${m.protein.toStringAsFixed(0)} C${m.carbs.toStringAsFixed(0)} F${m.fat.toStringAsFixed(0)}';
    return '$countStr ${food.effectiveUnitLabel}  ·  ${ing.weightGrams.toStringAsFixed(0)}g  ·  $macros';
  }
  if (food == null && !ing.hasCustomMacros) {
    return '${ing.weightGrams.toStringAsFixed(0)}g  ·  custom (no macros)';
  }
  return '${ing.weightGrams.toStringAsFixed(0)}g  ·  ${m.kcal.toStringAsFixed(0)} kcal  ·  P${m.protein.toStringAsFixed(0)} C${m.carbs.toStringAsFixed(0)} F${m.fat.toStringAsFixed(0)}';
}

class _IngredientTile extends StatelessWidget {
  final RecipeIngredient ingredient;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _IngredientTile({
    required this.ingredient,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final m = ingredient.macros;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              FoodPhoto(
                  photoPath: ingredient.food?.photoPath,
                  width: 40,
                  height: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _ingredientSubtitle(ingredient, m),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
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

class _StepTile extends StatelessWidget {
  final int index;
  final String text;
  final VoidCallback onTap;

  const _StepTile(
      {required this.index, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text('$index',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacrosCard extends StatelessWidget {
  final MacroTotals total;
  final MacroTotals perServing;
  final int servings;
  const _MacrosCard(
      {required this.total,
      required this.perServing,
      required this.servings});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _MacroRow(label: 'Per serving', macros: perServing),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _MacroRow(label: 'Total ($servings)', macros: total),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final MacroTotals macros;
  const _MacroRow({required this.label, required this.macros});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white60))),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroVal(label: 'kcal', value: macros.kcal, decimals: 0),
              _MacroVal(label: 'P', value: macros.protein),
              _MacroVal(label: 'C', value: macros.carbs),
              _MacroVal(label: 'F', value: macros.fat),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroVal extends StatelessWidget {
  final String label;
  final double value;
  final int decimals;
  const _MacroVal(
      {required this.label, required this.value, this.decimals = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toStringAsFixed(decimals),
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}

class _ServingsDialog extends StatefulWidget {
  final int totalServings;
  const _ServingsDialog({required this.totalServings});

  @override
  State<_ServingsDialog> createState() => _ServingsDialogState();
}

class _ServingsDialogState extends State<_ServingsDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How many servings did you eat?'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
            labelText: 'Servings',
            helperText: 'Recipe makes ${widget.totalServings}'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(_ctrl.text);
            Navigator.pop(context, v);
          },
          child: const Text('Log'),
        ),
      ],
    );
  }
}
