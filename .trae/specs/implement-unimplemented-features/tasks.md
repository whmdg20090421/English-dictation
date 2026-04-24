# Tasks

- [x] Task 1: 完善后台管理 - 词库编辑与导入导出
  - [x] SubTask 1.1: 在 `admin_screen.dart` 中实现词库单词的保存编辑逻辑，并同步至 `DataManager`。
  - [x] SubTask 1.2: 实现智能校验并导入 JSON 文本到当前词库。
  - [x] SubTask 1.3: 实现全量词库备份下载及代码复制功能。

- [x] Task 2: 完善后台管理 - 数据清理与账号安全
  - [x] SubTask 2.1: 在 `admin_screen.dart` 中实现清空所有统计记录、仅清空错题本的逻辑。
  - [x] SubTask 2.2: 实现密码可见性切换与密码修改保存逻辑。
  - [x] SubTask 2.3: 实现“抹除所有账户及词库数据”危险操作（需二次确认弹窗）。

- [x] Task 3: 完善后台管理 - 真实历史记录渲染
  - [x] SubTask 3.1: 将 `_LogsTab` 中的 mock 列表替换为当前账户的真实 `history` 数据渲染。
  - [x] SubTask 3.2: 实现“清空所有记录”逻辑，并即时更新 UI。

- [x] Task 4: 完善视频听写 - 流程闭环
  - [x] SubTask 4.1: 在 `video_dictation_screen.dart` 中移除 `Submit (未实现)` 提示，接入真实的答案提交逻辑。
  - [x] SubTask 4.2: 通过 `DictationProvider` 实现视频听写中答案提交流程，并联动后续的判题流转到成绩界面。

# Task Dependencies
- [Task 1]、[Task 2]、[Task 3] 可由负责后台管理的 Agent A 并行处理。
- [Task 4] 可由负责听写测试引擎的 Agent B 并行处理。
