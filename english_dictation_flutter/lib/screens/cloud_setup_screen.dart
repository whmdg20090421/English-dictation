import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../sync/cloud_sync_service.dart';
import '../db/data_manager.dart';
import 'home_screen.dart';
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
  final _adminPwdConfirmController = TextEditingController();
  final _guestPwdController = TextEditingController();
  final _guestPwdConfirmController = TextEditingController();
  final _encPwdController = TextEditingController();
  final _encPwdConfirmController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureAdmin = true;
  bool _obscureAdminConfirm = true;
  bool _obscureGuest = true;
  bool _obscureGuestConfirm = true;
  bool _obscureEnc = true;
  bool _obscureEncConfirm = true;

  Future<void> _submit() async {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });

        final encKey = _encPwdController.text;

        if (widget.isExistingCloud) {
          // Verify encryption password against cloud
          final configData = await CloudSyncService().downloadConfig(encKey);
          if (configData != null) {
            // Password is correct, download data
            final storage = const FlutterSecureStorage();
            await storage.write(key: 'encryption_password', value: encKey);
            
            // Also clean up old insecure storage if exists
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('encryption_password');
            
            CloudSyncService().setEncryptionPassword(encKey);
            
            // Load public and personal data
            await DataManager.instance.loadData();
            
            // IMPORTANT: Overwrite local globalSettings with the correct hashes and salts from configData
            DataManager.instance.globalSettings['adminHash'] = configData['adminHash'];
            DataManager.instance.globalSettings['adminSalt'] = configData['adminSalt'];
            DataManager.instance.globalSettings['guestHash'] = configData['guestHash'];
            DataManager.instance.globalSettings['guestSalt'] = configData['guestSalt'];
            DataManager.instance.globalSettings['mekSalt'] = configData['mekSalt'];
            await DataManager.instance.saveData();
            
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
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
              const SnackBar(content: Text('解密失败：数据已被其他密钥加密，输入的密钥不正确。若要重置，请删除云端配置文件。')),
            );
          }
          return;
        }

        final adminSaltBytes = CryptoUtils.generateSalt();
        final guestSaltBytes = CryptoUtils.generateSalt();
        final mekSaltBytes = CryptoUtils.generateSalt();

        final adminHash = await CryptoUtils.hashPassword(_adminPwdController.text, adminSaltBytes);
        final guestHash = await CryptoUtils.hashPassword(_guestPwdController.text, guestSaltBytes);

        // MEK derives from encKey, but we just store MEK_Salt so other devices can derive it.
        // We do not store any hash of encKey. If it decrypts the file, it's correct.

        final configData = {
          'adminHash': adminHash,
          'adminSalt': adminSaltBytes,
          'guestHash': guestHash,
          'guestSalt': guestSaltBytes,
          'mekSalt': mekSaltBytes,
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Initialize cloud with MEK_Salt explicitly passed so it can be used for the first encryption
        CloudSyncService().setEncryptionPasswordAndSalt(encKey, mekSaltBytes);

        final success = await CloudSyncService().uploadConfig(
          configData,
          encKey, // We still use encKey and mekSaltBytes to encrypt the config itself
        );

        if (success) {
          // Save encryption password securely
          final storage = const FlutterSecureStorage();
          await storage.write(key: 'encryption_password', value: encKey);
          
          // Clean up old insecure storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('encryption_password');

          // Initial upload of existing data to cloud
          await DataManager.instance.loadData(); // Load local data first, which will auto-initialize empty cloud
          
          // IMPORTANT: Also save admin/guest hashes and salts to globalSettings so app logic uses them
          DataManager.instance.globalSettings['adminHash'] = adminHash;
          DataManager.instance.globalSettings['adminSalt'] = adminSaltBytes;
          DataManager.instance.globalSettings['guestHash'] = guestHash;
          DataManager.instance.globalSettings['guestSalt'] = guestSaltBytes;
          DataManager.instance.globalSettings['mekSalt'] = mekSaltBytes;
          await DataManager.instance.saveData();

          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });

          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
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
      body: Center(
        child: SingleChildScrollView(
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
                  decoration: InputDecoration(
                    labelText: '系统管理员密码',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureAdmin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureAdmin = !_obscureAdmin),
                    ),
                  ),
                  obscureText: _obscureAdmin,
                  validator: (v) => v!.isEmpty ? '不可为空' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adminPwdConfirmController,
                  decoration: InputDecoration(
                    labelText: '确认管理员密码',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureAdminConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureAdminConfirm = !_obscureAdminConfirm),
                    ),
                  ),
                  obscureText: _obscureAdminConfirm,
                  validator: (v) {
                    if (v!.isEmpty) return '不可为空';
                    if (v != _adminPwdController.text) return '两次输入的密码不一致';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _guestPwdController,
                  decoration: InputDecoration(
                    labelText: '访客账户密码',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureGuest ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureGuest = !_obscureGuest),
                    ),
                  ),
                  obscureText: _obscureGuest,
                  validator: (v) => v!.isEmpty ? '不可为空' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _guestPwdConfirmController,
                  decoration: InputDecoration(
                    labelText: '确认访客密码',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureGuestConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureGuestConfirm = !_obscureGuestConfirm),
                    ),
                  ),
                  obscureText: _obscureGuestConfirm,
                  validator: (v) {
                    if (v!.isEmpty) return '不可为空';
                    if (v != _guestPwdController.text) return '两次输入的密码不一致';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _encPwdController,
                decoration: InputDecoration(
                  labelText: widget.isExistingCloud ? '数据加密密钥' : '数据加密密钥（用于云端加解密）',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.security),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureEnc ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureEnc = !_obscureEnc),
                  ),
                ),
                obscureText: _obscureEnc,
                validator: (v) => v!.isEmpty ? '不可为空' : null,
              ),
              const SizedBox(height: 16),
              if (!widget.isExistingCloud)
                TextFormField(
                  controller: _encPwdConfirmController,
                  decoration: InputDecoration(
                    labelText: '确认加密密钥',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.security_update_good),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureEncConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureEncConfirm = !_obscureEncConfirm),
                    ),
                  ),
                  obscureText: _obscureEncConfirm,
                  validator: (v) {
                    if (v!.isEmpty) return '不可为空';
                    if (v != _encPwdController.text) return '两次输入的密钥不一致';
                    return null;
                  },
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
      ),
    );
  }

  @override
  void dispose() {
    _adminPwdController.dispose();
    _adminPwdConfirmController.dispose();
    _guestPwdController.dispose();
    _guestPwdConfirmController.dispose();
    _encPwdController.dispose();
    _encPwdConfirmController.dispose();
    super.dispose();
  }
}
