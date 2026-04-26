import 'package:flutter/material.dart';
import 'dart:convert';
import '../sync/webdav_new/webdav_file.dart';
import '../sync/cloud_sync_service.dart';
import '../utils/crypto_utils.dart';

class CloudFileManagerScreen extends StatefulWidget {
  const CloudFileManagerScreen({super.key});

  @override
  State<CloudFileManagerScreen> createState() => _CloudFileManagerScreenState();
}

class _CloudFileManagerScreenState extends State<CloudFileManagerScreen> {
  final CloudSyncService _syncService = CloudSyncService();
  String _currentPath = '/英语听写';
  List<WebDavFile> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });
    
    final files = await _syncService.listFiles(_currentPath);
    // Remove the current directory from the list if present
    files.removeWhere((file) => file.path == _currentPath || file.path == '$_currentPath/');
    
    // Sort directories first, then files
    files.sort((a, b) {
      if (a.isDirectory == b.isDirectory) {
        return a.name.compareTo(b.name);
      }
      return a.isDirectory ? -1 : 1;
    });

    if (mounted) {
      setState(() {
        _files = files;
        _isLoading = false;
      });
    }
  }

  void _navigateUp() {
    if (_currentPath == '/') return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    if (parts.isEmpty) {
      _currentPath = '/';
    } else {
      _currentPath = parts.join('/');
    }
    if (_currentPath.isEmpty) _currentPath = '/';
    _loadFiles();
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    });
    _loadFiles();
  }

  Future<void> _showDeleteConfirm(WebDavFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${file.name} 吗？\n删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && file.path.isNotEmpty) {
      setState(() => _isLoading = true);
      final success = await _syncService.deleteFile(file.path);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(content: Text('删除成功'), backgroundColor: Colors.green),
          );
        }
        _loadFiles();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '文件夹名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() => _isLoading = true);
      final newPath = _currentPath == '/' ? '/$name' : '$_currentPath/$name';
      final success = await _syncService.createFolder(newPath);
      if (success) {
        _loadFiles();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(content: Text('创建文件夹失败'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
  
  Future<void> _showMoveDialog(WebDavFile file) async {
    if (file.path.isEmpty) return;
    
    final oldPath = file.path.endsWith('/') ? file.path.substring(0, file.path.length - 1) : file.path;
    final controller = TextEditingController(text: oldPath);
    
    final newPath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名 / 移动'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '新路径'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newPath != null && newPath.isNotEmpty && newPath != oldPath) {
      setState(() => _isLoading = true);
      
      final success = await _syncService.moveFile(oldPath, newPath);
      if (success) {
        _loadFiles();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(content: Text('移动/重命名失败'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showCopyDialog(WebDavFile file) async {
    if (file.path.isEmpty) return;
    
    final oldPath = file.path.endsWith('/') ? file.path.substring(0, file.path.length - 1) : file.path;
    final controller = TextEditingController(text: '${oldPath}_副本');
    
    final newPath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('复制文件'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '副本路径'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newPath != null && newPath.isNotEmpty && newPath != oldPath) {
      setState(() => _isLoading = true);
      
      final success = await _syncService.copyFile(oldPath, newPath);
      if (success) {
        _loadFiles();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(content: Text('复制失败'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
  
  Future<String?> _promptForEncryptionPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入数据加密密钥'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '用于解密此文件',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('解密'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewOrEditFile(WebDavFile file) async {
    if (file.path.isEmpty) return;
    
    setState(() => _isLoading = true);
    final content = await _syncService.readFileText(file.path);
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (content == null) {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
        const SnackBar(content: Text('无法读取文件内容（可能不是文本文件）'), backgroundColor: Colors.red),
      );
      return;
    }
    
    String displayContent = content;
    bool isEncrypted = file.name.endsWith('.json') && !content.trim().startsWith('{');
    String? encryptionPassword;

    if (isEncrypted) {
      final pwd = await _promptForEncryptionPassword();
      if (pwd == null || pwd.isEmpty) return;
      
      final decryptedMap = _syncService.decryptData(content, pwd);
      if (decryptedMap == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(content: Text('解密失败，密钥错误或文件已损坏'), backgroundColor: Colors.red),
        );
        return;
      }
      
      displayContent = const JsonEncoder.withIndent('  ').convert(decryptedMap);
      encryptionPassword = pwd;
    }
    
    final controller = TextEditingController(text: displayContent);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑文件 - ${file.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 15,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '文件内容',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (newContent != null && newContent != displayContent) {
      setState(() => _isLoading = true);
      String finalContentToSave = newContent;
      
      if (isEncrypted && encryptionPassword != null) {
        try {
          final map = jsonDecode(newContent) as Map<String, dynamic>;
          finalContentToSave = _syncService.encryptData(map, encryptionPassword);
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
              const SnackBar(content: Text('JSON 格式错误，无法加密保存'), backgroundColor: Colors.red),
            );
          }
          return;
        }
      }
      
      final success = await _syncService.writeFileText(file.path, finalContentToSave);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(content: Text('保存成功'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(content: Text('保存失败'), backgroundColor: Colors.red),
          );
        }
      }
      _loadFiles();
    }
  }
  
  void _showFileOptions(WebDavFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(file.isDirectory ? '文件夹' : '文件'),
            ),
            const Divider(),
            if (!file.isDirectory)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('查看/编辑内容'),
                onTap: () {
                  Navigator.pop(context);
                  _viewOrEditFile(file);
                },
              ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('重命名 / 移动'),
              onTap: () {
                Navigator.pop(context);
                _showMoveDialog(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('复制'),
              onTap: () {
                Navigator.pop(context);
                _showCopyDialog(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云端文件管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _showCreateFolderDialog,
            tooltip: '新建文件夹',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[200],
            width: double.infinity,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _currentPath == '/' ? null : _navigateUp,
                  tooltip: '返回上一级',
                ),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(child: Text('文件夹为空'))
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          final isDir = file.isDirectory;
                          return ListTile(
                            leading: Icon(
                              isDir ? Icons.folder : Icons.insert_drive_file,
                              color: isDir ? Colors.amber : Colors.blue,
                              size: 32,
                            ),
                            title: Text(file.name),
                            subtitle: Text(file.lastModified?.toString() ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showFileOptions(file),
                            ),
                            onTap: () {
                              if (isDir && file.path.isNotEmpty) {
                                _navigateTo(file.path);
                              } else {
                                _showFileOptions(file);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
