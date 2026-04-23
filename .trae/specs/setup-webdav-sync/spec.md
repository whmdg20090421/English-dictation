# WebDAV Sync & AES-256-GCM Encryption Spec

## Why
用户希望将 123pan WebDAV 作为应用的中央同步服务器，以实现多端数据同步。同时要求所有上传的 JSON 数据和单词目录必须使用 AES-256-GCM 进行加密以防篡改。在应用首次启动时，需检查云端是否已初始化密码配置，若无则引导用户设置各种管理员/访客密码及加密密钥等。

## What Changes
- 引入 WebDAV 客户端和 AES-GCM 加密依赖库（如 `webdav_client`，`cryptography` 等）。
- 建立专门的 `CloudSyncService` 类，负责连接 `https://webdav.123pan.cn/webdav`。
- 修改应用的启动流程，增加“云端初始化状态检查”环节。
- 构建一个全新的初始化 UI 界面，用于在云端未配置时收集：管理员密码、访客密码、加密密钥，以及可选的临时密码及其权限和实现规则。
- 将配置信息打包为 JSON，并使用用户输入的加密密钥（AES-256-GCM）进行加密，上传至云端数据目录 `/英语听写/data/`。
- 改造现有的 `DataManager`，确保所有本地数据的读写都与加密的 WebDAV 后端进行同步防篡改校验。

## Impact
- Affected specs: 应用程序的启动流程（路由拦截）、本地离线存储与云端数据同步的防篡改机制。
- Affected code: `main.dart`（入口路由逻辑）、`data_manager.dart`（数据存取）、新增 `cloud_sync_service.dart` 和相应的初始化 UI 页面。

## ADDED Requirements
### Requirement: 首次启动云端校验与初始化
The system SHALL provide 强制的云端校验流程。

#### Scenario: Success case (首次初始化)
- **WHEN** 用户打开应用，且 `CloudSyncService` 检查到云端 `/英语听写/data/config.json`（或加密配置名）不存在时
- **THEN** 弹出/跳转至“云端初始化设置”界面，要求输入管理员密码、访客密码、加密密钥等，并将其加密后上传到该目录。

### Requirement: 数据 AES-256-GCM 强制加密
- **WHEN** 应用上传任何单词目录、用户数据或 JSON 结构到 WebDAV 时
- **THEN** 必须使用应用启动时载入的“加密密钥”通过 AES-256-GCM 算法对数据进行全量加密。

## MODIFIED Requirements
### Requirement: 密码与权限隔离体系
修改原本基于本地离线 SQLite 验证的管理员/访客鉴权，转为与云端解密下发的配置文件进行比对校验。