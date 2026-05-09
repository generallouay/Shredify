import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/food_dao.dart';
import '../database/meal_dao.dart';
import '../database/quick_entry_dao.dart';
import '../models/daily_goals.dart';
import '../providers/database_provider.dart';
import '../repositories/daily_goals_repository.dart';
import '../repositories/food_repository.dart';
import '../repositories/meal_repository.dart';
import '../repositories/quick_entry_repository.dart';
import 'firestore_service.dart';

/// Migrates pre-cloud local data (sqflite + shared_preferences) into the
/// signed-in user's Firestore tree. Idempotent: runs at most once per user
/// (tracked via the migration meta doc).
class MigrationService {
  final FoodDao _foodDao;
  final MealDao _mealDao;
  final QuickEntryDao _quickEntryDao;
  final FoodRepository _foodRepo;
  final MealRepository _mealRepo;
  final QuickEntryRepository _quickEntryRepo;
  final DailyGoalsRepository _goalsRepo;
  final FirestoreService _fs;

  MigrationService({
    required FoodDao foodDao,
    required MealDao mealDao,
    required QuickEntryDao quickEntryDao,
    required FoodRepository foodRepo,
    required MealRepository mealRepo,
    required QuickEntryRepository quickEntryRepo,
    required DailyGoalsRepository goalsRepo,
    required FirestoreService firestoreService,
  })  : _foodDao = foodDao,
        _mealDao = mealDao,
        _quickEntryDao = quickEntryDao,
        _foodRepo = foodRepo,
        _mealRepo = mealRepo,
        _quickEntryRepo = quickEntryRepo,
        _goalsRepo = goalsRepo,
        _fs = firestoreService;

  /// Returns true when the current user has not yet migrated AND the device
  /// has local data worth importing.
  Future<bool> needsMigration() async {
    if (_fs.uid == null) return false;
    final meta = await _fs.migrationDoc.get();
    if (meta.exists) return false;
    final foods = await _foodDao.getAll();
    if (foods.isNotEmpty) return true;
    final meals = await _mealDao.getAll();
    if (meals.isNotEmpty) return true;
    final entries = await _quickEntryDao.getAll();
    if (entries.isNotEmpty) return true;
    return false;
  }

  /// Marks migration done so we don't prompt again on this account, even if
  /// the user chose to skip.
  Future<void> markSkipped() async {
    await _fs.migrationDoc.set({
      'migratedAt': FieldValue.serverTimestamp(),
      'source': 'sqflite',
      'skipped': true,
    });
  }

  /// Reads all local data, uploads photos to Storage, writes everything to
  /// Firestore, and records completion. Reports progress via [onProgress].
  Future<MigrationResult> migrate({
    void Function(MigrationProgress p)? onProgress,
  }) async {
    if (_fs.uid == null) throw StateError('No signed-in user');

    final foods = await _foodDao.getAll();
    final meals = await _mealDao.getAll();
    final quickEntries = await _quickEntryDao.getAll();

    // Daily goals from shared_preferences.
    final prefs = await SharedPreferences.getInstance();
    final hasLocalGoals = prefs.containsKey('goal_kcal');

    final total = foods.length +
        meals.length +
        quickEntries.length +
        (hasLocalGoals ? 1 : 0);
    var done = 0;
    void tick(String label) {
      done++;
      onProgress?.call(MigrationProgress(done: done, total: total, label: label));
    }

    // Foods first — meals snapshot food data, so we want freshly-uploaded URLs
    // available when we re-read foods to populate items.
    for (final food in foods) {
      await _foodRepo.insert(food);
      tick('Imported food: ${food.name}');
    }

    // Reload foods so we have the new photo URLs.
    final reloaded = await _foodDao.getAll();
    final foodByLocalId = {for (final f in reloaded) f.id: f};

    // Meals — re-fetch so items are loaded with foods, then ensure each item's
    // food snapshot uses the just-uploaded URL rather than the local path.
    for (final meal in meals) {
      final patchedItems = meal.items.map((item) {
        // The local DAO joins food in by id; the food on the item still has
        // the local photo path. Look up the (now-uploaded) version.
        final fresh = foodByLocalId[item.foodId];
        return fresh == null ? item : item.copyWith(food: fresh);
      }).toList();
      await _mealRepo.insert(meal.copyWith(items: patchedItems));
      tick('Imported meal');
    }

    for (final entry in quickEntries) {
      await _quickEntryRepo.insert(entry);
      tick('Imported quick entry');
    }

    if (hasLocalGoals) {
      await _goalsRepo.save(DailyGoals(
        kcal: prefs.getDouble('goal_kcal') ?? 2000,
        protein: prefs.getDouble('goal_protein') ?? 150,
        fat: prefs.getDouble('goal_fat') ?? 65,
        carbs: prefs.getDouble('goal_carbs') ?? 200,
      ));
      tick('Imported goals');
    }

    await _fs.migrationDoc.set({
      'migratedAt': FieldValue.serverTimestamp(),
      'source': 'sqflite',
      'foodCount': foods.length,
      'mealCount': meals.length,
      'quickEntryCount': quickEntries.length,
      'goalsImported': hasLocalGoals,
    });

    return MigrationResult(
      foodCount: foods.length,
      mealCount: meals.length,
      quickEntryCount: quickEntries.length,
      goalsImported: hasLocalGoals,
    );
  }
}

class MigrationProgress {
  final int done;
  final int total;
  final String label;
  const MigrationProgress(
      {required this.done, required this.total, required this.label});
}

class MigrationResult {
  final int foodCount;
  final int mealCount;
  final int quickEntryCount;
  final bool goalsImported;
  const MigrationResult({
    required this.foodCount,
    required this.mealCount,
    required this.quickEntryCount,
    required this.goalsImported,
  });
}

final migrationServiceProvider = Provider<MigrationService>((ref) =>
    MigrationService(
      foodDao: ref.watch(foodDaoProvider),
      mealDao: ref.watch(mealDaoProvider),
      quickEntryDao: ref.watch(quickEntryDaoProvider),
      foodRepo: ref.watch(foodRepositoryProvider),
      mealRepo: ref.watch(mealRepositoryProvider),
      quickEntryRepo: ref.watch(quickEntryRepositoryProvider),
      goalsRepo: ref.watch(dailyGoalsRepositoryProvider),
      firestoreService: ref.watch(firestoreServiceProvider),
    ));
