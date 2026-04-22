# 英语听写 App Flutter 重构 Spec

## Why
当前项目基于 React Native (Expo) 构建。为了追求更高的跨平台性能、更一致的渲染体验以及更丰富的动画和 UI 定制能力，用户要求将现有的所有代码、业务逻辑与深色玻璃态（Glassmorphism）UI 全面重构为 Flutter 应用。

## What Changes
- **BREAKING**: 放弃原有的 React Native (Expo) 框架，重新初始化 Flutter 项目。
- 迁移本地数据库：从 `expo-sqlite` 迁移至 Flutter 的 `sqflite`，并复刻现有的数据结构（包含词库拆分与多账户统计逻辑）。
- UI/UX 重构：使用 Flutter 重写深蓝色沉浸式背景、毛玻璃卡片（`BackdropFilter`），以及错误抖动、正确闪烁等原生动画。
- 业务功能复刻：完整实现多账户系统、主页看板数据、专属数据详情页（词库树状图与统计流水）、管理后台（词库管理、导入导出、系统设置）。
- 测试引擎复刻：实现单题/全局双轨倒计时、基于 LCP 的智能提示、以及 TTS 语音播放（使用 `flutter_tts`）。
- 视频听写复刻：使用 `video_player` 实现视频播放，并叠加毛玻璃字幕遮罩层进行听写。
- 局域网同步复刻：使用 Dart 的 WebSocket 和局域网服务发现（如 `nsd` 或 `multicast_dns`），配合本地离线队列实现断网环境下的练习数据同步。

## Impact
- Affected specs: 框架底座、数据层架构、UI 渲染层、听写引擎、局域网同步网络层。
- Affected code: 全新构建的 Flutter Dart 代码，将完全替换原有的 React Native 代码。

## ADDED Requirements
### Requirement: Flutter 基础设施与数据库
系统 SHALL 使用 Flutter 构建，并使用 `sqflite` 提供离线数据库支持。

### Requirement: 核心业务逻辑与 UI 还原
系统 SHALL 完全还原现有的深蓝色玻璃态 UI，并保持原有的听写引擎和多账户统计逻辑。

## MODIFIED Requirements
### Requirement: 局域网同步网络层
原 Node.js Express 服务将被 Dart 原生 HTTP/WebSocket Server 替代，用于局域网内的设备发现与数据同步。