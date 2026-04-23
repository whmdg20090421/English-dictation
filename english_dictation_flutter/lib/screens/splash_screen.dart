import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sync/cloud_sync_service.dart';
import 'cloud_setup_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkConfig();
  }

  Future<void> _checkConfig() async {
    // Optional: wait a moment for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prefs = await SharedPreferences.getInstance();
    final hasConnectedBefore = prefs.getBool('has_connected_before') ?? false;

    bool isConnected = false;
    try {
      isConnected = await CloudSyncService().ping();
    } catch (e) {
      isConnected = false;
    }
    
    if (!mounted) return;

    if (isConnected) {
      await prefs.setBool('has_connected_before', true);
      final exists = await CloudSyncService().checkConfigExists();
      if (!mounted) return;
      
      if (exists) {
        final pwd = prefs.getString('encryption_password');
        if (pwd != null && pwd.isNotEmpty) {
          CloudSyncService().setEncryptionPassword(pwd);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          // Prompt for password
          _promptForPassword();
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CloudSetupScreen()),
        );
      }
    } else {
      if (hasConnectedBefore) {
        final pwd = prefs.getString('encryption_password');
        if (pwd != null && pwd.isNotEmpty) {
          CloudSyncService().setEncryptionPassword(pwd);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          _promptForPassword();
        }
      } else {
        _showConnectionError();
      }
    }
  }

  void _showConnectionError() {
    final logs = CloudSyncService().errorLogs;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('网盘连接失败'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('首次运行需要连接网盘进行初始化，但当前连接失败。\n请检查网络连接或WebDAV配置。'),
              const SizedBox(height: 10),
              if (logs.isNotEmpty)
                Text(
                  '最新报错: ${logs.first}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkConfig(); // Retry
              },
              child: const Text('重试'),
            ),
          ],
        );
      }
    );
  }

  void _promptForPassword() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('请输入云端加密密码'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: '加密密码',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final pwd = controller.text;
                if (pwd.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('encryption_password', pwd);
                  CloudSyncService().setEncryptionPassword(pwd);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_sync, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text('正在检查云端配置...', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
