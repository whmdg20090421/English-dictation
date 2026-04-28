# Tasks

- [x] Task 1: Update Dependencies
  - [x] SubTask 1.1: Add `cryptography` package to `pubspec.yaml` (e.g., `^2.5.0` or latest compatible).
  - [x] SubTask 1.2: Ensure `flutter_secure_storage` is configured properly for Android/iOS (already in pubspec).

- [x] Task 2: Implement Cryptographic Primitives (`CryptoUtils`)
  - [x] SubTask 2.1: Implement `Argon2id` for Password Hashing (Admin Password). Needs a randomly generated `Salt` (e.g., 16 bytes). Return Hash and Salt.
  - [x] SubTask 2.2: Implement `Argon2id` for Key Derivation (MEK). Takes MEK Password and `Salt`. Returns derived `SecretKey` (MEK) for AES-256-GCM.
  - [x] SubTask 2.3: Modify `encryptPassword` and `verifyPassword` to utilize the new hashing scheme instead of AES fixed IV encryption.

- [x] Task 3: Implement Anti-Brute-Force Rate Limiting
  - [x] SubTask 3.1: Create a `RateLimiter` class or integrate into `CryptoUtils` / `SharedPreferences` to track `failed_attempts` and `lockout_until` timestamp.
  - [x] SubTask 3.2: Implement check before allowing Admin Password or MEK Password verification. Lock for 15 minutes after 5 consecutive failures.

- [x] Task 4: Refactor Cloud Setup & Sync Service
  - [x] SubTask 4.1: Modify `CloudSetupScreen` to generate Salts during initialization and store them.
  - [x] SubTask 4.2: Update the `Config.json` schema uploaded to WebDAV to store `Admin_Hash`, `Admin_Salt`, `Guest_Hash`, `Guest_Salt`, and `MEK_Salt`.
  - [x] SubTask 4.3: Ensure `CloudSyncService` uses the derived MEK (instead of directly using the string password) for AES-GCM encryption/decryption of `data.json`.

- [x] Task 5: Refactor Local Data Manager & Admin Auth
  - [x] SubTask 5.1: Update `DataManager` to store the new Hash and Salt structures instead of the old encrypted passwords.
  - [x] SubTask 5.2: Update `AdminScreen` to verify passwords against the new Argon2id Hashes and respect the Rate Limiting lockout.
  - [x] SubTask 5.3: Ensure backward compatibility or wipe old DB cleanly if schema migration fails during SQLCipher initialization.

# Task Dependencies
- Task 2 depends on Task 1.
- Task 4 and 5 depend on Task 2 and Task 3.