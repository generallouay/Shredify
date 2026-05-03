import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/daily_goals.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/foods_provider.dart';
import '../../core/providers/meals_provider.dart';
import '../../core/services/backup_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily goals
          _SectionHeader('Daily Goals'),
          goalsAsync.when(
            data: (goals) => _GoalsCard(goals: goals),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 24),

          // Backup & restore
          _SectionHeader('Backup & Restore'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Create Backup'),
                  subtitle: const Text('Save all data as a ZIP file',
                      style: TextStyle(fontSize: 12)),
                  trailing:
                      const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _createBackup(context, ref),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Restore Backup'),
                  subtitle: const Text(
                      'Import from ZIP (replaces all data)',
                      style: TextStyle(fontSize: 12)),
                  trailing:
                      const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _restoreBackup(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    try {
      final service = BackupService(
        ref.read(appDatabaseProvider),
        ref.read(foodDaoProvider),
        ref.read(mealDaoProvider),
      );
      final path = await service.createBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup saved to:\n$path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
            'This will replace ALL current data with the backup. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      final service = BackupService(
        ref.read(appDatabaseProvider),
        ref.read(foodDaoProvider),
        ref.read(mealDaoProvider),
      );
      await service.restoreBackup(result.files.single.path!);
      ref.invalidate(foodsProvider);
      ref.invalidate(mealsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restore complete!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600)),
      );
}

class _GoalsCard extends ConsumerStatefulWidget {
  final DailyGoals goals;
  const _GoalsCard({required this.goals});

  @override
  ConsumerState<_GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends ConsumerState<_GoalsCard> {
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  late final TextEditingController _carbs;

  @override
  void initState() {
    super.initState();
    _kcal = TextEditingController(
        text: widget.goals.kcal.toStringAsFixed(0));
    _protein = TextEditingController(
        text: widget.goals.protein.toStringAsFixed(0));
    _fat = TextEditingController(
        text: widget.goals.fat.toStringAsFixed(0));
    _carbs = TextEditingController(
        text: widget.goals.carbs.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _kcal.dispose();
    _protein.dispose();
    _fat.dispose();
    _carbs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final goals = DailyGoals(
      kcal: double.tryParse(_kcal.text) ?? widget.goals.kcal,
      protein: double.tryParse(_protein.text) ?? widget.goals.protein,
      fat: double.tryParse(_fat.text) ?? widget.goals.fat,
      carbs: double.tryParse(_carbs.text) ?? widget.goals.carbs,
    );
    await ref.read(dailyGoalsProvider.notifier).save(goals);
    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Goals saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _GoalField(ctrl: _kcal, label: 'Calories (kcal)')),
                const SizedBox(width: 10),
                Expanded(
                    child: _GoalField(ctrl: _protein, label: 'Protein (g)')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _GoalField(ctrl: _carbs, label: 'Carbs (g)')),
                const SizedBox(width: 10),
                Expanded(
                    child: _GoalField(ctrl: _fat, label: 'Fat (g)')),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _save, child: const Text('Save Goals')),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _GoalField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      );
}
