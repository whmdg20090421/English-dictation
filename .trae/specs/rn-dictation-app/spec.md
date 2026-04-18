# React Native Dictation App Spec

## Why
当前的英语听写程序（`英语听写.py`）是一个基于 Python (nicegui) 构建、具有“代码即数据库”自修改特性的极客应用。为了提供更原生的移动端体验、更流畅的动画性能以及方便后续打包为安卓 App 分发，我们需要将其重构为基于 React Native 的原生应用，同时保留其深色毛玻璃美学、所有核心功能及数据结构。

## What Changes
- **BREAKING**: 将技术栈从 Python/nicegui 迁移到 React Native (Expo) + NativeWind (Tailwind CSS) + 类似 Shadcn 的组件库（如 gluestack-ui/react-native-reusables）。
- **BREAKING**: 移除脚本自修改（代码即数据库）的持久化方式，改用原生的本地安全存储方案（如 `AsyncStorage` 或 `MMKV`）。
- 完美复刻深色毛玻璃（Glassmorphism） UI 设计，包含渐变背景、半透明卡片和震动错误反馈动画。
- 重建多账户系统、全局设置及测试历史记录。
- 重建核心听写测试引擎（全卷/单题倒计时、动态掩码提示、跳题、重新作答等）。
- 重建智能错题本和错题重练功能。
- 集成原生 TTS (Text-to-Speech) 发音（如 `expo-speech`）。
- 使用原生加密存储重构安全机制（Admin 密码和 Guest 访客密码拦截）。

## Impact
- Affected specs: UI/UX (深色毛玻璃风格)、Data Storage (原生本地化存储)、State Management (React 状态管理)、Audio Playback (原生发音引擎)。
- Affected code: 原有的 `英语听写.py` 将被全新的 React Native 项目结构替代。

## ADDED Requirements
### Requirement: React Native Architecture
系统 SHALL 使用 React Native (基于 Expo 框架) 构建，使用 NativeWind 管理 Tailwind CSS 样式，并采用受 Shadcn 启发的组件化结构（如拆分 Card, Input, Button）。

### Requirement: Local Data Persistence
系统 SHALL 将词库、账户数据、历史记录和配置安全地存储在设备本地（AsyncStorage/MMKV），不再依赖于运行时修改 Python 脚本。

### Requirement: Native TTS
系统 SHALL 使用原生文本转语音 API (如 `expo-speech`) 在听写过程中朗读单词。

### Requirement: UI/UX Fidelity
系统 SHALL 通过 React Native 的动画库 (`Animated` 或 `react-native-reanimated`) 和 NativeWind 类名，精准复刻原版中的“深色毛玻璃”美学（深色渐变背景、半透明边框、交互反馈）。

## MODIFIED Requirements
无（这是一次完整的跨端平台迁移，现有功能要求均需全量迁移至新平台）。

## REMOVED Requirements
### Requirement: Self-modifying DB and Python Environment Setup
**Reason**: React Native 应用在编译后使用原生的存储机制，在 Android 运行时修改源代码既不可能也不安全。
**Migration**: 迁移到 AsyncStorage 或 MMKV 以实现极速本地持久化。