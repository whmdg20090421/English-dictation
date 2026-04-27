# Tasks
- [ ] Task 1: 修复数据详情页面的标题显示问题
  - [ ] SubTask 1.1: 在 `lib/screens/data_browser_screen.dart` 中，将两处的 `Text("[\${_currentAcc['name']}] 数据追踪"` 修改为正确的字符串插值语法 `Text("[${_currentAcc['name']}] 数据追踪"`。

- [ ] Task 2: 完善云端初始化配置页的密码输入与保存逻辑
  - [ ] SubTask 2.1: 在 `lib/screens/cloud_setup_screen.dart` 的 `_CloudSetupScreenState` 中，为 `adminPwd`、`guestPwd`、`encPwd` 分别增加三个对应的 `confirm` TextEditingController 控制器。
  - [ ] SubTask 2.2: 在 `_CloudSetupScreenState` 中添加管理每个密码框可见状态的布尔变量（例如 `_obscureAdmin`、`_obscureGuest`、`_obscureEnc` 及对应的确认框）。
  - [ ] SubTask 2.3: 在 UI 中添加对应的“确认密码”输入框，并在所有六个密码框的 `suffixIcon` 处添加点击切换可见状态的小眼睛图标（`Icons.visibility` 和 `Icons.visibility_off`）。
  - [ ] SubTask 2.4: 修改 `validator` 逻辑，确保主密码框与对应的确认密码框内容一致，如果不一致则提示“两次输入的密码不一致”。
  - [ ] SubTask 2.5: 修复 `_submit` 中的逻辑漏洞：确保在 `await DataManager.instance.loadData();` 之后再将 `encryptedAdminPwd` 和 `encryptedGuestPwd` 赋值给 `DataManager.instance.globalSettings`，随后再额外调用一次 `await DataManager.instance.saveData();`，防止新配置好的密码被本地旧数据覆盖。

- [ ] Task 3: 优化添加账户弹窗的 UI 交互
  - [ ] SubTask 3.1: 在 `lib/utils/dialogs.dart` 中，重构 `promptAccountDialog` 方法。
  - [ ] SubTask 3.2: 移除原来的角色下拉选择框（`DropdownButton`）。
  - [ ] SubTask 3.3: 在 `actions` 区域或表单底部，提供两个平行的按钮：“添加普通用户”和“添加管理员”，点击任意一个即触发 `callback(text, role)` 回调并传入对应的角色字符串（`user` 或 `admin`）。

# Task Dependencies
- Task 1、Task 2 和 Task 3 是彼此独立的，可以由 Sub-Agent 分别并行处理。
