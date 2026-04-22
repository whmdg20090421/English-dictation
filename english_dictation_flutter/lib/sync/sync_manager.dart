import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Mock Sync Queue Item
class SyncTask {
  final int id;
  final Map<String, dynamic> payload;
  final String status; // 'pending', 'processing', 'completed', 'failed'

  SyncTask({required this.id, required this.payload, this.status = 'pending'});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payload': jsonEncode(payload),
      'status': status,
    };
  }

  factory SyncTask.fromMap(Map<String, dynamic> map) {
    return SyncTask(
      id: map['id'],
      payload: jsonDecode(map['payload']),
      status: map['status'],
    );
  }
}

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  Database? _db;
  bool _isSyncing = false;
  Timer? _syncTimer;

  // Initialize SQLite database
  Future<void> initDB() async {
    if (_db != null) return;
    
    String path = join(await getDatabasesPath(), 'sync_queue.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          '''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payload TEXT,
            status TEXT
          )
          '''
        );
      },
    );
    
    // Start background sync timer (e.g., every 10 seconds)
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => _processSyncQueue());
  }

  // Add a stat record to local sync queue
  Future<void> addStatToQueue(Map<String, dynamic> statData) async {
    if (_db == null) await initDB();
    
    await _db!.insert(
      'sync_queue',
      {
        'payload': jsonEncode(statData),
        'status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Trigger sync immediately upon adding new task
    _processSyncQueue();
  }

  // Process the queue and upload to mock server
  Future<void> _processSyncQueue() async {
    if (_isSyncing || _db == null) return;
    _isSyncing = true;

    try {
      // Get pending tasks
      final List<Map<String, dynamic>> maps = await _db!.query(
        'sync_queue',
        where: 'status = ?',
        whereArgs: ['pending'],
        limit: 10, // Process 10 at a time
      );

      if (maps.isEmpty) {
        _isSyncing = false;
        return;
      }

      List<SyncTask> tasks = maps.map((map) => SyncTask.fromMap(map)).toList();

      for (var task in tasks) {
        bool success = await _mockUploadToServer(task.payload);
        
        if (success) {
          // Update status to completed or delete from queue
          await _db!.delete(
            'sync_queue',
            where: 'id = ?',
            whereArgs: [task.id],
          );
          print("Task ${task.id} uploaded successfully.");
        } else {
          // Optionally handle retry logic or mark as failed
          await _db!.update(
            'sync_queue',
            {'status': 'failed'},
            where: 'id = ?',
            whereArgs: [task.id],
          );
          print("Task ${task.id} upload failed.");
        }
      }
    } catch (e) {
      print("Error processing sync queue: \$e");
    } finally {
      _isSyncing = false;
    }
  }

  // Mock HTTP/WebSocket upload
  Future<bool> _mockUploadToServer(Map<String, dynamic> data) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate an 80% success rate
    bool isSuccess = (DateTime.now().millisecond % 10) < 8;
    
    if (isSuccess) {
      print("Mock Server: Received data: \$data");
      return true;
    } else {
      print("Mock Server: Network error");
      return false;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _db?.close();
  }
}
