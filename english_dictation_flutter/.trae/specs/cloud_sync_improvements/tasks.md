# Tasks

- [ ] Task 1: Fix encryption key validation
  - [ ] SubTask 1.1: Ensure `downloadConfig` or the validation logic in `cloud_setup_screen.dart` correctly identifies decryption failures and rejects incorrect passwords.
- [ ] Task 2: Improve AccountBindScreen UI
  - [ ] SubTask 2.1: Update the "or" divider text color to contrast with the background (e.g., white).
  - [ ] SubTask 2.2: Update the "Create new user" button text color to contrast with the background.
- [ ] Task 3: Fix auto-login and admin password requirements
  - [ ] SubTask 3.1: Ensure the app auto-logs in as the bound user on subsequent launches.
  - [ ] SubTask 3.2: Require admin password verification when switching users or creating new users from the login/home screen.
- [ ] Task 4: Implement cloud file/folder name encryption
  - [ ] SubTask 4.1: Update `CloudSyncService` to encrypt user folder names and file names before uploading to WebDAV.
  - [ ] SubTask 4.2: Update `CloudSyncService` to decrypt folder and file names when fetching the list of files from WebDAV.
  - [ ] SubTask 4.3: Ensure the Cloud File Manager uses the decrypted names for display but operates on the encrypted paths when interacting with WebDAV.
- [ ] Task 5: Github Upload and Build
  - [ ] SubTask 5.1: Commit the changes using git-commit skill.
  - [ ] SubTask 5.2: Upload to GitHub and trigger the build process following rules.

# Task Dependencies
- [Task 4] depends on [Task 1]
- [Task 5] depends on all previous tasks.
