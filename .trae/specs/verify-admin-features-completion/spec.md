# 严格校验与完善后台管理功能 (Verify Admin Features Completion) Spec

## Why
根据用户提供的最新三张系统后台截图，需要作为全栈开发工程师与全局监督Agent接手收尾工作。目前应用内大部分占位符已经替换，但需要进行一次全局深度检索，确保没有任何遗漏的 `未实现/未开发` 按钮，并对所有危险操作（数据删除、密码修改、加密切换等）追加二次确认弹窗，以符合安全规范和截图需求。

## What Changes
- 全局扫描代码，标记并确认所有 `未实现/未开发/待完善/TODO/空白事件/空函数` 均已闭环。
- **BREAKING**: 为以下高危操作追加 `AlertDialog` 二次确认弹窗，防止用户误触：
  - 清空所有统计与历史记录 (`_clearStatsAndHistory`)
  - 仅清空错题本记录 (`_clearMistakes`)
  - 专属听写明细 - 清空所有记录 (`_clearLogs`)
  - 修改系统管理员主密码 (`_changePassword`)
  - 切换加密/明文状态 (`_isEncrypted` toggle)
  - 智能校验并导入 JSON 词库 (`_importJson`)
- 校验已有的“抹除所有账户及词库数据”二次确认弹窗的可用性。
- 保留并校验现有的“提示次数限制”、“AI格式化提示词模板复制功能”。

## Impact
- Affected specs: 提升后台管理页面的交互安全性与操作防呆能力。
- Affected code: `lib/screens/admin_screen.dart`

## ADDED Requirements
### Requirement: 危险操作的二次确认防呆
系统必须在执行任何不可逆的数据清理、密码变更、安全状态变更前，弹出明确的二次确认提示框（`AlertDialog`）。

#### Scenario: Success case
- **WHEN** 用户点击“清空所有记录”
- **THEN** 弹出警告框“确定要清空吗？此操作不可恢复。”，点击“确定”后才执行数据抹除。

## MODIFIED Requirements
### Requirement: 后台管理页面完整性
确保截图中的所有按钮不仅有实际逻辑，还要有完整的异常捕获、权限判断（当前已是管理员界面）和交互提示（`SnackBar`）。
