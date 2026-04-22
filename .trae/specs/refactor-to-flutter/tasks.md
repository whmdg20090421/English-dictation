# Tasks

- [x] Task 1: 基础设施与项目初始化
  - [x] SubTask 1.1: 在工作区创建或初始化全新的 Flutter 项目，清理默认模板代码。
  - [x] SubTask 1.2: 引入必要依赖（如 `sqflite`, `provider` / `riverpod` 用于状态管理, `flutter_tts`, `video_player`, 动画库等）。
  - [x] SubTask 1.3: 封装全局 UI 主题（深蓝渐变色背景、`BackdropFilter` 毛玻璃组件、通用文字排版）。

- [x] Task 2: 离线数据库与账户看板迁移
  - [x] SubTask 2.1: 移植 SQLite 表结构（Accounts, Vocab, Settings, SyncQueue）及词库解析逻辑至 Dart。
  - [x] SubTask 2.2: 实现账户系统的增删改查、角色权限及本地登录记忆功能。
  - [x] SubTask 2.3: 开发首页 Dashboard，展示听写次数、练习单词数、正确率，以及未完成进度恢复与“错题本重练”弹窗。

- [x] Task 3: 专属数据详情页与管理后台
  - [x] SubTask 3.1: 开发数据详情页，使用 Flutter 的折叠列表展示书本/单元/单词结构，并实现文件夹聚合统计与单词精准流水弹窗。
  - [x] SubTask 3.2: 开发管理后台词库管理 Tab，支持书本/单元增删改及排序，支持单词多词性编辑。
  - [x] SubTask 3.3: 开发导入导出 Tab，实现文本格式的词库解析与导入，以及全量数据的 JSON 导出。
  - [x] SubTask 3.4: 开发设置与日志 Tab，控制单题限时、提示限制，并展示个人流水。

- [x] Task 4: 核心听写测试引擎与评分
  - [x] SubTask 4.1: 实现听写内容与模式（拼写/释义/混合）选择页面。
  - [x] SubTask 4.2: 开发测试界面，集成 `flutter_tts` 语音播报，实现单题与总计双倒计时器。
  - [x] SubTask 4.3: 移植智能提示（LCP 防碰撞）算法，处理输入防抖、抖动与颜色闪烁动画。
  - [x] SubTask 4.4: 移植评分算法，实现期中/期末结果展示，并提供“人工判卷 (Manual Grade)”功能，最终写入数据库。

- [x] Task 5: 附加功能：视频字幕听写与局域网同步
  - [x] SubTask 5.1: 集成 `video_player`，在底部叠加毛玻璃层遮挡字幕，复用底层听写评分逻辑。
  - [x] SubTask 5.2: 使用 Dart 搭建内嵌 HTTP/WebSocket Server，利用局域网广播机制（如 `nsd`）实现设备发现。
  - [x] SubTask 5.3: 实现离线同步队列机制，客户端联网后自动批量上传本地未同步记录，服务端支持手动推送。

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 2]
- [Task 5] depends on [Task 4]