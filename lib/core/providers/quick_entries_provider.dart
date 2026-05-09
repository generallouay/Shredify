import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_entry.dart';
import '../models/macro_totals.dart';
import '../repositories/quick_entry_repository.dart';
import 'auth_provider.dart';

class QuickEntriesNotifier extends StreamNotifier<List<QuickEntry>> {
  @override
  Stream<List<QuickEntry>> build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return Stream.value(const <QuickEntry>[]);
    return ref.watch(quickEntryRepositoryProvider).watchAll();
  }

  Future<void> add(QuickEntry entry) =>
      ref.read(quickEntryRepositoryProvider).insert(entry);

  Future<void> updateEntry(QuickEntry entry) =>
      ref.read(quickEntryRepositoryProvider).insert(entry);

  Future<void> delete(String id) =>
      ref.read(quickEntryRepositoryProvider).delete(id);
}

final quickEntriesProvider =
    StreamNotifierProvider<QuickEntriesNotifier, List<QuickEntry>>(
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
