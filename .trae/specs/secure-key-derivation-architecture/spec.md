# Secure Key Derivation and Authentication Architecture Spec

## Why
Currently, the application relies on simple cryptographic primitives (SHA-256) and conflates the roles of the admin password with the encryption key password. This approach is vulnerable to brute-force attacks via GPU/ASIC if the ciphertext or hashes are compromised. Furthermore, there is no rate-limiting or lockout mechanism for local or cloud authentication attempts. We need a robust, cryptographically sound architecture separating authentication from data encryption, utilizing memory-hard KDFs (Key Derivation Functions) like Argon2id.

## What Changes
- **BREAKING**: Replace SHA-256 based password hashing with **Argon2id** (via `cryptography` package) for Admin Password authentication.
- **BREAKING**: Implement Key Derivation (KDF) for the Data Encryption Key (MEK) using Argon2id and a cryptographically secure random Salt.
- **BREAKING**: Cloud Config JSON format will change to store `Admin_Hash`, `Admin_Salt`, and `MEK_Salt` instead of directly encrypted passwords.
- Implement an anti-brute-force lockout mechanism (e.g., lock for 15 minutes after 5 failed attempts).
- Separate the concepts: Admin Password is used *only* for configuration access. MEK Password (密钥加密密码) is used *only* to derive the MEK for data encryption.

## Impact
- Affected specs: Authentication, Cloud Sync Initialization, Local Admin Access.
- Affected code: `pubspec.yaml`, `CryptoUtils`, `CloudSetupScreen`, `AdminScreen`, `DataManager`, `CloudSyncService`.

## ADDED Requirements
### Requirement: Cryptographic Separation of Duties
The system SHALL use the Admin Password exclusively for authenticating access to configuration settings.
The system SHALL use the MEK Password exclusively to derive the Master Encryption Key (MEK) for data encryption.

#### Scenario: Admin Login
- **WHEN** user attempts to access Admin settings
- **THEN** the system hashes the input password using Argon2id and the stored `Admin_Salt`.
- **THEN** the system compares the result with the stored `Admin_Hash`.

### Requirement: Anti-Brute-Force Lockout
The system SHALL implement a lockout mechanism for password attempts.

#### Scenario: Multiple Failed Attempts
- **WHEN** a user fails to enter the correct Admin Password 5 consecutive times
- **THEN** the system locks the authentication interface for 15 minutes.
- **THEN** the system prevents further attempts during the lockout period, storing the timestamp locally.

## MODIFIED Requirements
### Requirement: Data Encryption Key Derivation
Instead of directly using the SHA-256 hash of the user-provided encryption key, the system SHALL derive a 256-bit MEK using Argon2id, the MEK Password, and a randomly generated `MEK_Salt`. The `MEK_Salt` MUST be stored and synced alongside the encrypted data or config to allow derivation on other devices.

## REMOVED Requirements
### Requirement: Direct Password Encryption for Config
**Reason**: Encrypting the admin password with the encryption key and storing it in config conflates encryption and authentication, risking exposure.
**Migration**: Store the Argon2id hash of the admin password (`Admin_Hash`) and its salt (`Admin_Salt`) in the config instead.