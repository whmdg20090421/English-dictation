import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoUtils {
  static final _argon2id = Argon2id(
    memory: 65536, // 64 MB
    iterations: 3,
    parallelism: 2,
  );

  /// Generates a cryptographically secure random 16-byte salt
  static List<int> generateSalt() {
    final random = DartRandom();
    return random.nextBytes(16);
  }

  /// Hashes a password using Argon2id and a given salt
  /// Returns a Base64 encoded string of the hash
  static Future<String> hashPassword(String password, List<int> salt) async {
    if (password.isEmpty) return '';
    final secretKey = await _argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return base64Encode(bytes);
  }

  /// Verifies a password against an existing hash and salt
  static Future<bool> verifyPassword(String inputPassword, String storedHash, List<int> salt) async {
    if (storedHash.isEmpty && inputPassword.isEmpty) return true;
    final hash = await hashPassword(inputPassword, salt);
    return hash == storedHash;
  }

  /// Derives the Master Encryption Key (MEK) from the user's MEK Password and Salt
  /// Returns a 32-byte SecretKey (256-bit)
  static Future<SecretKey> deriveMEK(String mekPassword, List<int> salt) async {
    return await _argon2id.deriveKeyFromPassword(
      password: mekPassword,
      nonce: salt,
    );
  }
}
