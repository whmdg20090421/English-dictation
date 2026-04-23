import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../sync/cloud_sync_service.dart';
import '../app_state.dart';

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
    // Attempt to download from cloud first if password is set
    final publicData = await CloudSyncService().downloadPublicData();
    if (publicData != null) {
      vocab = publicData['vocab'] ?? {};
      globalSettings = publicData['global_settings'] ?? {};
      
      // Attempt to download personal data for all local accounts
      // First, load local accounts to know which ones to fetch
      final db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query('Store', where: 'key = ?', whereArgs: ['accounts']);
      if (maps.isNotEmpty) {
        final localAccounts = jsonDecode(maps.first['value'] as String) as Map<String, dynamic>;
        for (var accId in localAccounts.keys) {
          final accName = localAccounts[accId]['name'];
          if (accName != null) {
            final personalData = await CloudSyncService().downloadPersonalData(accName);
            if (personalData != null && personalData['account'] != null) {
              accounts[accId] = personalData['account'];
            } else {
              accounts[accId] = localAccounts[accId];
            }
          }
        }
      }

      // Save cloud data to local DB to keep it in sync
      await _saveToLocalDB();
      rebuildPosCache();
      return;
    }

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
        "role": "admin",
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

  Future<void> _saveToLocalDB() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('Store', {'key': 'vocab', 'value': jsonEncode(vocab)}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('Store', {'key': 'accounts', 'value': jsonEncode(accounts)}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('Store', {'key': 'global_settings', 'value': jsonEncode(globalSettings)}, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> saveData() async {
    rebuildPosCache();
    await _saveToLocalDB();

    // Upload to cloud as single source of truth
    await CloudSyncService().uploadPublicData({
      'vocab': vocab,
      'global_settings': globalSettings,
    });

    // Determine current user
    // Since AppState depends on DataManager, we might not have direct access to AppState here without circular dependency
    // But we can check if the current user is admin by importing AppState or passing it
    // To avoid dependency issues, let's import app_state.dart
    final appState = AppState.instance;
    final currentAcc = getAcc(appState.currentAccountId);
    final isAdmin = currentAcc['role'] == 'admin';

    // Upload personal data
    if (isAdmin) {
      // Admins sync all local accounts to their respective directories
      for (var accId in accounts.keys) {
        final acc = accounts[accId];
        final accName = acc['name'];
        if (accName != null) {
          await CloudSyncService().uploadPersonalData(accName, {
            'account': acc,
          });
        }
      }
    } else {
      // Regular users only sync their own directory
      final accName = currentAcc['name'];
      if (accName != null) {
        await CloudSyncService().uploadPersonalData(accName, {
          'account': currentAcc,
        });
      }
    }
  }

  Future<void> downloadAllUsersData() async {
    final publicData = await CloudSyncService().downloadPublicData();
    if (publicData != null) {
      vocab = publicData['vocab'] ?? {};
      globalSettings = publicData['global_settings'] ?? {};
    }

    final allFolders = await CloudSyncService().listFiles('/英语听写');
    for (var folder in allFolders) {
      if (folder.isDir == true) {
        String folderName = folder.name ?? '';
        // Skip public folder and root itself
        if (folderName == '公共数据' || folderName == '英语听写' || folderName.isEmpty) continue;
        
        final personalData = await CloudSyncService().downloadPersonalData(folderName);
        if (personalData != null && personalData['account'] != null) {
          String? foundId;
          for (var entry in accounts.entries) {
            if (entry.value['name'] == folderName) {
              foundId = entry.key;
              break;
            }
          }
          foundId ??= DateTime.now().millisecondsSinceEpoch.toString() + folderName.hashCode.toString();
          
          accounts[foundId] = personalData['account'];
        }
      }
    }
    
    await _saveToLocalDB();
    rebuildPosCache();
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
