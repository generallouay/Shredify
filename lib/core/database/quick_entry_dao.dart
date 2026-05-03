import 'package:sqflite/sqflite.dart';
import '../models/quick_entry.dart';
import 'app_database.dart';

class QuickEntryDao {
  final AppDatabase _db;
  QuickEntryDao(this._db);

  Future<List<QuickEntry>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('quick_entries', orderBy: 'created_at DESC');
    return rows.map(QuickEntry.fromMap).toList();
  }

  Future<void> insert(QuickEntry entry) async {
    final db = await _db.database;
    await db.insert('quick_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('quick_entries', where: 'id = ?', whereArgs: [id]);
  }
}
