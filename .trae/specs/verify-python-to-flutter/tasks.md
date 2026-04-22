# Tasks

- [x] Task 1: 拆分模块并规划 Agent 任务
  - 使用 Agent 分析 `英语听写.py` 源码（约 2450 行），按照核心类、状态管理、网络与各 UI 页面将其划分为十几个逻辑模块。
- [x] Task 2: DataManager & AppState 验证
  - 使用子 Agent 负责核对原 `DataManager` 和 `AppState` (行150-436)，在 Flutter 的 SQLite 和状态管理中是否已完全实现。若未实现，将其实现并标记。
- [x] Task 3: 路由与基础组件、鉴权模块验证
  - 使用子 Agent 负责核对原 `change_view`, `require_password`, `multi_action_dialog` 等 (行442-576)，在 Flutter 中是否具有对应的导航和弹窗鉴权逻辑。若未实现，将其实现并标记。
- [x] Task 4: 首页与账号切换模块验证
  - 使用子 Agent 负责核对原 `render_home`, `show_account_switch` (行508-680)，在 Flutter 中是否已有完整的 UI 文字和用户/管理员入口逻辑。若未实现，将其实现并标记。
- [x] Task 5: 历史数据浏览器模块验证
  - 使用子 Agent 负责核对原 `render_data_browser` (行681-829)，在 Flutter 中是否实现了对应的记录展示和图表（若有）等。若未实现，将其实现并标记。
- [x] Task 6: 管理员 - 题库管理模块验证
  - 使用子 Agent 负责核对原 `render_admin`, `admin_tab_words` (行830-1050)，在 Flutter 管理界面中是否具备完整的词库/视频配置与操作。若未实现，将其实现并标记。
- [x] Task 7: 管理员 - 导入导出与日志模块验证
  - 使用子 Agent 负责核对原 `admin_tab_import_export`, `admin_tab_logs` (行1051-1416, 1510-1542)，在 Flutter 中的批量导入、导出逻辑和日志展示是否对齐。若未实现，将其实现并标记。
- [x] Task 8: 管理员 - 设置与网络同步模块验证
  - 使用子 Agent 负责核对原 `admin_tab_settings`及服务端逻辑 `start_server`, `index_page` (行1417-1509, 2384-2450)，在 Flutter 中的离线队列、局域网 WebSocket 通信是否实现。若未实现，将其实现并标记。
- [x] Task 9: 课程选择与模式选择模块验证
  - 使用子 Agent 负责核对原 `render_select_content`, `render_select_mode` (行1543-1745)，在 Flutter 界面中的分类选择、学习模式逻辑是否完整。若未实现，将其实现并标记。
- [x] Task 10: 核心听写测试模块（视频与输入）验证
  - 使用子 Agent 负责核对原 `render_testing` 前半部分 (行1746-2000)，在 Flutter 中的视频播放、模糊遮罩、答题输入框及 LCP 智能提示逻辑是否对齐。若未实现，将其实现并标记。
- [x] Task 11: 核心听写测试模块（评分与快捷键）验证
  - 使用子 Agent 负责核对原 `render_testing` 后半部分及 TTS (行2000-2282)，在 Flutter 中的快捷键事件、TTS朗读、以及答案判定是否严格对齐。若未实现，将其实现并标记。
- [x] Task 12: 评分报告与手动批改模块验证
  - 使用子 Agent 负责核对原 `render_interim_report`, `render_manual_grade`, `render_results` (行2283-2383)，在 Flutter 中的阶段性报告、手工修改正确率和最终结算页面逻辑是否一致。若未实现，将其实现并标记。
- [x] Task 13: 总 Agent 检查汇报与收尾
  - 启动一个 Master Agent 汇总所有子 Agent 的执行结果，生成最终对比报告并汇报给用户，最后删除原本的 `英语听写.py` 文件。

# Task Dependencies
- Task 2-12 depends on Task 1
- Task 13 depends on Tasks 2-12
