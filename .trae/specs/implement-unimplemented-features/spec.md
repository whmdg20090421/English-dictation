# 检查与实现所有未实现功能 Spec

## Why
目前应用内（尤其是 `admin_screen.dart` 和 `video_dictation_screen.dart`）存在大量被标记为 `(未实现)` 的占位按钮和未对接的功能。为了提供完整的用户体验、可用的管理后台以及完整的视频听写闭环，我们需要将这些占位符替换为真实的业务逻辑，并撰写未实现功能的检查报告。

## 报告：未实现功能清单 (What Changes)
经过全代码库扫描，以下 11 项功能当前被标记为未实现或使用了 Mock 数据：
1. **词库编辑与保存** (`admin_screen.dart`): 添加或修改单词词性与释义后的保存功能未实现。
2. **词库智能导入** (`admin_screen.dart`): 通过 JSON 文本批量智能校验并导入至当前词库的功能未实现。
3. **下载完整备份** (`admin_screen.dart`): 将当前词库完整导出并下载的功能未实现。
4. **复制词库代码** (`admin_screen.dart`): 将当前词库 JSON 格式代码复制到剪贴板的功能未实现。
5. **清空所有统计与历史记录** (`admin_screen.dart`): 清空当前账号所有的流水和统计数据未实现。
6. **仅清空错题本记录** (`admin_screen.dart`): 清理当前账号的专属错题本记录未实现。
7. **密码可见性切换** (`admin_screen.dart`): 切换加密/明文状态以查看或修改密码的功能未实现。
8. **确认修改密码** (`admin_screen.dart`): 修改当前账号的安全密码未实现。
9. **抹除所有账户及词库数据** (`admin_screen.dart`): 初始化应用并清除所有数据的危险操作未实现。
10. **清空所有记录与真实历史渲染** (`admin_screen.dart`): 个人听写明细列表目前为 mock 数据，且对应的“清空所有记录”未实现。
11. **视频听写答案提交** (`video_dictation_screen.dart`): 视频听写界面中的 "Submit" 功能未接入实际的打分与下一题逻辑。

### Changes to be made
- [移除所有 `(未实现)` 字样，并补齐真实逻辑]
- [将管理后台 `admin_screen.dart` 中的相关功能对接至 `DataManager`]
- [将视频听写 `video_dictation_screen.dart` 的 Submit 按钮对接至 `DictationProvider` 和 `DataManager`]

## Impact
- Affected specs: 完善应用后台管理及视频听写模块。
- Affected code: 
  - `lib/screens/admin_screen.dart`
  - `lib/screens/video_dictation_screen.dart`

## ADDED Requirements
### Requirement: 词库导入与导出
系统必须提供完整的 JSON 词库解析导入能力，以及全量词库的导出/复制能力，并与底层 SQLite 数据库同步。

### Requirement: 数据清理与账号安全
系统必须提供对历史记录、错题本以及全局数据的精准清空能力。同时必须支持当前登录用户的密码修改。

### Requirement: 视频听写闭环
视频听写界面必须能通过输入框提交答案，流转到下一题，并在测试结束后进入成绩单结算页面。
