import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('系统后台', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.settings, size: 24),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '全局书单与词库'),
            Tab(text: '导入与导出'),
            Tab(text: '专属系统设置'),
            Tab(text: '个人听写明细'),
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

// 单词管理 Tab (全局书单与词库)
class _WordsTab extends StatefulWidget {
  const _WordsTab();

  @override
  State<_WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<_WordsTab> {
  bool _isEditMode = false;
  
  // 模拟的词库结构，用于匹配 Python 版本的树形结构
  final Map<String, dynamic> _vocab = {
    '小学/五年级/下册': {
      'Unit 1': {
        'word_01': {'单词': 'eat breakfast', 'v.': '吃早饭'},
      }
    }
  };

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建根文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入名称 (如: 小学)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _vocab[controller.text.trim()] = {};
              });
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showWordDialog(String book, String unit, {String? wordId, Map<String, dynamic>? initialData}) {
    final wordController = TextEditingController(text: initialData?['单词'] ?? '');
    final posWidgets = <Widget>[];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(wordId == null ? '新增单词' : '编辑单词'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: wordController,
                      decoration: const InputDecoration(labelText: '英文拼写'),
                    ),
                    const SizedBox(height: 10),
                    ...posWidgets,
                    TextButton(
                      onPressed: () {
                        setStateDialog(() {
                          posWidgets.add(
                            Row(
                              children: [
                                Expanded(child: TextField(decoration: const InputDecoration(labelText: '词性/短语(n.)'))),
                                const SizedBox(width: 8),
                                Expanded(child: TextField(decoration: const InputDecoration(labelText: '释义'))),
                              ],
                            )
                          );
                        });
                      },
                      child: const Text('+ 添加考点词性'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: null,
                  child: const Text('保存 (未实现)'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _showNewFolderDialog,
                icon: const Icon(Icons.add),
                label: const Text('新建根文件夹', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              Row(
                children: [
                  const Text('编辑排序', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _isEditMode,
                    onChanged: (val) => setState(() => _isEditMode = val),
                    activeColor: Colors.amber,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_vocab.isEmpty)
          const Expanded(child: Center(child: Text('词库为空，请先新建根文件夹', style: TextStyle(color: Colors.grey)))),
        if (_vocab.isNotEmpty)
          Expanded(
            child: ListView(
              children: _vocab.entries.map((bookEntry) {
                return ExpansionTile(
                  leading: const Icon(Icons.folder),
                  title: Text(bookEntry.key),
                  children: (bookEntry.value as Map<String, dynamic>).entries.map((unitEntry) {
                    return ExpansionTile(
                      leading: const Icon(Icons.description),
                      title: Text('${unitEntry.key} (${(unitEntry.value as Map).length} 词)'),
                      children: (unitEntry.value as Map<String, dynamic>).entries.map((wordEntry) {
                        return ListTile(
                          title: Text(wordEntry.value['单词'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_isEditMode)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showWordDialog(bookEntry.key, unitEntry.key, wordId: wordEntry.key, initialData: wordEntry.value),
                                ),
                              if (_isEditMode) ...[
                                // IconButton(icon: const Icon(Icons.arrow_upward), onPressed: () {}),
                                // IconButton(icon: const Icon(Icons.arrow_downward), onPressed: () {}),
                                // IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {}),
                              ]
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// 导入与导出 Tab
class _ImportExportTab extends StatelessWidget {
  const _ImportExportTab();

  void _safeCopy(BuildContext context, String text, String title) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text('已尝试复制: $title')));
  }

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();

    const aiPromptSingle = """请帮我把以下内容（文本或图片）转换为严格的 JSON 格式，方便我导入听写系统。
【结构要求：单单元扁平模式】
1. 必须是单层扁平化结构：外层键名为"唯一的单词ID"（如word_01），值为该单词的属性字典。
2. 属性字典中，必须包含一个键名为 "单词"，值为英文拼写。如果是短语包含空格即可。
3. 其他属性键名为词性（如 "n.", "v."，若无词性可直接用 "释义"），值为中文解释。
4. 纯 JSON 代码，不要外层书名/单元包裹。
【输出严格规范】
请务必将结果直接包裹在可复制的 ```json 和 ``` 代码块中！
请直接输出 JSON 代码块，绝不要输出任何解释、问候语、确认语或普通对话内容！""";

    const aiPromptMulti = """请帮我把以下内容（可能是多张图片或长文本）转换为严格的 JSON 格式，方便我导入听写系统。
【结构要求：多书册/多单元完整层级模式】
1. 系统需要完整的层级结构：{ "书册名称": { "单元名称": { "单词ID": {属性字典} } } }。
2. 请根据我提供的内容，自动识别或归纳出合理的“书册名称”（如：八年级上册）和“单元名称”（如：Unit 1）。如果图片中跨越了多个单元，请将它们正确分类到对应的单元对象下。
3. 单词ID需要保证在单元内唯一（如 word_01）。
4. 属性字典中，必须包含一个键名为 "单词"，值为英文拼写。如果是短语包含空格即可。
5. 其他属性键名为词性（如 "n.", "v."，若无词性可直接用 "释义"），值为中文解释。
【输出严格规范】
请务必将结果直接包裹在可复制的 ```json 和 ``` 代码块中！
请直接输出 JSON 代码块，绝不要输出任何解释、问候语、确认语或普通对话内容！""";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          TextField(
            controller: textController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '粘贴 JSON 代码进行导入',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.black26,
            ),
          ),
          const SizedBox(height: 8),
          // const Text('指定导入目标 (书册或单词集)', style: TextStyle(color: Colors.amber, fontSize: 16)),
          // ElevatedButton(
          //   style: ElevatedButton.styleFrom(alignment: Alignment.centerLeft, backgroundColor: Colors.blue.withOpacity(0.5)),
          //   onPressed: null, // () {},
          //   child: const Text('导入位置: / (根目录)'),
          // ),
          // const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: null, // () {},
            child: const Text('智能校验并导入 (未实现)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 24),
          const Text('获取 AI 格式化提示词', style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => _safeCopy(context, aiPromptSingle, '单单元模板'),
                  icon: const Icon(Icons.content_copy),
                  label: const Text('复制单单元模板'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () => _safeCopy(context, aiPromptMulti, '完整层级模板'),
                  icon: const Icon(Icons.content_copy),
                  label: const Text('复制完整层级模板'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('词库导出与备份', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: null, // () {},
                  icon: const Icon(Icons.download),
                  label: const Text('下载完整备份 (未实现)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: null, // () {},
                  icon: const Icon(Icons.content_copy),
                  label: const Text('复制词库代码 (未实现)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 专属系统设置 Tab
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _hideConfig = false;
  bool _allowBackward = true;
  bool _allowHint = false;
  bool _timerLock = true;
  double _perQTime = 20.0;
  int _hintDelay = 5;
  int _hintLimit = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('[当前账户] 专属听写配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                SwitchListTile(title: const Text('隐藏听写前配置界面 (直接使用默认)'), value: _hideConfig, onChanged: (v) => setState(() => _hideConfig = v)),
                SwitchListTile(title: const Text('允许倒退与修改'), value: _allowBackward, onChanged: (v) => setState(() => _allowBackward = v)),
                SwitchListTile(title: const Text('开启首字母提示'), value: _allowHint, onChanged: (v) => setState(() => _allowHint = v)),
                SwitchListTile(title: const Text('限时关联计算锁 (时间到强制跳题)'), value: _timerLock, onChanged: (v) => setState(() => _timerLock = v)),
                TextField(
                  decoration: const InputDecoration(labelText: '默认单题限时 (秒)'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _perQTime.toString()),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '提示亮起延迟 (秒)'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _hintDelay.toString()),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '每局最大提示次数 (0为无限)'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _hintLimit.toString()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('[当前账户] 数据清理区', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
          onPressed: null, // () {},
          icon: const Icon(Icons.delete_sweep),
          label: const Text('清空所有统计与历史记录 (未实现)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
          onPressed: null, // () {},
          icon: const Icon(Icons.playlist_remove),
          label: const Text('仅清空错题本记录 (未实现)'),
        ),
        const SizedBox(height: 16),
        const Text('全局安全控制与密码管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('高强度密码加密隔离', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('当前状态：🔒 已加密隐藏 (安全)', style: TextStyle(color: Colors.amber)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: null, child: const Text('点击切换加密/明文状态 (未实现)')),
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('修改系统管理员主密码', style: TextStyle(fontWeight: FontWeight.bold)),
                const TextField(decoration: InputDecoration(labelText: '请输入当前旧密码'), obscureText: true),
                const TextField(decoration: InputDecoration(labelText: '请输入新密码'), obscureText: true),
                const SizedBox(height: 8),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: null, child: const Text('确认修改密码 (未实现)')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('全局危险操作核心区', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
          onPressed: null,
          icon: const Icon(Icons.delete_forever),
          label: const Text('抹除所有账户及词库数据 (未实现)'),
        ),
      ],
    );
  }
}

// 个人听写明细 Tab
class _LogsTab extends StatelessWidget {
  const _LogsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('[当前账户] 专属听写明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: null,
                child: const Text('清空所有记录 (未实现)'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 2, // mock count
            itemBuilder: (context, index) {
              return ExpansionTile(
                title: Text('2024-04-22 10:00:00 (100分 - 混合模式 - 已完成)'),
                subtitle: const Text('总得分点: 10.0/10 | 提示使用: 0次', style: TextStyle(color: Colors.grey)),
                children: [
                  ListTile(
                    title: const Text('[spelling] apple -> apple (标答:[apple])', style: TextStyle(color: Colors.green)),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
