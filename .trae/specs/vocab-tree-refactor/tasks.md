# Tasks

- [x] Task 1: 数据结构标识与通用递归工具
  - [x] SubTask 1.1: 在 `lib/db/data_manager.dart` 中新增辅助方法（例如判断是否为 File/Folder 的逻辑，以及递归提取所有单词的逻辑）。
  - [x] SubTask 1.2: 修改 `cleanEmptyNodes`，使其支持递归路径的节点清理。

- [x] Task 2: 重构后台管理界面的词库树 (`admin_screen.dart`)
  - [x] SubTask 2.1: 移除原有的两级 `ExpansionTile` 循环，编写一个 `_buildVocabTree(Map node, List<String> path)` 递归组件。
  - [x] SubTask 2.2: 在 UI 节点上增加对应的添加按钮（Folder 可以添加 Folder/File，File 可以添加 Word）。
  - [x] SubTask 2.3: 适配导入 JSON 时的合并逻辑，保留其原有的树状层级。

- [x] Task 3: 适配错题本与听写选择逻辑
  - [x] SubTask 3.1: 更新 `home_screen.dart` 中的 `_startMistakes`，使用递归函数收集全局错题。
  - [x] SubTask 3.2: 更新 `selection_screen.dart` 中的 `_loadVocab`，使用递归函数收集所有单词并转换为扁平列表以供听写。

- [x] Task 4: 适配数据追踪界面
  - [x] SubTask 4.1: 重写 `data_browser_screen.dart` 中的数据树生成逻辑，直接适配并渲染新的递归 `vocab`。

- [x] Task 5: 全局联调与错误排查
  - [x] SubTask 5.1: 运行应用，测试新建文件夹、子文件夹、文件、单词的全流程。
  - [x] SubTask 5.2: 确保“错题本重练”、“开始听写”不会因为层级变动而崩溃。
