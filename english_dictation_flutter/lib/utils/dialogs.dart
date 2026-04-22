import 'package:flutter/material.dart';
import '../db/data_manager.dart';
import '../app_state.dart';
import '../theme.dart';

class DialogUtils {
  static String getAdminPwd() {
    final rawPwd = DataManager.instance.globalSettings['password'] ?? '123456';
    return rawPwd.toString().trim();
  }

  static void requirePassword(BuildContext context, VoidCallback callback, {bool allowGuest = false}) {
    if (AppState.instance.authDialogOpen) return;
    AppState.instance.authDialogOpen = true;

    final title = allowGuest && AppState.instance.guestPassword.isNotEmpty
        ? '安全验证 (支持访客)'
        : '管理员安全验证';

    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlue.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: AppTheme.glassBorder, width: 1),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 24),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54, width: 2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentGreen, width: 2)),
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
    final sysPwd = getAdminPwd();
    final guestPwd = AppState.instance.guestPassword.trim();

    final isAdmin = input == sysPwd;
    final isGuest = allowGuest && guestPwd.isNotEmpty && input == guestPwd;

    if (isAdmin || isGuest) {
      AppState.instance.authDialogOpen = false;
      Navigator.pop(context);
      callback();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证失败：密码错误或权限不足'), backgroundColor: Colors.red),
      );
      // Wait for user to re-enter
    }
  }

  static void multiActionDialog(BuildContext context, String title, String msg, List<Map<String, dynamic>> actions) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlue.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: AppTheme.glassBorder, width: 1),
          ),
          title: Text(title, style: const TextStyle(color: Colors.amberAccent, fontSize: 20, fontWeight: FontWeight.bold)),
          content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16)),
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
          backgroundColor: AppTheme.secondaryBlue.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: AppTheme.glassBorder, width: 1),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54)),
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
}
