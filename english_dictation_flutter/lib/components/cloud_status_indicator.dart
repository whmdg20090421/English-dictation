import 'package:flutter/material.dart';
import '../sync/cloud_sync_service.dart';
import '../db/data_manager.dart';
import '../app_state.dart';
import '../screens/cloud_file_manager_screen.dart';

class CloudStatusIndicator extends StatefulWidget {
  const CloudStatusIndicator({super.key});

  @override
  State<CloudStatusIndicator> createState() => _CloudStatusIndicatorState();
}

class _CloudStatusIndicatorState extends State<CloudStatusIndicator> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    CloudSyncService().connectionStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isConnected = status;
        });
      }
    });
  }

  Future<void> _checkConnection() async {
    final connected = await CloudSyncService().ping();
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }
  }

  void _showMenu(BuildContext context) {
    final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
    final isAdmin = currentAcc['role'] == 'admin';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload, color: Colors.green),
                title: const Text('上传资料', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    const SnackBar(content: Text('正在上传资料...'), backgroundColor: Colors.blue),
                  );
                  await DataManager.instance.saveData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    const SnackBar(content: Text('上传完成'), backgroundColor: Colors.green),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download, color: Colors.blue),
                title: const Text('下载资料', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    const SnackBar(content: Text('正在下载资料...'), backgroundColor: Colors.blue),
                  );
                  await DataManager.instance.loadData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    const SnackBar(content: Text('下载完成'), backgroundColor: Colors.green),
                  );
                },
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: const Text('编辑云端资料', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CloudFileManagerScreen()),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isConnected ? '云端已连接' : '云端异常',
              style: TextStyle(
                color: _isConnected ? Colors.green[300] : Colors.red[300],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
