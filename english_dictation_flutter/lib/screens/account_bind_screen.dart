import 'package:flutter/material.dart';
import '../sync/cloud_sync_service.dart';
import '../db/data_manager.dart';
import 'home_screen.dart';
import '../utils/dialogs.dart';
import '../app_state.dart';

class AccountBindScreen extends StatefulWidget {
  final String encKey;
  const AccountBindScreen({super.key, required this.encKey});

  @override
  State<AccountBindScreen> createState() => _AccountBindScreenState();
}

class _AccountBindScreenState extends State<AccountBindScreen> {
  bool _isLoading = true;
  List<String> _cloudAccounts = [];
  String? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadCloudAccounts();
  }

  Future<void> _loadCloudAccounts() async {
    final accounts = await CloudSyncService().listCloudAccounts();
    if (mounted) {
      setState(() {
        _cloudAccounts = accounts;
        if (accounts.isNotEmpty) {
          _selectedAccount = accounts.first;
        }
        _isLoading = false;
      });
    }
  }

  void _bindAccount() {
    if (_selectedAccount == null) return;
    DialogUtils.requirePassword(context, () async {
      setState(() {
        _isLoading = true;
      });
      final personalData = await CloudSyncService().downloadPersonalData(_selectedAccount!);
      if (personalData != null && personalData['account'] != null) {
        final newId = DateTime.now().millisecondsSinceEpoch.toString();
        DataManager.instance.accounts[newId] = personalData['account'];
        
        // Remove default account if it is untouched
        if (DataManager.instance.accounts.containsKey('default') && DataManager.instance.accounts.length > 1) {
          final defAcc = DataManager.instance.accounts['default'];
          if ((defAcc['history'] as List).isEmpty && (defAcc['mistakes'] as List).isEmpty) {
            DataManager.instance.accounts.remove('default');
          }
        }
        
        AppState.instance.currentAccountId = newId;
        await DataManager.instance.saveData();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('绑定失败，无法获取账号数据')));
        }
      }
    });
  }

  void _createNewAccount() {
    DialogUtils.requirePassword(context, () {
      DialogUtils.promptAccountDialog(context, (name, role) async {
        if (name.isNotEmpty) {
          setState(() {
            _isLoading = true;
          });
          final newId = DateTime.now().millisecondsSinceEpoch.toString();
          final baseSettings = DataManager.instance.getAcc("default")["settings"] ?? <String, dynamic>{};
          DataManager.instance.accounts[newId] = <String, dynamic>{
            "name": name,
            "role": role,
            "history": <dynamic>[],
            "stats": <String, dynamic>{},
            "settings": Map<String, dynamic>.from(baseSettings)
          };
          
          // Remove default account if untouched
          if (DataManager.instance.accounts.containsKey('default') && DataManager.instance.accounts.length > 1) {
            final defAcc = DataManager.instance.accounts['default'];
            if ((defAcc['history'] as List).isEmpty && (defAcc['mistakes'] as List).isEmpty) {
              DataManager.instance.accounts.remove('default');
            }
          }

          AppState.instance.currentAccountId = newId;
          await DataManager.instance.saveData();

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备初始化：绑定用户'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_alt, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    '已成功连接云端！\n请选择绑定一个云端已有的用户，\n或在当前设备创建新用户。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  if (_cloudAccounts.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedAccount,
                      decoration: const InputDecoration(
                        labelText: '选择已有用户',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _cloudAccounts.map((acc) {
                        return DropdownMenuItem(value: acc, child: Text(acc));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAccount = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _bindAccount,
                        child: const Text('绑定选中用户'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('或者')),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _createNewAccount,
                      child: const Text('创建新用户'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
