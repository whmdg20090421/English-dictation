import 'package:flutter/material.dart';
import '../db/data_manager.dart';
import '../app_state.dart';
import '../utils/crypto_utils.dart';
import '../sync/cloud_sync_service.dart';

class DialogUtils {
  static String getAdminPwd() {
    final rawPwd = DataManager.instance.globalSettings['password'] ?? '';
    return rawPwd.toString().trim();
  }

  static void requirePassword(BuildContext context, VoidCallback callback, {bool allowGuest = false}) {
    if (AppState.instance.authDialogOpen) return;
    AppState.instance.authDialogOpen = true;

    final guestPwd = DataManager.instance.globalSettings['guestPassword']?.toString() ?? '';
    final title = allowGuest && guestPwd.isNotEmpty
        ? '安全验证 (支持访客)'
        : '管理员安全验证';

    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
          title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 24),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
            ),
            onSubmitted: (_) {
              _verifyPassword(context, controller.text, allowGuest, callback);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppState.instance.authDialogOpen = false;
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(backgroundColor: Colors.grey[500]),
              child: const Text('取消', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                _verifyPassword(context, controller.text, allowGuest, callback);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
              child: const Text('验证', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      AppState.instance.authDialogOpen = false;
    });
  }

  static void _verifyPassword(BuildContext context, String input, bool allowGuest, VoidCallback callback) {
    final sysPwdEncrypted = getAdminPwd();
    final guestPwdEncrypted = (DataManager.instance.globalSettings['guestPassword']?.toString() ?? '').trim();
    final encKey = CloudSyncService().encryptionPassword ?? '';

    // If sysPwdEncrypted is empty, we assume no password is set, fallback to '123456' matching
    // Wait, let's just encrypt the input and compare
    bool isAdmin = false;
    bool isGuest = false;

    if (sysPwdEncrypted.isEmpty) {
       isAdmin = input == '123456';
    } else {
       isAdmin = CryptoUtils.verifyPassword(input, sysPwdEncrypted, encKey);
    }

    if (allowGuest && guestPwdEncrypted.isNotEmpty) {
       isGuest = CryptoUtils.verifyPassword(input, guestPwdEncrypted, encKey);
    }

    if (isAdmin || isGuest) {
      AppState.instance.authDialogOpen = false;
      Navigator.pop(context);
      callback();
    } else {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
        const SnackBar(content: Text('验证失败：密码错误或权限不足'), backgroundColor: Colors.red),
      );
    }
  }

  static void multiActionDialog(BuildContext context, String title, String msg, List<Map<String, dynamic>> actions) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
          title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
          content: Text(msg, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16)),
          actions: actions.map((action) {
            final String label = action['label'];
            final Color color = action['color'];
            final VoidCallback? callback = action['callback'];

            return ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (callback != null) callback();
              },
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: Text(label, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );
      },
    );
  }

  static void promptDialog(BuildContext context, String title, String label, String defaultValue, Function(String) callback) {
    final TextEditingController controller = TextEditingController(text: defaultValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
          title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(backgroundColor: Colors.grey[500]),
              child: const Text('取消', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context);
                  callback(text);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
              child: const Text('确认', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  static void promptAccountDialog(BuildContext context, Function(String name, String role) callback) {
    final TextEditingController controller = TextEditingController();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              ),
              title: Text('新建账户', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(labelText: '输入姓名/昵称', labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('角色:', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: selectedRole,
                        dropdownColor: Theme.of(context).cardColor,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('普通用户')),
                          DropdownMenuItem(value: 'admin', child: Text('管理员')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedRole = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(backgroundColor: Colors.grey[500]),
                  child: const Text('取消', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(context);
                      callback(text, selectedRole);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                  child: const Text('确认', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
