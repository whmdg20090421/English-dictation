import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sync/cloud_sync_service.dart';
import '../db/data_manager.dart';
import 'home_screen.dart';
import 'account_bind_screen.dart';
import '../utils/crypto_utils.dart';

import '../components/cloud_status_indicator.dart';

class CloudSetupScreen extends StatefulWidget {
  final bool isExistingCloud;
  const CloudSetupScreen({super.key, this.isExistingCloud = false});

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

        final encKey = _encPwdController.text;

        if (widget.isExistingCloud) {
          // Verify encryption password against cloud
          final configData = await CloudSyncService().downloadConfig(encKey);
          
          // Check for required configuration keys to ensure correct decryption
          final bool isValidDecryption = configData != null && 
              configData.containsKey('version') && 
              configData.containsKey('password') && 
              configData.containsKey('guestPassword');

          if (isValidDecryption) {
            // Password is correct, download data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('encryption_password', encKey);
            CloudSyncService().setEncryptionPassword(encKey);
            await DataManager.instance.loadData();
            
            final isFirstInstall = DataManager.instance.accounts.length == 1 && DataManager.instance.accounts.containsKey('default');
            
            if (!mounted) return;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              if (isFirstInstall) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => AccountBindScreen(encKey: encKey)),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            }
          } else {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
              const SnackBar(content: Text('解密失败：数据已被其他密钥加密，输入的密钥不正确。若要重置，请删除云端配置文件。')),
            );
          }
          return;
        }

        final encryptedAdminPwd = CryptoUtils.encryptPassword(_adminPwdController.text, encKey);
        final encryptedGuestPwd = CryptoUtils.encryptPassword(_guestPwdController.text, encKey);

        final configData = {
          'adminPassword': encryptedAdminPwd,
          'guestPassword': encryptedGuestPwd,
          'createdAt': DateTime.now().toIso8601String(),
        };

        final success = await CloudSyncService().uploadConfig(
          configData,
          encKey,
        );

        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Save encryption password locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('encryption_password', encKey);
          CloudSyncService().setEncryptionPassword(encKey);

          // Also save admin/guest passwords to globalSettings so app logic uses them
          DataManager.instance.globalSettings['password'] = encryptedAdminPwd;
          DataManager.instance.globalSettings['guestPassword'] = encryptedGuestPwd;

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
        title: Text(widget.isExistingCloud ? '验证云端密钥' : '云端初始化配置'),
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
              Text(
                widget.isExistingCloud ? '检测到云端已有数据，请输入加密密钥以解密' : '首次运行，请设置应用密码并同步至云端',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!widget.isExistingCloud) ...[
                TextFormField(
                  controller: _adminPwdController,
                  decoration: const InputDecoration(
                    labelText: '系统管理员密码',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? '不可为空' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _guestPwdController,
                  decoration: const InputDecoration(
                    labelText: '访客账户密码',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? '不可为空' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _encPwdController,
                decoration: InputDecoration(
                  labelText: widget.isExistingCloud ? '数据加密密钥' : '数据加密密钥（用于云端加解密）',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.security),
                ),
                obscureText: true,
                validator: (v) => v!.isEmpty ? '不可为空' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.isExistingCloud ? '解密并同步' : '完成并初始化云端'),
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
