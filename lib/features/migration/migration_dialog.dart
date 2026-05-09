import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/migration_service.dart';

/// Shows the import-existing-data prompt and runs the migration. Returns
/// `true` if the migration completed, `false` if the user skipped, `null` if
/// the dialog was dismissed without a choice.
Future<bool?> showMigrationDialog(
    BuildContext context, WidgetRef ref) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ChoiceDialog(ref: ref),
  );
}

class _ChoiceDialog extends StatelessWidget {
  final WidgetRef ref;
  const _ChoiceDialog({required this.ref});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import existing data?'),
      content: const Text(
          'Found foods, meals, or entries on this device from before sign-in. '
          'Import them into your account so they sync across devices?'),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(migrationServiceProvider).markSkipped();
            if (context.mounted) Navigator.pop(context, false);
          },
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context, null); // close choice
            final result = await _runMigrationWithProgress(
                context.findRootAncestorStateOfType<NavigatorState>()!.context,
                ref);
            if (result == null) return;
            final scaffold = ScaffoldMessenger.maybeOf(
                context.findRootAncestorStateOfType<NavigatorState>()!.context);
            scaffold?.showSnackBar(SnackBar(
                content: Text(
                    'Imported ${result.foodCount} foods, ${result.mealCount} meals, '
                    '${result.quickEntryCount} entries')));
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}

Future<MigrationResult?> _runMigrationWithProgress(
    BuildContext context, WidgetRef ref) async {
  final progress = ValueNotifier<MigrationProgress?>(null);
  MigrationResult? result;
  Object? error;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProgressDialog(progress: progress),
  );

  try {
    result = await ref.read(migrationServiceProvider).migrate(
          onProgress: (p) => progress.value = p,
        );
  } catch (e) {
    error = e;
  }

  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  progress.dispose();

  if (error != null && context.mounted) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import failed'),
        content: Text('$error'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }
  return result;
}

class _ProgressDialog extends StatelessWidget {
  final ValueNotifier<MigrationProgress?> progress;
  const _ProgressDialog({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importing your data'),
      content: ValueListenableBuilder<MigrationProgress?>(
        valueListenable: progress,
        builder: (_, p, __) {
          final ratio = (p == null || p.total == 0) ? null : p.done / p.total;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: ratio),
              const SizedBox(height: 12),
              Text(
                p == null
                    ? 'Preparing...'
                    : '${p.done} of ${p.total}  ·  ${p.label}',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}
