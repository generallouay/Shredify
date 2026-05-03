import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_entry.dart';
import '../models/macro_totals.dart';
import 'database_provider.dart';

class QuickEntriesNotifier
    extends AsyncNotifier<List<QuickEntry>> {
  @override
  Future<List<QuickEntry>> build() async {
    return ref.read(quickEntryDaoProvider).getAll();
  }

  Future<void> add(QuickEntry entry) async {
    await ref.read(quickEntryDaoProvider).insert(entry);
    state = AsyncData([entry, ...?state.valueOrNull]);
  }

  Future<void> delete(String id) async {
    await ref.read(quickEntryDaoProvider).delete(id);
    state = AsyncData(
        state.valueOrNull?.where((e) => e.id != id).toList() ?? []);
  }
}

final quickEntriesProvider =
    AsyncNotifierProvider<QuickEntriesNotifier, List<QuickEntry>>(
        QuickEntriesNotifier.new);

final dailyQuickEntriesProvider =
    Provider.family<List<QuickEntry>, DateTime>((ref, day) {
  final entries = ref.watch(quickEntriesProvider);
  return entries.whenOrNull(data: (list) {
        final start = DateTime(day.year, day.month, day.day);
        final end =
            DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
        return list
            .where((e) =>
                !e.createdAt.isBefore(start) &&
                !e.createdAt.isAfter(end))
            .toList();
      }) ??
      [];
});

MacroTotals quickEntryToMacros(QuickEntry e) => MacroTotals(
      kcal: e.kcal,
      protein: e.protein ?? 0,
      carbs: e.carbs ?? 0,
      fat: e.fat ?? 0,
    );
