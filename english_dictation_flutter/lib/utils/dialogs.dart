import 'package:flutter/material.dart';
import '../db/data_manager.dart';
import '../app_state.dart';
import '../utils/crypto_utils.dart';
import '../sync/cloud_sync_service.dart';
import '../utils/rate_limiter.dart';

class DialogUtils {
  static void requirePassword(BuildContext context, VoidCallback callback, {bool allowGuest = false}) {
    if (AppState.instance.authDialogOpen) return;
    AppState.instance.authDialogOpen = true;

    final guestPwd = DataManager.instance.globalSettings['guestHash']?.toString() ?? '';
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
            onSubmitted: (_) async {
              await _verifyPassword(context, controller.text, allowGuest, callback);
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
              onPressed: () async {
                await _verifyPassword(context, controller.text, allowGuest, callback);
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

  static Future<void> _verifyPassword(BuildContext context, String input, bool allowGuest, VoidCallback callback) async {
    if (await RateLimiter.isLockedOut()) {
      final remaining = await RateLimiter.getLockoutRemainingTime();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
        SnackBar(content: Text('尝试次数过多，请在 $remaining 后重试'), backgroundColor: Colors.red),
      );
      return;
    }

    final sysHash = (DataManager.instance.globalSettings['adminHash']?.toString() ?? '').trim();
    final sysSalt = DataManager.instance.globalSettings['adminSalt'] as List<dynamic>?;

    final guestHash = (DataManager.instance.globalSettings['guestHash']?.toString() ?? '').trim();
    final guestSalt = DataManager.instance.globalSettings['guestSalt'] as List<dynamic>?;

    bool isAdmin = false;
    bool isGuest = false;

    if (sysHash.isEmpty || sysSalt == null) {
       // fallback if no hash is set
       isAdmin = input == '123456';
    } else {
       isAdmin = await CryptoUtils.verifyPassword(input, sysHash, sysSalt.cast<int>());
    }

    if (allowGuest && guestHash.isNotEmpty && guestSalt != null) {
       isGuest = await CryptoUtils.verifyPassword(input, guestHash, guestSalt.cast<int>());
    }

    if (isAdmin || isGuest) {
      await RateLimiter.resetAttempts();
      AppState.instance.authDialogOpen = false;
      Navigator.pop(context);
      callback();
    } else {
      await RateLimiter.recordFailedAttempt();
      if (!context.mounted) return;
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

    showDialog(
      context: context,
      builder: (context) {
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
                autofocus: true,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(labelText: '输入姓名/昵称', labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
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
                  callback(text, 'user');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
              child: const Text('添加普通用户', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context);
                  callback(text, 'admin');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                foregroundColor: Colors.white,
              ),
              child: const Text('添加管理员'),
            ),
          ],
        );
      },
    );
  }
}
