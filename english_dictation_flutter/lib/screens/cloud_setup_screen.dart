import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sync/cloud_sync_service.dart';
import '../db/data_manager.dart';
import 'home_screen.dart';

import '../components/cloud_status_indicator.dart';

class CloudSetupScreen extends StatefulWidget {
  const CloudSetupScreen({super.key});

  @override
  State<CloudSetupScreen> createState() => _CloudSetupScreenState();
}

class _CloudSetupScreenState extends State<CloudSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminPwdController = TextEditingController();
  final _guestPwdController = TextEditingController();
  final _encPwdController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final configData = {
        'adminPassword': _adminPwdController.text,
        'guestPassword': _guestPwdController.text,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final success = await CloudSyncService().uploadConfig(
        configData,
        _encPwdController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Save encryption password locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('encryption_password', _encPwdController.text);
        CloudSyncService().setEncryptionPassword(_encPwdController.text);

        // Also save admin/guest passwords to globalSettings so app logic uses them
        DataManager.instance.globalSettings['password'] = _adminPwdController.text;
        DataManager.instance.globalSettings['guestPassword'] = _guestPwdController.text;
        
        // Initial upload of existing data to cloud
        await DataManager.instance.loadData(); // Load local data first, which will auto-initialize empty cloud

        if (!mounted) return;
        
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(content: Text('配置上传失败，请检查网络或WebDAV设置')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云端初始化配置'),
        leading: const CloudStatusIndicator(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                '首次运行，请设置应用密码并同步至云端',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _adminPwdController,
                decoration: const InputDecoration(
                  labelText: '管理员密码 (Admin Password)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) => value!.isEmpty ? '请输入管理员密码' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guestPwdController,
                decoration: const InputDecoration(
                  labelText: '访客密码 (Guest Password)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) => value!.isEmpty ? '请输入访客密码' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _encPwdController,
                decoration: const InputDecoration(
                  labelText: '数据加密密码 (Encryption Password)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) => value!.isEmpty ? '请输入加密密码' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('保存配置到云端', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adminPwdController.dispose();
    _guestPwdController.dispose();
    _encPwdController.dispose();
    super.dispose();
  }
}
