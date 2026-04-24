# Tasks

- [x] Task 1: 全局代码检索任务与UI状态确认
  - [x] SubTask 1.1: 检索整个项目，确认无残留的 `(未实现)` 或 `TODO` 代码占位。
  - [x] SubTask 1.2: 确认三张截图中的所有功能入口已全部对应现有代码逻辑。

- [x] Task 2: 截图功能拆解任务 - 数据清理区二次确认
  - [x] SubTask 2.1: 为 `_clearStatsAndHistory` (清空所有统计与历史记录) 增加二次确认弹窗。
  - [x] SubTask 2.2: 为 `_clearMistakes` (仅清空错题本记录) 增加二次确认弹窗。
  - [x] SubTask 2.3: 为 `_LogsTab` 中的 `_clearLogs` (清空专属听写明细) 增加二次确认弹窗。

- [x] Task 3: 截图功能拆解任务 - 全局安全控制与密码管理
  - [x] SubTask 3.1: 为“点击切换加密/明文状态”增加二次确认弹窗，并完善状态切换逻辑。
  - [x] SubTask 3.2: 为 `_changePassword` (修改系统管理员主密码) 增加二次确认弹窗，并在确认后执行修改。

- [x] Task 4: 截图功能拆解任务 - 词库导入与危险操作区
  - [x] SubTask 4.1: 为 `_importJson` (智能校验并导入) 增加二次确认弹窗，提示会覆盖或合并现有数据。
  - [x] SubTask 4.2: 检查现有的 `_eraseAllData` (抹除所有账户及词库数据) 的二次确认弹窗是否符合截图要求并安全可用。

- [x] Task 5: 兼容性校验任务与 bug 自查
  - [x] SubTask 5.1: 测试现有的“提示次数限制”和“AI格式化提示词模板复制功能”，确保它们在本次修改中未受影响。
  - [x] SubTask 5.2: 全局监督Agent 进行最终代码可用性复盘与报告输出。

# Task Dependencies
- [Task 2], [Task 3], [Task 4] 依赖于 [Task 1] 的确认。可以由同一个 Sub-Agent 顺序执行。
- [Task 5] 依赖于前面所有任务的完成。
