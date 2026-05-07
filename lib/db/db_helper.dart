import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/settings.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('questlog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE tasks (
  id $idType,
  title $textType,
  categoryId $textType,
  isCompleted $boolType,
  date $textType,
  repeatDays $textType
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  icon $textType
)
''');

    await db.execute('''
CREATE TABLE settings (
  id INTEGER PRIMARY KEY,
  targetAppPackage TEXT,
  lockActiveStatus INTEGER NOT NULL
)
''');
  }

  Future<void> insertTask(Task task) async {
    final db = await instance.database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks() async {
    final db = await instance.database;
    final maps = await db.query('tasks');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await instance.database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> insertCategory(Category category) async {
    final db = await instance.database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> getCategories() async {
    final db = await instance.database;
    final maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<void> updateSettings(Settings settings) async {
    final db = await instance.database;
    await db.insert('settings', settings.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Settings?> getSettings() async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return Settings.fromMap(maps.first);
    }
    return null;
  }
}
