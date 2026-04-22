# Tasks

- [x] Task 1: 基础设施与数据架构迁移
  - [x] SubTask 1.1: 初始化 React Native + Expo，配置 Expo Router 与 NativeWind，构建深蓝渐变色、毛玻璃 (Glassmorphism) 全局主题。
  - [x] SubTask 1.2: 使用 `expo-sqlite` 设计数据库表：`Accounts`（含 history 和 stats 的 JSON 字段）、`Vocab`（Book, Unit, Word, POS_Details）、`Settings`、`SyncQueue`。
  - [x] SubTask 1.3: 实现原版 `DataManager` 的 `auto_fix_db` 逻辑（自动拆分复合词性如 `v.(vt.)`）。

- [x] Task 2: 账户系统与主页看板
  - [x] SubTask 2.1: 实现账户的创建、切换、重命名、删除及设备状态记忆，整合超管/管理员/普通用户权限。
  - [x] SubTask 2.2: 开发首页 Dashboard，精确展示：听写次数、练词数、正确率百分比。
  - [x] SubTask 2.3: 实现“进度恢复”弹窗，检测未完成的听写状态，提供“继续进度”或“开始新听写”。
  - [x] SubTask 2.4: 实现“错题本重练”，从 Stats 中筛选 `wrong > 0` 的词汇，弹窗展示并支持全选/单选。

- [x] Task 3: 专属数据详情页 (Data Browser)
  - [x] SubTask 3.1: 实现词库树状折叠面板，展示每个词的“测 X 次 · 错 Y 次”。
  - [x] SubTask 3.2: 实现“目录聚合统计”弹窗（`show_folder_stats`），计算该目录的总频次及历史抽查会话流水。
  - [x] SubTask 3.3: 实现“单词精准流水”弹窗（`show_word_stats`），显示累计用时和最近 50 条按时间排序的对错记录。

- [x] Task 4: 管理后台 (Admin Console)
  - [x] SubTask 4.1: [词库管理] 实现新建根文件夹、层级展开，以及 Book/Unit/Word 的同级上下移动（Up/Down 排序）。
  - [x] SubTask 4.2: [词库管理] 实现单词编辑弹窗，支持动态增删词性（n., v. 等）及对应释义。
  - [x] SubTask 4.3: [导入导出] 实现原版文本解析逻辑，支持批量导入词库及全量 JSON 导出。
  - [x] SubTask 4.4: [系统设置] 还原全局设置项（单题时间、允许回退、允许提示、提示次数限制等）及安全密码修改。
  - [x] SubTask 4.5: [日志管理] 实现个人听写明细的查看与一键清空。

- [x] Task 5: 听写前置与测试引擎
  - [x] SubTask 5.1: 实现听写内容选择页（Select Content）和模式选择页（Select Mode：含融合生成试卷）。
  - [x] SubTask 5.2: 实现测试界面（Testing），包含单题倒计时（`q_time_left`）与总倒计时（`tot_left`）。
  - [x] SubTask 5.3: 实现智能提示系统（Hint），包含次数限制校验，以及基于最长公共前缀 (LCP) 的防碰撞字母掩码（`*`）生成。
  - [x] SubTask 5.4: 集成原版 `speakWord`（TTS 语音播放）功能。
  - [x] SubTask 5.5: 实现中途退出机制（弹窗选择“直接放弃”或“保存进度”，并准确记入 History）。

- [x] Task 6: 评分、人工判卷与结果
  - [x] SubTask 6.1: 完整复刻答案字符串比对、清洗、容错算法（支持多词性多释义匹配）。
  - [x] SubTask 6.2: 实现期中/期末报告（Interim Report / Results）。
  - [x] SubTask 6.3: 实现人工判卷（Manual Grade）界面，允许用户或老师覆盖系统的误判。
  - [x] SubTask 6.4: 将最终成绩及用时精准更新至 `Accounts.stats` 及 `Accounts.history`。

- [x] Task 7: 附加功能 - 视频字幕听写
  - [x] SubTask 7.1: 集成 `expo-av` 实现本地/远程视频播放控制。
  - [x] SubTask 7.2: 叠加玻璃态毛玻璃遮罩覆盖字幕区域，底部接入标准听写输入框，并复用评分逻辑。

- [x] Task 8: 附加功能 - 局域网离线同步
  - [x] SubTask 8.1: 管理员设备集成 Node.js + Express 和 WebSocket，并通过 `react-native-zeroconf` 广播服务。
  - [x] SubTask 8.2: 客户端实现局域网自动发现并建立 WebSocket 连接。
  - [x] SubTask 8.3: 开发离线同步队列，客户端联网时批量上传 `history/stats`，服务端支持手动下发题库。

- [x] Task 9: UI 动效与体验打磨
  - [x] SubTask 9.1: 补齐 Shake 抖动动画、正确/错误状态的背景颜色闪烁（Flash Success/Error）。
  - [x] SubTask 9.2: 确保移动端软键盘弹起时的视图偏移（View Shift）和平滑滚动体验。

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 1]
- [Task 5] depends on [Task 1]
- [Task 6] depends on [Task 5]
- [Task 7] depends on [Task 6]
- [Task 8] depends on [Task 1]
- [Task 9] depends on [Task 1]