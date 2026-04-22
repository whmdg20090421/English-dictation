import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('后台管理'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: '单词管理'),
            Tab(icon: Icon(Icons.import_export), text: '导入/导出'),
            Tab(icon: Icon(Icons.settings), text: '设置'),
            Tab(icon: Icon(Icons.history), text: '日志'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _WordsTab(),
          _ImportExportTab(),
          _SettingsTab(),
          _LogsTab(),
        ],
      ),
    );
  }
}

// 单词管理 Tab
class _WordsTab extends StatefulWidget {
  const _WordsTab();

  @override
  State<_WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<_WordsTab> {
  // Mock data
  final List<Map<String, dynamic>> _words = [
    {'id': 1, 'word': 'apple', 'translation': '苹果', 'pos': 'n.', 'unit': 'Unit 1'},
    {'id': 2, 'word': 'run', 'translation': '跑', 'pos': 'v.', 'unit': 'Unit 1'},
    {'id': 3, 'word': 'beautiful', 'translation': '美丽的', 'pos': 'adj.', 'unit': 'Unit 2'},
  ];

  void _showEditDialog(Map<String, dynamic>? wordData) {
    final isEditing = wordData != null;
    final wordController = TextEditingController(text: wordData?['word']);
    final translationController = TextEditingController(text: wordData?['translation']);
    final posController = TextEditingController(text: wordData?['pos']);
    final unitController = TextEditingController(text: wordData?['unit']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? '编辑单词' : '添加单词'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordController,
                decoration: const InputDecoration(labelText: '单词'),
              ),
              TextField(
                controller: translationController,
                decoration: const InputDecoration(labelText: '释义'),
              ),
              TextField(
                controller: posController,
                decoration: const InputDecoration(labelText: '词性 (POS)'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: '所属单元/分类'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Save to DB
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEditing ? '单词已更新' : '单词已添加')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(Map<String, dynamic> wordData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动单词'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('将 "${wordData['word']}" 移动到新单元：'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '目标单元名称',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Move in DB
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('移动成功')),
              );
            },
            child: const Text('确认移动'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '搜索单词...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showEditDialog(null),
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _words.length,
            itemBuilder: (context, index) {
              final word = _words[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text('${word['word']} (${word['pos']})'),
                  subtitle: Text('${word['translation']} - ${word['unit']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.drive_file_move_outline),
                        tooltip: '移动',
                        onPressed: () => _showMoveDialog(word),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: '编辑',
                        onPressed: () => _showEditDialog(word),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: '删除',
                        onPressed: () {
                          // TODO: Delete from DB
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已删除')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// 导入/导出 Tab
class _ImportExportTab extends StatelessWidget {
  const _ImportExportTab();

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('从文本解析导入 (格式: 单词 词性 释义)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: '例如：\napple n. 苹果\nrun v. 跑',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Parse text and insert to DB
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('解析并导入成功')),
                  );
                },
                icon: const Icon(Icons.input),
                label: const Text('解析并插入数据库'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Export to JSON
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已导出为 JSON')),
                  );
                },
                icon: const Icon(Icons.output),
                label: const Text('导出为 JSON'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 设置 Tab
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  double _timeLimit = 30.0;
  bool _showHints = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('测试设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('单词测试时间限制: ${_timeLimit.toInt()} 秒'),
                Slider(
                  value: _timeLimit,
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '${_timeLimit.toInt()} 秒',
                  onChanged: (value) {
                    setState(() {
                      _timeLimit = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            title: const Text('开启提示'),
            subtitle: const Text('在听写测试中显示首字母或词性提示'),
            value: _showHints,
            onChanged: (value) {
              setState(() {
                _showHints = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // TODO: Save settings to DB
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('设置已保存')),
            );
          },
          child: const Text('保存设置'),
        ),
      ],
    );
  }
}

// 日志 Tab
class _LogsTab extends StatelessWidget {
  const _LogsTab();

  @override
  Widget build(BuildContext context) {
    // Mock logs
    final logs = [
      '2023-10-01 10:00:00 - 测试完成：Unit 1 (得分 90/100)',
      '2023-10-01 09:30:00 - 导入单词 20 个',
      '2023-09-30 15:20:00 - 修改单词 "apple"',
      '2023-09-29 08:00:00 - 测试完成：Unit 2 (得分 85/100)',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('系统操作与测试日志', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('清空历史记录'),
                      content: const Text('确定要清空所有日志和历史记录吗？此操作不可恢复。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Clear logs in DB
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('历史记录已清空')),
                            );
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('确认清空'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('清空历史'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(logs[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
