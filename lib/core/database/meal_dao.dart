import 'package:sqflite/sqflite.dart';
import '../models/meal.dart';
import '../models/meal_food_item.dart';
import 'app_database.dart';
import 'food_dao.dart';

class MealDao {
  final AppDatabase _db;
  final FoodDao _foodDao;
  MealDao(this._db, this._foodDao);

  Future<List<Meal>> getAll() async {
    final db = await _db.database;
    final mealRows = await db.query('meals', orderBy: 'created_at DESC');
    final meals = <Meal>[];
    for (final row in mealRows) {
      final items = await _itemsForMeal(db, row['id'] as String);
      meals.add(Meal.fromMap(row, items: items));
    }
    return meals;
  }

  Future<Meal?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('meals', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final items = await _itemsForMeal(db, id);
    return Meal.fromMap(rows.first, items: items);
  }

  Future<Meal?> getLatest() async {
    final db = await _db.database;
    final rows =
        await db.query('meals', orderBy: 'created_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    final items = await _itemsForMeal(db, rows.first['id'] as String);
    return Meal.fromMap(rows.first, items: items);
  }

  Future<List<Meal>> getForDay(DateTime day) async {
    final db = await _db.database;
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end =
        DateTime(day.year, day.month, day.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    final rows = await db.query(
      'meals',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start, end],
      orderBy: 'created_at ASC',
    );
    final meals = <Meal>[];
    for (final row in rows) {
      final items = await _itemsForMeal(db, row['id'] as String);
      meals.add(Meal.fromMap(row, items: items));
    }
    return meals;
  }

  Future<List<MealFoodItem>> _itemsForMeal(Database db, String mealId) async {
    final rows = await db.query('meal_food_items',
        where: 'meal_id = ?', whereArgs: [mealId]);
    final items = <MealFoodItem>[];
    for (final row in rows) {
      final food = await _foodDao.getById(row['food_id'] as String);
      items.add(MealFoodItem.fromMap(row, food: food));
    }
    return items;
  }

  Future<void> insert(Meal meal) async {
    final db = await _db.database;
    await db.insert('meals', meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final item in meal.items) {
      await db.insert('meal_food_items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> update(Meal meal) async {
    final db = await _db.database;
    await db.update('meals', meal.toMap(),
        where: 'id = ?', whereArgs: [meal.id]);
    await db.delete('meal_food_items',
        where: 'meal_id = ?', whereArgs: [meal.id]);
    for (final item in meal.items) {
      await db.insert('meal_food_items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertAll(List<Meal> meals) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final meal in meals) {
      batch.insert('meals', meal.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in meal.items) {
        batch.insert('meal_food_items', item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('meal_food_items');
    await db.delete('meals');
  }
}
