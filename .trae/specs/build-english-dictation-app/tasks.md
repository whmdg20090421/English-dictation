# Tasks

- [ ] Task 1: 第一阶段 - 基础设施与数据模型迁移
  - [ ] SubTask 1.1: 初始化 React Native + Expo 项目，配置 Expo Router 与 NativeWind。
  - [ ] SubTask 1.2: 分析 `英语听写.py` 中的数据结构，使用 `expo-sqlite` 设计对应的数据表（账号表、词库目录/单元/单词表、统计记录表、同步队列表）。
  - [ ] SubTask 1.3: 实现深蓝渐变色、玻璃态卡片（Glassmorphism）的全局 UI 主题封装，确保动画效果（防抖、闪烁等）还原。
  - [ ] SubTask 1.4: 开发多账户系统（创建、切换、重命名、删除，以及超管/管理员/普通用户的三级权限拓展）。

- [ ] Task 2: 第二阶段 - 原版核心功能 1:1 还原（界面与逻辑）
  - [ ] SubTask 2.1: 实现首页数据看板（听写次数、练词数、正确率），UI 文字严格遵循原版（"移动端听写系统"、"错题本重练"、"专属数据详情"等）。
  - [ ] SubTask 2.2: 实现听写测试引擎（倒计时、提示系统、模式切换、上一题/下一题、防作弊退出机制）。
  - [ ] SubTask 2.3: 实现专属数据详情页（目录/单词维度的数据统计、历史流水明细展示）。
  - [ ] SubTask 2.4: 实现管理后台（词库的增删改查、层级移动、系统设置）。
  - [ ] SubTask 2.5: 将原 Python 中的文本比对、评分算法与业务逻辑（如多词性校验）转译为 TypeScript。

- [ ] Task 3: 第三阶段 - 附加功能：视频听写模块
  - [ ] SubTask 3.1: 引入 `expo-av` 开发视频播放界面。
  - [ ] SubTask 3.2: 实现半透明字幕遮罩层，配合底部的答题输入框。
  - [ ] SubTask 3.3: 完成视频听写的评分逻辑并计入统一的历史记录数据库中。

- [ ] Task 4: 第四阶段 - 附加功能：局域网内嵌服务与同步
  - [ ] SubTask 4.1: 在管理员端集成 Node.js + Express 内嵌服务器（使用 Expo 适用方案运行 HTTP 和 WebSocket）。
  - [ ] SubTask 4.2: 引入 `react-native-zeroconf` 实现局域网服务广播与客户端发现。
  - [ ] SubTask 4.3: 搭建 WebSocket 服务实现设备在线状态监控。
  - [ ] SubTask 4.4: 开发离线优先的同步队列，实现客户端批量上传与管理员推送下发功能。

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 1]
- [Task 4] depends on [Task 1]
