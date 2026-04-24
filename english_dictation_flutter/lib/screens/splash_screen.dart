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
    final pwd = prefs.getString('encryption_password');
    if (pwd != null && pwd.isNotEmpty) {
      CloudSyncService().setEncryptionPassword(pwd);
    }
    
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C313C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_sync, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text('正在初始化应用...', style: TextStyle(fontSize: 18, color: Colors.white)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
