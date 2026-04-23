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
    
    final exists = await CloudSyncService().checkConfigExists();
    
    if (!mounted) return;
    
    if (exists) {
      final prefs = await SharedPreferences.getInstance();
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
