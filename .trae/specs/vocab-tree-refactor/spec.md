# 词库多级文件夹结构重构 (Vocab Tree Refactor) Spec

## Why
当前词库只支持固定的两级结构（“书本”->“单元”），无法满足用户进一步细分归类的需求。用户期望支持“文件夹内创建子文件夹”的多级结构，在最底层创建“文件（单元）”，并在文件中存储具体的单词。同时要求继续以 JSON 形式保存在本地，并支持手动云端同步。

## What Changes
- **BREAKING**: 重构 `DataManager.instance.vocab` 的数据结构，从固定的两级 Map (`vocab[book][unit]`) 改为支持任意深度的递归 Map。
  - **文件夹 (Folder)**：其子节点可以是其他文件夹或文件。空文件夹内部会保存一个隐藏标识 `"_type": "folder"`。
  - **文件 (File/Unit)**：其子节点只能是“单词”(Word)。空文件内部会保存一个隐藏标识 `"_type": "file"`。
  - **单词 (Word)**：一个包含 `"单词"` 键的 Map。
- 修改 `admin_screen.dart` 中的 `_WordsTab`，支持递归渲染词库树（`ExpansionTile` 嵌套）。
  - 在每个文件夹层级，提供“新建子文件夹”和“新建单元文件”的功能。
  - 在每个文件层级，提供“新增单词”功能。
- 修改 `data_manager.dart` 的 `cleanEmptyNodes` 为递归清理空节点。
- 修改 `home_screen.dart` (`_startMistakes`)、`selection_screen.dart` (`_loadVocab`)、`data_browser_screen.dart` (`_buildTree`)，以支持对任意深度的词库树进行递归遍历，提取出底层的单词数据。

## Impact
- Affected specs: 词库管理、错题本抽取、听写范围选择、数据追踪。
- Affected code:
  - `lib/db/data_manager.dart`
  - `lib/screens/admin_screen.dart`
  - `lib/screens/home_screen.dart`
  - `lib/screens/dictation/selection_screen.dart`
  - `lib/screens/data_browser_screen.dart`

## ADDED Requirements
### Requirement: 多级文件夹与单元文件
系统必须支持在词库的任意层级创建“子文件夹”或“单元文件”。只有在“单元文件”下才可以添加单词，且支持将该树状结构无缝导出/导入为 JSON。

#### Scenario: Success case
- **WHEN** 用户在“小学”文件夹下点击“新建子文件夹”
- **THEN** 系统在“小学”内创建新的嵌套 Map。
- **WHEN** 用户在“一年级”文件夹下点击“新建单元文件”
- **THEN** 系统创建具有 `_type: 'file'` 的 Map，并允许在其中添加单词。

## MODIFIED Requirements
### Requirement: 词库遍历与听写抽取
系统的错题本、全局听写抽词、数据追踪必须通过递归遍历所有叶子节点（单词），而不能假设词库只有两层。
