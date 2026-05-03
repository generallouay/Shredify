import 'package:sqflite/sqflite.dart';
import '../models/food.dart';
import 'app_database.dart';

class FoodDao {
  final AppDatabase _db;
  FoodDao(this._db);

  Future<List<Food>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('foods', orderBy: 'name ASC');
    return rows.map(Food.fromMap).toList();
  }

  Future<Food?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('foods', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Food.fromMap(rows.first);
  }

  Future<void> insert(Food food) async {
    final db = await _db.database;
    await db.insert('foods', food.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Food food) async {
    final db = await _db.database;
    await db.update('foods', food.toMap(),
        where: 'id = ?', whereArgs: [food.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertAll(List<Food> foods) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final f in foods) {
      batch.insert('foods', f.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('foods');
  }
}
