import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../sync/cloud_sync_service.dart';
import '../db/data_manager.dart';
import '../app_state.dart';
import '../screens/cloud_file_manager_screen.dart';
import '../screens/cloud_setup_screen.dart';

enum CloudState {
  connected,
  disconnected,
  unconfigured
}

class CloudStatusIndicator extends StatefulWidget {
  const CloudStatusIndicator({super.key});

  @override
  State<CloudStatusIndicator> createState() => _CloudStatusIndicatorState();
}

class _CloudStatusIndicatorState extends State<CloudStatusIndicator> {
  CloudState _state = CloudState.disconnected;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    CloudSyncService().connectionStatusStream.listen((status) {
      if (mounted) {
        _checkConnection();
      }
    });
  }

  Future<void> _checkConnection() async {
    final storage = const FlutterSecureStorage();
    final pwd = await storage.read(key: 'encryption_password');
    
    if (pwd == null || pwd.isEmpty) {
      if (mounted) {
        setState(() {
          _state = CloudState.unconfigured;
        });
      }
      return;
    }

    final connected = await CloudSyncService().ping();
    if (mounted) {
      setState(() {
        _state = connected ? CloudState.connected : CloudState.disconnected;
      });
    }
  }

  void _showMenu(BuildContext context) {
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
              if (_state == CloudState.unconfigured)
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.red),
                  title: const Text('去配置云端密码', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CloudSetupScreen()),
                    ).then((_) => _checkConnection());
                  },
                ),
              if (_state != CloudState.unconfigured) ...[
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
                if (DataManager.instance.accounts.isNotEmpty && 
                    DataManager.instance.getAcc(AppState.instance.currentAccountId)['role'] == 'admin')
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
              if (_state == CloudState.disconnected)
                ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.yellow),
                  title: const Text('查看报错日志', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showErrorLogs(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorLogs(BuildContext context) {
    final logs = CloudSyncService().errorLogs;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('网盘连接报错信息'),
          content: SizedBox(
            width: double.maxFinite,
            child: logs.isEmpty
                ? const Text('暂无详细报错信息')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final logStr = logs[index];
                      // Assume log format is [time] message
                      final splitIndex = logStr.indexOf('] ');
                      final timeStr = splitIndex != -1 ? logStr.substring(0, splitIndex + 1) : '';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () => _showLogDetail(context, logStr),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeStr.isNotEmpty ? timeStr : logStr,
                              style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showLogDetail(BuildContext context, String log) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('报错详情'),
          content: SingleChildScrollView(
            child: SelectableText(
              log,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: log));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 2)),
                );
              },
              child: const Text('复制'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    switch (_state) {
      case CloudState.connected:
        icon = Icons.cloud_done;
        color = Colors.green;
        text = '已连接';
        break;
      case CloudState.disconnected:
        icon = Icons.cloud_off;
        color = Colors.yellow;
        text = '未连接';
        break;
      case CloudState.unconfigured:
        icon = Icons.cloud_off;
        color = Colors.red;
        text = '未配置';
        break;
    }

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
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
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
