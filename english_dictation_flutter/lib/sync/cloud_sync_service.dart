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
  final String _configPath = '/英语听写/data/config.json';
  final String _dataPath = '/英语听写/data/data.json';
  String? _encryptionPassword;

  void init() {
    if (!_isInitialized) {
      _client = webdav.newClient(
        _webdavUrl,
        user: _user,
        password: _pwd,
        debug: true,
      );
      _isInitialized = true;
    }
  }

  void setEncryptionPassword(String password) {
    _encryptionPassword = password;
  }

  String? get encryptionPassword => _encryptionPassword;

  // Derive a 32-byte key from the password using SHA-256
  encrypt.Key _deriveKey(String password) {
    final bytes = utf8.encode(password);
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
      await _client.readDir('/英语听写/data');
      final files = await _client.readDir('/英语听写/data');
      for (var file in files) {
        if (file.path == _configPath || file.name == 'config.json') {
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
        await _client.mkdir('/英语听写/data');
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

  // Download and decrypt data
  Future<Map<String, dynamic>?> downloadData() async {
    if (_encryptionPassword == null) return null;
    init();
    try {
      final bytes = await _client.read(_dataPath);
      final base64String = utf8.decode(bytes);
      return decryptData(base64String, _encryptionPassword!);
    } catch (e) {
      print('Download data error: \$e');
      return null;
    }
  }

  // Encrypt and upload data
  Future<bool> uploadData(Map<String, dynamic> data) async {
    if (_encryptionPassword == null) return false;
    init();
    try {
      try {
        await _client.mkdir('/英语听写');
      } catch (_) {}
      try {
        await _client.mkdir('/英语听写/data');
      } catch (_) {}

      final encryptedBase64 = encryptData(data, _encryptionPassword!);
      final bytes = Uint8List.fromList(utf8.encode(encryptedBase64));
      
      await _client.write(_dataPath, bytes);
      return true;
    } catch (e) {
      print('Upload data error: \$e');
      return false;
    }
  }
}
