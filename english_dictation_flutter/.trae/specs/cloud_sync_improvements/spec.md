# Cloud Sync and Security Improvements Spec

## Why
The cloud synchronization feature currently has several security and user experience issues. The encryption key validation allows incorrect keys to pass, UI text contrast is poor on the account binding screen, auto-login after binding is inconsistent, and cloud file/folder names expose sensitive user information in plaintext.

## What Changes
- Fix encryption key validation to correctly reject invalid passwords.
- Improve text contrast on the AccountBindScreen ("or" divider and "Create new user" button).
- Implement auto-login for the bound user on subsequent app launches.
- Require admin password verification when switching or creating new users.
- Encrypt folder names (user names) and file names before uploading to WebDAV.
- Automatically decrypt folder and file names when viewing in the Cloud File Manager using the admin's encryption key.
- **BREAKING**: Cloud file structure will change due to encrypted folder/file names. Existing unencrypted files might need a migration or will be re-uploaded.

## Impact
- Affected specs: Cloud Synchronization, User Authentication, UI/UX.
- Affected code: `splash_screen.dart`, `account_bind_screen.dart`, `cloud_sync_service.dart`, `cloud_file_manager_screen.dart`, `crypto_utils.dart`, `home_screen.dart`.

## ADDED Requirements
### Requirement: Encrypted Cloud Paths
The system SHALL encrypt all folder and file names uploaded to the cloud using the user's encryption key, and automatically decrypt them when displayed in the Cloud File Manager.

#### Scenario: Success case
- **WHEN** user syncs data to the cloud
- **THEN** the folder names (e.g., user names) and file names on WebDAV are encrypted (e.g., Base64 encoded AES cipher).
- **WHEN** admin views the Cloud File Manager
- **THEN** the encrypted names are automatically decrypted and displayed in plaintext.

## MODIFIED Requirements
### Requirement: Encryption Key Validation
The system SHALL strictly validate the encryption key during cloud setup and reject incorrect keys, preventing access to the account binding or home screen.

### Requirement: Account Binding UI & Flow
The AccountBindScreen SHALL use high-contrast text colors for readability. After a successful bind, the app SHALL automatically log in as the bound user on next launch. Switching or creating users SHALL require admin password verification.
