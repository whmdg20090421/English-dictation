import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoUtils {
  // Use a fixed IV to ensure deterministic encryption for password comparison
  // (As explicitly requested by the user: "encrypt again and compare")
  static final _fixedIV = encrypt.IV.fromLength(12); // 12-byte zero IV for deterministic AES-GCM

  static encrypt.Key _deriveKey(String password) {
    const envKey = String.fromEnvironment('ENCRYPTION_KEY');
    final String keyToUse = envKey.isNotEmpty ? envKey : password;
    final bytes = utf8.encode(keyToUse);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  static String encryptPassword(String plainPassword, String encryptionKey) {
    if (plainPassword.isEmpty) return '';
    final key = _deriveKey(encryptionKey);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    
    final encrypted = encrypter.encrypt(plainPassword, iv: _fixedIV);
    return encrypted.base64;
  }

  static bool verifyPassword(String inputPassword, String storedEncryptedPassword, String encryptionKey) {
    if (storedEncryptedPassword.isEmpty && inputPassword.isEmpty) return true;
    final encryptedInput = encryptPassword(inputPassword, encryptionKey);
    return encryptedInput == storedEncryptedPassword;
  }
}
