import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('english_dictation.db');
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
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE Accounts (
        id $idType,
        name $textType,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE Vocab (
        id $idType,
        account_id $integerType,
        word $textType,
        translation $textType,
        next_review $textType,
        level $integerType,
        FOREIGN KEY (account_id) REFERENCES Accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Settings (
        id $idType,
        account_id $integerType,
        key $textType,
        value $textType,
        FOREIGN KEY (account_id) REFERENCES Accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE SyncQueue (
        id $idType,
        action $textType,
        data $textType,
        created_at $textType
      )
    ''');
  }

  // Account operations
  Future<int> createAccount(String name) async {
    final db = await instance.database;
    return await db.insert('Accounts', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await instance.database;
    return await db.query('Accounts');
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete('Accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
