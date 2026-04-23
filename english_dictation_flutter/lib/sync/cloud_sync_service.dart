import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:crypto/crypto.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  late webdav.Client _client;
  bool _isInitialized = false;

  final String _webdavUrl = 'https://webdav.123pan.cn/webdav';
  final String _user = '18302339198';
  final String _pwd = 'c4zl1zkp';
  final String _basePath = '/英语听写';
  final String _publicDataFolder = '/英语听写/公共数据';
  final String _configPath = '/英语听写/公共数据/配置.json';
  final String _publicDataPath = '/英语听写/公共数据/数据.json';
  String? _encryptionPassword;

  // Connection status stream
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void init() {
    if (!_isInitialized) {
      _client = webdav.newClient(
        _webdavUrl,
        user: _user,
        password: _pwd,
        debug: true,
      );
      _isInitialized = true;
      _checkConnection();
    }
  }

  Future<void> _checkConnection() async {
    try {
      await _client.ping();
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
    }
    _connectionStatusController.add(_isConnected);
  }

  Future<bool> ping() async {
    init();
    await _checkConnection();
    return _isConnected;
  }

  void setEncryptionPassword(String password) {
    _encryptionPassword = password;
  }

  String? get encryptionPassword => _encryptionPassword;

  // Derive a 32-byte key from the password using SHA-256
  encrypt.Key _deriveKey(String password) {
    const envKey = String.fromEnvironment('ENCRYPTION_KEY');
    final String keyToUse = envKey.isNotEmpty ? envKey : password;
    final bytes = utf8.encode(keyToUse);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  // Encrypt JSON map to Base64 string with AES-GCM
  String encryptData(Map<String, dynamic> data, String password) {
    final key = _deriveKey(password);
    // AES-GCM typically uses a 12-byte IV
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final jsonString = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);

    // Combine IV and Encrypted data
    // We can prepend the IV to the encrypted bytes and base64 encode the whole thing
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return base64Encode(combined);
  }

  // Decrypt Base64 string to JSON map
  Map<String, dynamic>? decryptData(String base64Data, String password) {
    try {
      final key = _deriveKey(password);
      final combined = base64Decode(base64Data);

      // Extract IV (first 12 bytes) and encrypted data
      final ivBytes = combined.sublist(0, 12);
      final encryptedBytes = combined.sublist(12);

      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final encrypted = encrypt.Encrypted(encryptedBytes);

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      print('Decryption failed: \$e');
      return null;
    }
  }

  // Check if config exists
  Future<bool> checkConfigExists() async {
    init();
    try {
      // We can try to get the file info or read it
      await _client.readDir(_publicDataFolder);
      final files = await _client.readDir(_publicDataFolder);
      for (var file in files) {
        if (file.path == _configPath || file.name == '配置.json') {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Check config exists error: \$e');
      return false;
    }
  }

  // Download and decrypt config
  Future<Map<String, dynamic>?> downloadConfig(String password) async {
    init();
    try {
      final bytes = await _client.read(_configPath);
      final base64String = utf8.decode(bytes);
      return decryptData(base64String, password);
    } catch (e) {
      print('Download config error: \$e');
      return null;
    }
  }

  // Encrypt and upload config
  Future<bool> uploadConfig(Map<String, dynamic> data, String password) async {
    init();
    try {
      // Ensure directory exists
      try {
        await _client.mkdir('/英语听写');
      } catch (_) {}
      try {
        await _client.mkdir(_publicDataFolder);
      } catch (_) {}

      final encryptedBase64 = encryptData(data, password);
      final bytes = Uint8List.fromList(utf8.encode(encryptedBase64));
      
      await _client.write(_configPath, bytes);
      return true;
    } catch (e) {
      print('Upload config error: \$e');
      return false;
    }
  }

  // Get personal data path
  String _getPersonalDataPath(String username) {
    return '$_basePath/$username/数据/数据.json';
  }

  // Get personal data folder
  String _getPersonalDataFolder(String username) {
    return '$_basePath/$username/数据';
  }

  // Ensure directories exist
  Future<void> _ensureDir(String path) async {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    String current = '';
    for (var part in parts) {
      current += '/$part';
      try {
        await _client.mkdir(current);
      } catch (_) {}
    }
  }

  // Download and decrypt public data
  Future<Map<String, dynamic>?> downloadPublicData() async {
    return _downloadFromPath(_publicDataPath);
  }

  // Download and decrypt personal data
  Future<Map<String, dynamic>?> downloadPersonalData(String username) async {
    return _downloadFromPath(_getPersonalDataPath(username));
  }

  Future<Map<String, dynamic>?> _downloadFromPath(String path) async {
    if (_encryptionPassword == null) return null;
    init();
    try {
      final bytes = await _client.read(path);
      final base64String = utf8.decode(bytes);
      return decryptData(base64String, _encryptionPassword!);
    } catch (e) {
      print('Download data error from $path: \$e');
      return null;
    }
  }

  // Encrypt and upload public data
  Future<bool> uploadPublicData(Map<String, dynamic> data) async {
    return _uploadToPath(_publicDataFolder, _publicDataPath, data);
  }

  // Encrypt and upload personal data
  Future<bool> uploadPersonalData(String username, Map<String, dynamic> data) async {
    return _uploadToPath(_getPersonalDataFolder(username), _getPersonalDataPath(username), data);
  }

  Future<bool> _uploadToPath(String folderPath, String filePath, Map<String, dynamic> data) async {
    if (_encryptionPassword == null) return false;
    init();
    try {
      await _ensureDir(folderPath);

      final encryptedBase64 = encryptData(data, _encryptionPassword!);
      final bytes = Uint8List.fromList(utf8.encode(encryptedBase64));

      await _client.write(filePath, bytes);
      return true;
    } catch (e) {
      print('Upload data error to $filePath: $e');
      return false;
    }
  }

  // Admin File Management Methods
  Future<List<webdav.File>> listFiles(String path) async {
    init();
    try {
      return await _client.readDir(path);
    } catch (e) {
      print('List files error: $e');
      return [];
    }
  }

  Future<bool> createFolder(String path) async {
    init();
    try {
      await _client.mkdir(path);
      return true;
    } catch (e) {
      print('Create folder error: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String path) async {
    init();
    try {
      await _client.removeAll(path);
      return true;
    } catch (e) {
      print('Delete file error: $e');
      return false;
    }
  }

  Future<bool> moveFile(String fromPath, String toPath) async {
    init();
    try {
      await _client.rename(fromPath, toPath, false); // false for overwrite? WebDAV typically uses rename or move.
      return true;
    } catch (e) {
      print('Move file error: $e');
      return false;
    }
  }

  Future<bool> copyFile(String fromPath, String toPath) async {
    init();
    try {
      await _client.copy(fromPath, toPath, false);
      return true;
    } catch (e) {
      print('Copy file error: $e');
      return false;
    }
  }
  
  Future<String?> readFileText(String path) async {
    init();
    try {
      final bytes = await _client.read(path);
      return utf8.decode(bytes);
    } catch (e) {
      print('Read file error: $e');
      return null;
    }
  }
  
  Future<bool> writeFileText(String path, String content) async {
    init();
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      await _client.write(path, bytes);
      return true;
    } catch (e) {
      print('Write file error: $e');
      return false;
    }
  }
}
