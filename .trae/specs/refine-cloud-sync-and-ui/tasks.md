# Tasks
- [x] Task 1: 配置 GitHub Actions 密钥注入
  - [x] 修改 `.github/workflows/build-apk.yml`，在 flutter build apk 命令中增加 `--dart-define=ENCRYPTION_KEY=${{ secrets.KEY_PASSWORD }}`。
- [x] Task 2: 改造云端加密服务
  - [x] 修改 `CloudSyncService` 以读取 `const String.fromEnvironment('ENCRYPTION_KEY')`。
  - [x] 确保所有上传到云盘的文件、文件夹命名尽量采用中文（如：`配置.json`, `题库` 等）。
- [x] Task 3: 优化全局报错提示逻辑
  - [x] 封装一个全局提示工具（或修改现有逻辑），在调用 `showSnackBar` 前先执行 `clearSnackBars()`，确保新错误立刻覆盖旧错误。
- [x] Task 4: 完善账户添加流程
  - [x] 在添加账户界面/弹窗中，增加角色选择器（管理员/普通用户）。
  - [x] 确保账户模型支持角色区分，并保存到本地及同步至云端。
- [x] Task 5: 增加左上角云端状态指示器及弹窗
  - [x] 创建 `CloudStatusIndicator` 组件，置于左上角。绿色表示连接正常，红色表示异常。
  - [x] 点击指示器弹出菜单：上传资料、下载资料、编辑云端资料（编辑选项仅对管理员可见）。
- [x] Task 6: 实现按角色的云端文件同步
  - [x] 修改上传/下载逻辑：普通资料同步至 `/公共数据/`，个人资料同步至 `/用户名/数据/`。
  - [x] 普通用户只能触发属于自己的目录和公共目录的同步。
- [x] Task 7: 开发管理员云端文件管理器
  - [x] 创建 `CloudFileManagerScreen`，仅管理员可访问。
  - [x] 实现文件树浏览、点击进入用户目录、删除、编辑、移动、复制等完整 WebDAV 文件管理功能。
- [x] Task 8: 全量功能盘点与可用性修复
  - [x] 检查并移除应用内的空壳按钮和未实现功能。
  - [x] 确保听写、错误重练、数据统计等核心业务在生产环境下均能正常运行。

# Task Dependencies
- Task 2 depends on Task 1
- Task 5 depends on Task 2
- Task 6 depends on Task 5
- Task 7 depends on Task 6
- Task 8 can be done independently
