# Refine Cloud Sync and UI Spec

## Why
用户需要进一步完善 WebDAV 云端同步功能，使用 GitHub Secrets 中预置的密钥进行强加密，优化错误提示的交互体验（覆盖显示而非排队），完善多账户体系（区分管理员与普通用户），并增加直观的云端状态指示器和强大的云端文件管理功能（支持管理员像文件管理器一样操作所有用户数据）。同时要求云端文件命名中文化，并对全量功能进行可用性复查。

## What Changes
- 修改 GitHub Actions 工作流，通过 `--dart-define` 注入 `KEY_PASSWORD` 作为全局加密密钥。
- 修改 `CloudSyncService`，默认使用注入的密钥进行 AES-256-GCM 加解密。
- 优化全局 `SnackBar` 提示逻辑，在显示新报错时先清除旧的提示（覆盖显示）。
- 账户添加流程增加角色选择（管理员/普通用户）。
- 顶部导航栏左侧增加 WebDAV 连接状态指示器（红/绿点）。
- 状态指示器点击弹窗包含：上传资料、下载资料、编辑云端资料（仅限管理员）。
- 数据同步目录区分：公共数据存放在 `/公共数据`，个人数据存放在 `/用户名/数据/`。
- 管理员拥有云端文件管理器功能，可查看、移动、复制、删除、编辑所有用户目录。
- 云端文件和目录的命名采用中文。
- 全量盘点现有功能，移除空壳代码，确保生产环境可用。

## Impact
- Affected specs: `setup-webdav-sync`, `build-english-dictation-app`
- Affected code: 
  - `.github/workflows/build-apk.yml`
  - `lib/services/cloud_sync_service.dart`
  - `lib/utils/snackbar_utils.dart` (或全局提示工具)
  - `lib/screens/admin_screen.dart` / `lib/screens/account_screen.dart`
  - `lib/widgets/cloud_status_indicator.dart`
  - `lib/screens/cloud_file_manager.dart`

## ADDED Requirements
### Requirement: GitHub Secret Encryption Key
系统必须从编译环境读取 `ENCRYPTION_KEY` 并用于所有云端数据的加密和解密。

### Requirement: Cloud Status Indicator
在主界面左上角必须存在一个状态指示灯，实时反映 WebDAV 的连通性。点击后可呼出云端数据操作面板。

### Requirement: Role-based Cloud Storage
数据必须按用户隔离。普通用户只能操作 `/用户名/数据/`，公共题库等数据存放于 `/公共数据`。管理员具备全量目录操作权限（文件管理器形态）。

## MODIFIED Requirements
### Requirement: SnackBar Overwrite
所有使用 `ScaffoldMessenger` 弹出的提示必须即时覆盖上一条，避免多条错误提示排队等待。

### Requirement: Add Account Flow
在添加账户时，必须弹窗询问新建账户的类型（管理员或普通用户）。
