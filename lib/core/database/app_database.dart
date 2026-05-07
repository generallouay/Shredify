import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();

  static AppDatabase get instance => _instance ??= AppDatabase._();

  Future<Database> get database async => _db ??= await _init();

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'shredify.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        kcal REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        carbs REAL NOT NULL,
        type TEXT NOT NULL DEFAULT 'standard',
        can_size REAL,
        photo_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE meal_food_items (
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        food_id TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'standard',
        weight_grams REAL,
        weight_before REAL,
        weight_after REAL,
        can_count INTEGER,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
        FOREIGN KEY (food_id) REFERENCES foods(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_mfi_meal ON meal_food_items(meal_id)');
    await _createQuickEntriesTable(db);
    await _createMealEntriesTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createQuickEntriesTable(db);
    }
    if (oldVersion < 3) {
      await _createMealEntriesTable(db);
    }
  }

  Future<void> _createMealEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meal_entries (
        id TEXT PRIMARY KEY,
        meal_id TEXT NOT NULL,
        kcal REAL NOT NULL,
        protein REAL,
        carbs REAL,
        fat REAL,
        description TEXT,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createQuickEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quick_entries (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        kcal REAL NOT NULL,
        protein REAL,
        carbs REAL,
        fat REAL,
        description TEXT
      )
    ''');
  }

  Future<String> get dbPath async =>
      join(await getDatabasesPath(), 'shredify.db');

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
