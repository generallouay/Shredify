import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/food_dao.dart';
import '../database/meal_dao.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../models/meal_food_item.dart';

class BackupService {
  final AppDatabase _db;
  final FoodDao _foodDao;
  final MealDao _mealDao;

  BackupService(this._db, this._foodDao, this._mealDao);

  Future<String> imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'shredify', 'images'));
    dir.createSync(recursive: true);
    return dir.path;
  }

  Future<String> createBackup() async {
    final archive = Archive();

    // Add database
    final dbPath = await _db.dbPath;
    if (File(dbPath).existsSync()) {
      final dbBytes = File(dbPath).readAsBytesSync();
      archive.addFile(ArchiveFile('shredify.db', dbBytes.length, dbBytes));
    }

    // Add images
    final imgDir = Directory(await imagesDir());
    if (imgDir.existsSync()) {
      for (final f in imgDir.listSync().whereType<File>()) {
        final bytes = f.readAsBytesSync();
        archive.addFile(
            ArchiveFile('images/${p.basename(f.path)}', bytes.length, bytes));
      }
    }

    final zipBytes = ZipEncoder().encode(archive)!;
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'shredify_backup_$ts.zip';

    Directory? outDir = await getExternalStorageDirectory();
    outDir ??= await getApplicationDocumentsDirectory();

    final outPath = p.join(outDir.path, fileName);
    File(outPath).writeAsBytesSync(zipBytes);
    return outPath;
  }

  Future<void> restoreBackup(String zipPath) async {
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = await getTemporaryDirectory();
    final imgDir = await imagesDir();
    String? tempDbPath;
    bool isOldFormat = false;

    // Single pass: extract DB file and images together
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final content = entry.content as List<int>;

      if (entry.name == 'shredify.db') {
        tempDbPath = p.join(tempDir.path, 'restore_shredify.db');
        File(tempDbPath).writeAsBytesSync(content);
      } else if (entry.name == 'meals.db3') {
        isOldFormat = true;
        tempDbPath = p.join(tempDir.path, 'restore_meals.db3');
        File(tempDbPath).writeAsBytesSync(content);
      } else if (entry.name.startsWith('images/')) {
        final name = p.basename(entry.name);
        if (name.isNotEmpty) {
          File(p.join(imgDir, name)).writeAsBytesSync(content);
        }
      }
    }

    if (tempDbPath == null) throw Exception('No database found in backup');

    final tempDb = await openDatabase(tempDbPath, readOnly: true);
    await _foodDao.deleteAll();
    await _mealDao.deleteAll();

    if (isOldFormat) {
      await _importOld(tempDb);
    } else {
      await _importNew(tempDb);
    }
    await tempDb.close();
  }

  Future<void> _importOld(Database src) async {
    final imgDir = await imagesDir();
    final foodRows = await src.query('Food');
    final foods = foodRows.map((row) {
      final canSize =
          row['CanSize'] != null ? (row['CanSize'] as num).toDouble() : null;
      final rawPath = row['PhotoPath'] as String?;
      String? photoPath;
      if (rawPath != null && rawPath.isNotEmpty) {
        final name = p.basename(rawPath);
        final local = p.join(imgDir, name);
        photoPath = File(local).existsSync() ? local : null;
      }
      return Food(
        id: row['Id'] as String,
        name: row['Name'] as String,
        kcal: (row['Kcal'] as num).toDouble(),
        protein: (row['Protein'] as num).toDouble(),
        fat: (row['Fat'] as num).toDouble(),
        carbs: (row['Carbs'] as num).toDouble(),
        type: (canSize != null && canSize > 0)
            ? FoodType.canister
            : FoodType.standard,
        canSize: (canSize != null && canSize > 0) ? canSize : null,
        photoPath: photoPath,
      );
    }).toList();
    await _foodDao.insertAll(foods);

    final mealRows = await src.query('Meal');
    final meals = <Meal>[];
    for (final mRow in mealRows) {
      final mealId = mRow['Id'] as String;
      final itemRows = await src.query('MealFoodItems',
          where: 'MealId = ?', whereArgs: [mealId]);
      final items = itemRows.map((r) {
        final canCount = r['CanCount'] as int?;
        final isContainer = (r['IsContainer'] as int?) == 1;
        MeasurementMethod method;
        double? weightGrams, weightBefore, weightAfter;
        int? cc;
        if (canCount != null && canCount > 0) {
          method = MeasurementMethod.canister;
          cc = canCount;
        } else if (isContainer) {
          method = MeasurementMethod.container;
          weightBefore = r['WeightBefore'] != null
              ? (r['WeightBefore'] as num).toDouble()
              : null;
          weightAfter = r['WeightAfter'] != null
              ? (r['WeightAfter'] as num).toDouble()
              : null;
        } else {
          method = MeasurementMethod.standard;
          weightGrams = r['WeightBefore'] != null
              ? (r['WeightBefore'] as num).toDouble()
              : null;
        }
        return MealFoodItem(
          id: r['Id'] as String,
          mealId: mealId,
          foodId: r['FoodId'] as String,
          method: method,
          weightGrams: weightGrams,
          weightBefore: weightBefore,
          weightAfter: weightAfter,
          canCount: cc,
        );
      }).toList();
      meals.add(Meal(
        id: mealId,
        createdAt: _parseDotNetDate(mRow['CreatedAt']),
        items: items,
      ));
    }
    await _mealDao.insertAll(meals);
  }

  // .NET DateTime ticks (100ns since Jan 1, 0001) vs Unix ms (since Jan 1, 1970).
  // Values > 1e15 are ticks; smaller values are already Unix ms.
  static DateTime _parseDotNetDate(dynamic value) {
    if (value == null) return DateTime.now();
    final raw = value as int;
    if (raw > 1000000000000000) {
      const dotNetEpochOffsetMs = 62135596800000; // ms between 0001-01-01 and 1970-01-01
      return DateTime.fromMillisecondsSinceEpoch(raw ~/ 10000 - dotNetEpochOffsetMs);
    }
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> _importNew(Database src) async {
    final foodRows = await src.query('foods');
    await _foodDao.insertAll(foodRows.map(Food.fromMap).toList());

    final mealRows = await src.query('meals');
    final meals = <Meal>[];
    for (final mRow in mealRows) {
      final mealId = mRow['id'] as String;
      final itemRows = await src.query('meal_food_items',
          where: 'meal_id = ?', whereArgs: [mealId]);
      final items = itemRows.map((r) => MealFoodItem.fromMap(r)).toList();
      meals.add(Meal.fromMap(mRow, items: items));
    }
    await _mealDao.insertAll(meals);
  }
}
