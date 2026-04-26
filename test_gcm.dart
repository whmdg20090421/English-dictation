import 'dart:convert';
import 'package:encrypt/encrypt.dart';
void main() {
  final key = Key.fromUtf8('my 32 length key................');
  final iv = IV.fromLength(12);
  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
  final encrypted = encrypter.encrypt('{"test": 1}', iv: iv);
  print(encrypted.bytes);
  print(encrypted.base64);
  
  final wrongKey = Key.fromUtf8('wrong 32 length key.............');
  final encrypter2 = Encrypter(AES(wrongKey, mode: AESMode.gcm));
  try {
    final dec = encrypter2.decrypt(Encrypted(encrypted.bytes), iv: iv);
    print('Decrypted with wrong key: $dec');
  } catch (e) {
    print('Error: $e');
  }
}
