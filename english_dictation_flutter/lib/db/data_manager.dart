import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DataManager {
  static final DataManager instance = DataManager._init();
  static Database? _database;

  Map<String, dynamic> vocab = {};
  Map<String, dynamic> accounts = {};
  Map<String, dynamic> globalSettings = {};
  Set<String> posCache = {};

  DataManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('english_dictation.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Store (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> loadData() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Store');
    
    Map<String, dynamic> data = {};
    for (var map in maps) {
      data[map['key'] as String] = jsonDecode(map['value'] as String);
    }
    
    vocab = data['vocab'] ?? {};
    accounts = data['accounts'] ?? {};
    globalSettings = data['global_settings'] ?? {};
    
    if (accounts.isEmpty) {
      accounts['default'] = {
        "name": "默认账户",
        "history": [],
        "stats": {},
        "settings": {
          "allow_backward": true,
          "allow_hint": false,
          "timer_lock": true,
          "per_q_time": 20.0,
          "hide_test_config": false,
          "hint_delay": 5,
          "hint_limit": 0,
          "folders": []
        }
      };
      await saveData();
    }
    rebuildPosCache();
  }

  Map<String, dynamic> getAcc(String accId) {
    if (!accounts.containsKey(accId)) {
      accId = accounts.keys.isNotEmpty ? accounts.keys.first : "default";
    }
    return accounts[accId] ?? {};
  }

  void rebuildPosCache() {
    posCache.clear();
    for (var b in vocab.values) {
      for (var u in (b as Map<String, dynamic>).values) {
        for (var w in (u as Map<String, dynamic>).values) {
          for (var k in (w as Map<String, dynamic>).keys) {
            if (!["单词", "_uid", "source_book", "_ask_pos", "_test_mode"].contains(k)) {
              posCache.add(k.toLowerCase());
            }
          }
        }
      }
    }
  }

  Future<void> saveData() async {
    rebuildPosCache();
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('Store', {'key': 'vocab', 'value': jsonEncode(vocab)}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('Store', {'key': 'accounts', 'value': jsonEncode(accounts)}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('Store', {'key': 'global_settings', 'value': jsonEncode(globalSettings)}, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  void updateWordStats(String accId, String wordText, bool isCorrect, [double timeSpent = 0]) {
    final acc = getAcc(accId);
    acc['stats'] ??= {};
    final stats = acc['stats'] as Map<String, dynamic>;
    if (!stats.containsKey(wordText)) {
      stats[wordText] = {
        "total": 0,
        "correct": 0,
        "wrong": 0,
        "cumulative_seconds": 0,
        "history": []
      };
    }
    final s = stats[wordText] as Map<String, dynamic>;
    s["total"] = (s["total"] as int) + 1;
    if (isCorrect) {
      s["correct"] = (s["correct"] as int) + 1;
    } else {
      s["wrong"] = (s["wrong"] as int) + 1;
    }
    s["cumulative_seconds"] = (s["cumulative_seconds"] as int) + timeSpent.toInt();
    
    final now = DateTime.now();
    final timeStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    (s["history"] as List).add({"time": timeStr, "result": isCorrect ? "对" : "错"});
  }

  Future<void> cleanEmptyNodes(String book, String unit) async {
    if (vocab[book] != null && (vocab[book] as Map)[unit] == null) {
      (vocab[book] as Map).remove(unit);
    }
    if (vocab[book] == null || (vocab[book] as Map).isEmpty) {
      vocab.remove(book);
    }
    await saveData();
  }
}
