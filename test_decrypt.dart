import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

encrypt.Key _deriveKey(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return encrypt.Key(Uint8List.fromList(digest.bytes));
}

void main() {
  final data = {'hello': 'world'};
  final key = _deriveKey('correct');
  final iv = encrypt.IV.fromSecureRandom(12);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
  final encrypted = encrypter.encrypt(jsonEncode(data), iv: iv);
  
  final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
  combined.setAll(0, iv.bytes);
  combined.setAll(iv.bytes.length, encrypted.bytes);
  
  final base64Data = base64Encode(combined);
  
  // Decrypt with wrong key
  try {
    final key2 = _deriveKey('wrong');
    final combined2 = base64Decode(base64Data);
    final ivBytes = combined2.sublist(0, 12);
    final encryptedBytes = combined2.sublist(12);
    final iv2 = encrypt.IV(ivBytes);
    final encrypter2 = encrypt.Encrypter(encrypt.AES(key2, mode: encrypt.AESMode.gcm));
    final encrypted2 = encrypt.Encrypted(encryptedBytes);
    final decrypted = encrypter2.decrypt(encrypted2, iv: iv2);
    print('Decrypted with wrong key: $decrypted');
  } catch (e) {
    print('Failed with wrong key: $e');
  }
}
