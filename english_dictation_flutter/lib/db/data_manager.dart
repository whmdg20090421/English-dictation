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

  Future<void> loadLocalDataOnly() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Store');

    Map<String, dynamic> localVocab = {};
    Map<String, dynamic> localAccounts = {};
    Map<String, dynamic> localGlobalSettings = {};

    for (var row in maps) {
      if (row['key'] == 'vocab') localVocab = jsonDecode(row['value'] as String);
      if (row['key'] == 'accounts') localAccounts = jsonDecode(row['value'] as String);
      if (row['key'] == 'global_settings') localGlobalSettings = jsonDecode(row['value'] as String);
    }

    vocab = localVocab;
    accounts = localAccounts;
    globalSettings = localGlobalSettings;

    if (accounts.isEmpty) {
      accounts['default'] = {
        "name": "默认账户",
        "role": "admin",
        "createdAt": DateTime.now().toIso8601String(),
        "history": [],
        "mistakes": [],
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
      await _saveToLocalDB();
    }
    rebuildPosCache();
  }

  Future<void> syncWithCloud() async {
    // Attempt to download from cloud first if password is set
    final publicData = await CloudSyncService().downloadPublicData();
    bool isCloudEmpty = publicData == null || ((publicData['vocab'] as Map?)?.isEmpty ?? true);

    if (publicData != null && !isCloudEmpty) {
      vocab = publicData['vocab'] ?? {};
      globalSettings = publicData['global_settings'] ?? {};

      // Attempt to download personal data for all local accounts
      if (accounts.isNotEmpty) {
        for (var accId in accounts.keys) {
          final accName = accounts[accId]['name'];
          if (accName != null) {
            final personalData = await CloudSyncService().downloadPersonalData(accName);
            if (personalData != null && personalData['account'] != null) {
              accounts[accId] = personalData['account'];
            }
          }
        }
      }
      await _saveToLocalDB();
      rebuildPosCache();
    } else {
      // Cloud is empty (or failed to load) but we have local data, initialize cloud with local data
      await saveData();
    }
  }

  Future<void> loadData() async {
    await loadLocalDataOnly();
    await syncWithCloud();
  }

  Map<String, dynamic> getAcc(String accId) {
    if (!accounts.containsKey(accId)) {
      accId = accounts.keys.isNotEmpty ? accounts.keys.first : "default";
    }
    return accounts[accId] ?? {};
  }

  void rebuildPosCache() {
    posCache.clear();
    final allWords = DataManager.getAllWords(vocab);
    for (var w in allWords) {
      for (var k in w.keys) {
        if (!["单词", "word", "_uid", "source_book", "_ask_pos", "_test_mode", "_type", "translation"].contains(k)) {
          posCache.add(k.toLowerCase());
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
      final keys = accounts.keys.toList(); // Copy keys to prevent concurrent modification
      for (var accId in keys) {
        final acc = accounts[accId];
        if (acc != null) {
          final accName = acc['name'];
          if (accName != null) {
            await CloudSyncService().uploadPersonalData(accName, {
              'account': acc,
            });
          }
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

  static bool isFolder(Map<String, dynamic> node) {
    if (node.containsKey('_type') && node['_type'] == 'folder') return true;
    if (node.containsKey('_type') && node['_type'] == 'file') return false;
    
    if (node.isNotEmpty) {
      for (var val in node.values) {
        if (val is Map) {
          final mapVal = val;
          if (mapVal.containsKey('单词') || mapVal.containsKey('word')) {
            return false; // It's a file
          }
        }
      }
      return true; // It's a folder
    }
    return true; // Default empty node to folder unless explicitly file
  }

  static bool isFile(Map<String, dynamic> node) {
    if (node.containsKey('_type') && node['_type'] == 'file') return true;
    if (node.containsKey('_type') && node['_type'] == 'folder') return false;
    
    if (node.isNotEmpty) {
      // Try to find ANY word entry in the node to determine if it's a file
      for (var val in node.values) {
        if (val is Map) {
          final mapVal = val;
          if (mapVal.containsKey('单词') || mapVal.containsKey('word')) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static List<Map<String, dynamic>> getAllWords(Map<String, dynamic> root) {
    List<Map<String, dynamic>> allWords = [];
    void traverse(Map<String, dynamic> node) {
      if (isFile(node)) {
        node.forEach((key, value) {
          if (key != '_type' && value is Map && (value.containsKey('单词') || value.containsKey('word'))) {
            final meta = Map<String, dynamic>.from(value);
            meta['_uid'] = key;
            meta['word'] = meta['单词'] ?? meta['word'];
            if (!meta.containsKey('translation')) {
              for (var k in meta.keys) {
                if (!["单词", "word", "_uid", "source_book", "_ask_pos", "_test_mode"].contains(k)) {
                  meta['translation'] = meta[k];
                  meta['_ask_pos'] = k;
                  break;
                }
              }
            }
            allWords.add(meta);
          }
        });
      } else {
        node.forEach((key, value) {
          if (key != '_type' && value is Map<String, dynamic>) {
            traverse(value);
          } else if (key != '_type' && value is Map) {
             traverse(Map<String, dynamic>.from(value));
          }
        });
      }
    }
    traverse(root);
    return allWords;
  }

  Future<void> cleanEmptyNodes(List<String> path) async {
    // Recursively removes empty nodes backwards up the path
    bool removedAny = false;
    for (int i = path.length; i > 0; i--) {
      Map<String, dynamic> curr = vocab;
      for (int j = 0; j < i - 1; j++) {
        if (curr[path[j]] is Map) {
          curr = curr[path[j]] as Map<String, dynamic>;
        } else {
          return;
        }
      }
      final keyToRemove = path[i - 1];
      if (curr[keyToRemove] is Map) {
        final node = curr[keyToRemove] as Map<String, dynamic>;
        // Keep _type but if no other keys, it's empty
        bool isEmpty = node.keys.where((k) => k != '_type').isEmpty;
        if (isEmpty) {
          curr.remove(keyToRemove);
          removedAny = true;
        } else {
          break; // Stop if we hit a non-empty node
        }
      }
    }
    if (removedAny) {
      await saveData();
    }
  }
}
