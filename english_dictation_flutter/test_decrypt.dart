import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

encrypt.Key _deriveKey(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return encrypt.Key(Uint8List.fromList(digest.bytes));
}

String encryptData(Map<String, dynamic> data, String password) {
  final key = _deriveKey(password);
  final iv = encrypt.IV.fromSecureRandom(12);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

  final jsonString = jsonEncode(data);
  final encrypted = encrypter.encrypt(jsonString, iv: iv);

  final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
  combined.setAll(0, iv.bytes);
  combined.setAll(iv.bytes.length, encrypted.bytes);

  return base64Encode(combined);
}

Map<String, dynamic>? decryptData(String base64Data, String password) {
  try {
    final key = _deriveKey(password);
    final combined = base64Decode(base64Data);

    final ivBytes = combined.sublist(0, 12);
    final encryptedBytes = combined.sublist(12);

    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypt.Encrypted(encryptedBytes);

    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return (jsonDecode(decrypted) as Map).cast<String, dynamic>();
  } catch (e) {
    print('Decryption failed: $e');
    return null;
  }
}

void main() {
  final data = {'hello': 'world'};
  final enc = encryptData(data, 'correct_password');
  print('Encrypted: $enc');
  
  print('Trying to decrypt with wrong password...');
  final dec = decryptData(enc, 'wrong_password');
  print('Decrypted: $dec');
}
