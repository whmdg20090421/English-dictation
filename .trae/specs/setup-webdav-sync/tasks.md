# Tasks

- [x] Task 1: 引入并配置基础网络与加密依赖
  - 在 `pubspec.yaml` 中添加 WebDAV 客户端依赖（如 `webdav_client`）和高级加密依赖（如 `cryptography` 或 `encrypt`），并运行 `flutter pub get`。
- [x] Task 2: 实现云端通信与加密核心层 `CloudSyncService`
  - 创建 `lib/services/cloud_sync_service.dart`，配置指定的 WebDAV 账户（18302339198 / c4zl1zkp / https://webdav.123pan.cn/webdav），并实现通用的 AES-256-GCM 加解密工具方法。
- [x] Task 3: 构建云盘配置结构与启动校验逻辑
  - 在应用入口 (`main.dart` 或初始化屏) 增加逻辑：连接 WebDAV 检查 `/英语听写/data/` 目录下是否存在加密的全局配置文件（如 `config.enc`）。
- [x] Task 4: 开发云端首次初始化 UI 界面
  - 若检查到云端未配置，路由至全新的 `CloudSetupScreen`。
  - 界面要求输入：管理员密码、访客密码、加密密钥，以及可选配置（临时密码、临时密码实现方式、临时密码权限选择）。
- [x] Task 5: 提交加密的初始化配置至 WebDAV
  - 在 `CloudSetupScreen` 点击提交后，将表单数据序列化为 JSON，利用用户填写的“加密密钥”进行 AES-256-GCM 加密，并上传保存至云端根目录。
- [x] Task 6: 集成数据同步至现有的 DataManager
  - 改造 `DataManager` 的存取逻辑：所有题库与用户记录数据上传前，均经过 `CloudSyncService` 加密；下载后先解密，以保证云端文件的绝对防篡改安全。

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 2
- Task 4, 5 depends on Task 3
- Task 6 depends on Task 5