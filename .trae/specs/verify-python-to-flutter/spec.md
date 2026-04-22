# Python to Flutter Refactoring Verification Spec

## Why
用户要求对原有的 `英语听写.py` 脚本进行严格的、多 Agent 并行的核对工作。其目的是为了将长达 1500 多行的 Python 业务逻辑与新开发的 Flutter 应用程序代码（`english_dictation_flutter`）进行逐行、逐功能的比对，确保没有任何微小功能或判断标准被遗漏。一旦确认全部迁移并实现，则由总 Agent 汇报并最终删除原有的 Python 文件。

## What Changes
- 使用 Agent 分析并将 `英语听写.py` 拆分为十几个小模块。
- 启动多个子 Agent，各自负责一个或多个模块，识别该模块在 Flutter 中是否已实现。
- 若模块已实现，则标记为已实现；若未实现，则由子 Agent 直接在 Flutter 项目中进行补充实现。
- 最后由一个总 Agent（Master Agent）对所有的核对结果进行复查和汇总汇报。
- 在汇报无误后，删除本地的 `英语听写.py` 文件。

## Impact
- Affected specs: 验证并完善 Flutter 应用程序的各项功能对齐。
- Affected code: `english_dictation_flutter/` 目录下的相关 Dart 文件，以及根目录的 `英语听写.py`（将被删除）。

## ADDED Requirements
### Requirement: 多 Agent 模块化校验
系统必须支持拆分原有代码为细粒度模块，并通过并发或序列化的子 Agent 独立验证其在 Flutter 中的存在性。

#### Scenario: 发现未实现的功能
- **WHEN** 子 Agent 在检查其负责的模块时发现 Flutter 端缺失了某项判断标准或逻辑
- **THEN** 子 Agent 必须修改 Flutter 代码以补齐该功能，并确保 UI 文字与原文件一致。

## REMOVED Requirements
### Requirement: 移除原有 Python 脚本
**Reason**: Python 脚本的所有功能已被完全重构为 Flutter 应用，为了保持代码库的整洁，需将其移除。
**Migration**: 在所有子 Agent 校验完成并由总 Agent 汇报后，删除 `英语听写.py`。
