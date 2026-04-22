# Tasks

- [ ] Task 1: 第一阶段 - 搭建项目框架与基础设施
  - [ ] SubTask 1.1: 初始化 React Native + Expo 项目，安装并配置 Expo Router 和 NativeWind。
  - [ ] SubTask 1.2: 配置 `expo-sqlite`，设计并创建本地数据库模型（用户表、练习记录表、题库表、同步队列表）。
  - [ ] SubTask 1.3: 实现离线 JWT 登录注册逻辑及三级角色（超管、管理员、普通用户）的权限路由拦截。
  - [ ] SubTask 1.4: 确立全局 UI 主题（深蓝色调、深色磨砂背景、大圆角组件），实现首页和设置页骨架。

- [ ] Task 2: 第二阶段 - 核心听写练习功能
  - [ ] SubTask 2.1: 引入 `expo-av` 实现视频播放与控制。
  - [ ] SubTask 2.2: 实现练习界面的半透明玻璃态字幕遮罩和底部答题输入框。
  - [ ] SubTask 2.3: 完成答题提交后的比对与结果展示界面，将进度与答案写入本地数据库。
  - [ ] SubTask 2.4: 实现历史记录页，展示练习情况和正确率走势图表。

- [ ] Task 3: 第三阶段 - 管理员内嵌服务器与局域网通信
  - [ ] SubTask 3.1: 在应用中集成 Node.js + Express 内嵌服务器（通过 Expo 后台机制运行 HTTP 和 WebSocket 服务）。
  - [ ] SubTask 3.2: 引入 `react-native-zeroconf` 实现局域网服务广播与客户端自动发现。
  - [ ] SubTask 3.3: 搭建 WebSocket 服务，实现设备在线状态的实时监控。
  - [ ] SubTask 3.4: 开发离线同步队列机制，实现客户端批量上传数据及管理员确认回执逻辑。

- [ ] Task 4: 第四阶段 - 管理员后台界面与 UI 精修
  - [ ] SubTask 4.1: 开发管理员题库管理模块（视频上传、字幕配置）。
  - [ ] SubTask 4.2: 开发用户管理模块（账号创建、学习进度查看）。
  - [ ] SubTask 4.3: 开发同步中心模块（实时显示在线设备、待同步记录数，支持手动推送内容）。
  - [ ] SubTask 4.4: 全局 UI 细节打磨（发光边框、柔和渐变色、页面平滑切换动效）。

- [ ] Task 5: 第五阶段 - 整合 Python 评分算法与业务逻辑
  - [ ] SubTask 5.1: 寻找并读取工作区中用户提供的 Python 评分程序文件。
  - [ ] SubTask 5.2: 将 Python 的核心评分算法（如文本比对、容错处理等）转译为 TypeScript/JavaScript 并在应用内集成。
  - [ ] SubTask 5.3: 测试算法在答题提交环节的准确性，确保与原 Python 业务逻辑完全一致。

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 1]
- [Task 4] depends on [Task 3]
- [Task 5] depends on [Task 2]
