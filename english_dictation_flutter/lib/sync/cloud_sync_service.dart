import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cryptography/cryptography.dart' as crypto;

import 'webdav_new/webdav_client.dart';
import 'webdav_new/webdav_service.dart';
import 'webdav_new/webdav_file.dart';
import '../utils/crypto_utils.dart';
import '../db/data_manager.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  late WebDavClient _client;
  late WebDavService _service;
  bool _isInitialized = false;

  final String _webdavUrl = 'https://webdav.123pan.cn/webdav';
  final String _user = '18302339198';
  final String _pwd = 'c4zl1zkp';
  final String _basePath = '/英语听写';
  final String _publicDataFolder = '/英语听写/公共数据';
  final String _configPath = '/英语听写/公共数据/配置.json';
  final String _publicDataPath = '/英语听写/公共数据/数据.json';
  String? _encryptionPassword;
  List<int>? _mekSalt;

  // Connection status stream
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final List<String> _errorLogs = [];
  List<String> get errorLogs => _errorLogs;

  void _logError(String msg) {
    final time = DateTime.now().toLocal().toString().split('.')[0];
    _errorLogs.insert(0, '[$time] $msg');
    if (_errorLogs.length > 50) _errorLogs.removeLast();
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  void init() {
    if (!_isInitialized) {
      _client = WebDavClient(
        baseUrl: _webdavUrl,
        username: _user,
        password: _pwd,
      );
      _service = WebDavService(_client);
      _isInitialized = true;
      _checkConnection();
    }
  }

  Future<void> _checkConnection() async {
    try {
      await _service.readDir('/');
      _isConnected = true;
      _connectionStatusController.add(_isConnected);
    } catch (e) {
      _logError('Ping error: $e');
    }
  }

  Future<bool> ping() async {
    init();
    await _checkConnection();
    return _isConnected;
  }

  void setEncryptionPassword(String password) {
    _encryptionPassword = password;
  }

  void setEncryptionPasswordAndSalt(String password, List<int> salt) {
    _encryptionPassword = password;
    _mekSalt = salt;
  }

  String? get encryptionPassword => _encryptionPassword;

  // Use a fixed salt for encrypting the config file itself, since we don't have the mekSalt yet
  static final List<int> _configFixedSalt = utf8.encode('config_fixed_salt_for_mek_derivation_v1');

  Future<crypto.SecretKey> _deriveKey(String password, {List<int>? salt}) async {
    const envKey = String.fromEnvironment('ENCRYPTION_KEY');
    final String keyToUse = envKey.isNotEmpty ? envKey : password;
    
    List<int> actualSalt = salt ?? _mekSalt ?? [];
    if (actualSalt.isEmpty) {
      // Fallback to config fixed salt if no salt provided and mekSalt is null
      actualSalt = _configFixedSalt;
    }
    
    return await CryptoUtils.deriveMEK(keyToUse, actualSalt);
  }

  // Encrypt JSON map to Base64 string with AES-GCM
  Future<String> encryptData(Map<String, dynamic> data, String password, {List<int>? salt}) async {
    final secretKey = await _deriveKey(password, salt: salt);
    final keyBytes = await secretKey.extractBytes();
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final jsonString = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);

    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);

    return base64Encode(combined);
  }

  // Decrypt Base64 string to JSON map
  Future<Map<String, dynamic>?> decryptData(String base64Data, String password, {List<int>? salt}) async {
    try {
      final secretKey = await _deriveKey(password, salt: salt);
      final keyBytes = await secretKey.extractBytes();
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      
      final combined = base64Decode(base64Data);

      final ivBytes = combined.sublist(0, 12);
      final encryptedBytes = combined.sublist(12);

      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final encrypted = encrypt.Encrypted(encryptedBytes);

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return (jsonDecode(decrypted) as Map).cast<String, dynamic>();
    } catch (e) {
      _logError('Decryption failed: $e');
      return null;
    }
  }

  // Check if config exists
  Future<bool> checkConfigExists() async {
    init();
    try {
      final dirPath = _publicDataFolder.endsWith('/') ? _publicDataFolder : '$_publicDataFolder/';
      final files = await _service.readDir(dirPath);
      for (var file in files) {
        if (file.path == _configPath || file.name == '配置.json') {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Check config exists error (expected if new): $e');
      return false;
    }
  }

  // Download and decrypt config
  Future<Map<String, dynamic>?> downloadConfig(String password) async {
    init();
    try {
      final bytes = await _service.readBytes(_configPath);
      final base64String = utf8.decode(bytes);
      // Config always uses the fixed salt so it can be decrypted before knowing MEK_Salt
      final config = await decryptData(base64String, password, salt: _configFixedSalt);
      if (config != null && config.containsKey('mekSalt')) {
        _mekSalt = (config['mekSalt'] as List).cast<int>();
      }
      return config;
    } catch (e) {
      _logError('Download config error: $e');
      return null;
    }
  }

  // Encrypt and upload config
  Future<bool> uploadConfig(Map<String, dynamic> data, String password) async {
    init();
    try {
      await _ensureDir(_publicDataFolder);

      // Config always uses the fixed salt so it can be decrypted before knowing MEK_Salt
      final encryptedBase64 = await encryptData(data, password, salt: _configFixedSalt);
      final bytes = Uint8List.fromList(utf8.encode(encryptedBase64));
      
      await _service.writeBytes(_configPath, bytes.toList());
      return true;
    } catch (e) {
      _logError('Upload config error: $e');
      return false;
    }
  }

  Future<String> encryptUsername(String username, String password) async {
    final secretKey = await _deriveKey(password);
    final keyBytes = await secretKey.extractBytes();
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(username, iv: iv);
    
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);
    
    return base64UrlEncode(combined).replaceAll('=', '');
  }

  // Get personal data path
  Future<String> _getPersonalDataPath(String username) async {
    if (_encryptionPassword == null) return '$_basePath/$username/数据/数据.json';
    final encName = await encryptUsername(username, _encryptionPassword!);
    return '$_basePath/$encName/数据/数据.json';
  }

  // Get personal data folder
  Future<String> _getPersonalDataFolder(String username) async {
    if (_encryptionPassword == null) return '$_basePath/$username/数据';
    final encName = await encryptUsername(username, _encryptionPassword!);
    return '$_basePath/$encName/数据';
  }

  // Ensure directories exist
  Future<void> _ensureDir(String path) async {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    String current = '';
    for (var part in parts) {
      current += '/$part';
      try {
        await _service.mkdir('$current/');
      } catch (e) {
        print('mkdir $current/ error (expected if exists): $e');
      }
    }
  }

  // Download and decrypt public data
  Future<Map<String, dynamic>?> downloadPublicData() async {
    return _downloadFromPath(_publicDataPath);
  }

  // Download and decrypt personal data
  Future<Map<String, dynamic>?> downloadPersonalData(String username) async {
    final path = await _getPersonalDataPath(username);
    return _downloadFromPath(path);
  }

  Future<Map<String, dynamic>?> _downloadFromPath(String path) async {
    if (_encryptionPassword == null) return null;
    init();
    try {
      final bytes = await _service.readBytes(path);
      final base64String = utf8.decode(bytes);
      // Retrieve mekSalt from DataManager if not set
      if (_mekSalt == null) {
        final savedSalt = DataManager.instance.globalSettings['mekSalt'];
        if (savedSalt != null) {
          _mekSalt = (savedSalt as List).cast<int>();
        }
      }
      return decryptData(base64String, _encryptionPassword!);
    } catch (e) {
      _logError('Download data error from $path: $e');
      return null;
    }
  }

  // Encrypt and upload public data
  Future<bool> uploadPublicData(Map<String, dynamic> data) async {
    return _uploadToPath(_publicDataFolder, _publicDataPath, data);
  }

  // Encrypt and upload personal data
  Future<bool> uploadPersonalData(String username, Map<String, dynamic> data) async {
    final folder = await _getPersonalDataFolder(username);
    final path = await _getPersonalDataPath(username);
    return _uploadToPath(folder, path, data);
  }

  Future<bool> _uploadToPath(String folderPath, String filePath, Map<String, dynamic> data) async {
    if (_encryptionPassword == null) return false;
    init();
    try {
      await _ensureDir(folderPath);

      // Retrieve mekSalt from DataManager if not set
      if (_mekSalt == null) {
        final savedSalt = DataManager.instance.globalSettings['mekSalt'];
        if (savedSalt != null) {
          _mekSalt = (savedSalt as List).cast<int>();
        }
      }

      final encryptedBase64 = await encryptData(data, _encryptionPassword!);
      final bytes = Uint8List.fromList(utf8.encode(encryptedBase64));

      await _service.writeBytes(filePath, bytes.toList());
      return true;
    } catch (e) {
      _logError('Upload data error to $filePath: $e');
      return false;
    }
  }

  // Admin File Management Methods
  Future<List<WebDavFile>> listFiles(String path) async {
    init();
    try {
      return await _service.readDir(path);
    } catch (e) {
      _logError('List files error: $e');
      return [];
    }
  }

  Future<bool> createFolder(String path) async {
    init();
    try {
      await _service.mkdir(path);
      return true;
    } catch (e) {
      _logError('Create folder error: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String path) async {
    init();
    try {
      await _service.remove(path);
      return true;
    } catch (e) {
      _logError('Delete file error: $e');
      return false;
    }
  }

  Future<bool> moveFile(String fromPath, String toPath) async {
    init();
    try {
      await _service.move(fromPath, toPath);
      return true;
    } catch (e) {
      _logError('Move file error: $e');
      return false;
    }
  }

  Future<bool> copyFile(String fromPath, String toPath) async {
    init();
    try {
      await _service.copy(fromPath, toPath);
      return true;
    } catch (e) {
      _logError('Copy file error: $e');
      return false;
    }
  }
  
  Future<String?> readFileText(String path) async {
    init();
    try {
      final bytes = await _service.readBytes(path);
      return utf8.decode(bytes);
    } catch (e) {
      _logError('Read file error: $e');
      return null;
    }
  }
  
  Future<bool> writeFileText(String path, String content) async {
    init();
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      await _service.writeBytes(path, bytes.toList());
      return true;
    } catch (e) {
      _logError('Write file error: $e');
      return false;
    }
  }
}
