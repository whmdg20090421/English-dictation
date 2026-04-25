import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../db/data_manager.dart';
import '../app_state.dart';
import '../utils/crypto_utils.dart';
import '../sync/cloud_sync_service.dart';
import '../theme.dart';

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: '全局书单与词库'),
                Tab(text: '导入与导出'),
                Tab(text: '专属系统设置'),
                Tab(text: '个人听写明细'),
              ],
            ),
          ),
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

class PosController {
  TextEditingController pos = TextEditingController();
  TextEditingController meaning = TextEditingController();
}

// 单词管理 Tab (全局书单与词库)
class _WordsTab extends StatefulWidget {
  const _WordsTab();

  @override
  State<_WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<_WordsTab> {
  bool _isEditMode = false;

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
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  DataManager.instance.vocab[text] = <String, dynamic>{};
                });
                DataManager.instance.saveData();
              }
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showNewNodeDialog(List<String> path, bool isFile) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFile ? '新建单元(文件)' : '新建子文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  Map<String, dynamic> curr = DataManager.instance.vocab;
                  for (var p in path) {
                    curr[p] ??= <String, dynamic>{};
                    curr = (curr[p] as Map).cast<String, dynamic>();
                  }
                  curr[text] = {'_type': isFile ? 'file' : 'folder'};
                });
                DataManager.instance.saveData();
              }
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showWordDialog(List<String> path, {String? wordId, Map<String, dynamic>? initialData}) {
    final initialWord = initialData?['单词'] ?? initialData?['word'] ?? '';
    final wordController = TextEditingController(text: initialWord.toString());
    final posControllers = <PosController>[];

    if (initialData != null) {
      initialData.forEach((key, value) {
        if (key != '单词' && key != 'word' && key != '_uid' && key != 'source_book' && key != '_ask_pos' && key != '_test_mode' && key != '_type') {
          final pc = PosController();
          pc.pos.text = key;
          pc.meaning.text = value.toString();
          posControllers.add(pc);
        }
      });
    }

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
                    ...posControllers.map((pc) => Row(
                      children: [
                        Expanded(child: TextField(controller: pc.pos, decoration: const InputDecoration(labelText: '词性/短语(n.)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: pc.meaning, decoration: const InputDecoration(labelText: '释义'))),
                      ],
                    )),
                    TextButton(
                      onPressed: () {
                        setStateDialog(() {
                          posControllers.add(PosController());
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
                  onPressed: () {
                    final text = wordController.text.trim();
                    if (text.isEmpty) return;

                    Map<String, dynamic> curr = DataManager.instance.vocab;
                    for (var p in path) {
                      curr[p] ??= <String, dynamic>{};
                      curr = (curr[p] as Map).cast<String, dynamic>();
                    }
                    
                    final wId = wordId ?? 'word_${DateTime.now().millisecondsSinceEpoch}';
                    
                    Map<String, dynamic> newWordData = {'单词': text};
                    for (var pc in posControllers) {
                      if (pc.pos.text.isNotEmpty && pc.meaning.text.isNotEmpty) {
                        newWordData[pc.pos.text.trim()] = pc.meaning.text.trim();
                      }
                    }

                    curr[wId] = newWordData;
                    DataManager.instance.saveData();
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildVocabTree(Map<String, dynamic> node, List<String> path) {
    if (DataManager.isFile(node)) {
      // It's a file, list words inside
      final words = node.entries.where((e) => e.key != '_type').toList();
      return ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.description, color: Colors.blueAccent),
        title: Text('${path.last} (${words.length} 词)', style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ...words.map((wordEntry) {
            final wordData = wordEntry.value as Map;
            final displayWord = wordData['单词'] ?? wordData['word'] ?? '未知单词';
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 40, right: 16),
              title: Text(displayWord.toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isEditMode)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showWordDialog(path, wordId: wordEntry.key, initialData: wordEntry.value),
                    ),
                  if (_isEditMode)
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {
                      setState(() {
                        node.remove(wordEntry.key);
                      });
                      DataManager.instance.cleanEmptyNodes([...path, wordEntry.key]);
                    }),
                ],
              ),
            );
          }),
          if (!_isEditMode)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 40),
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text('新增单词', style: TextStyle(color: Colors.green)),
              onTap: () => _showWordDialog(path),
            ),
        ],
      );
    } else {
      // It's a folder, list children
      final children = node.entries.where((e) => e.key != '_type').toList();
      return ExpansionTile(
        leading: const Icon(Icons.folder, color: Colors.amber),
        title: Text(path.isEmpty ? 'Root' : path.last, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ...children.map((childEntry) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Row(
                children: [
                  Expanded(child: _buildVocabTree((childEntry.value as Map).cast<String, dynamic>(), [...path, childEntry.key])),
                  if (_isEditMode)
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                      setState(() {
                        node.remove(childEntry.key);
                      });
                      DataManager.instance.cleanEmptyNodes([...path, childEntry.key]);
                    }),
                ],
              ),
            );
          }),
          if (!_isEditMode)
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showNewNodeDialog(path, false),
                    icon: const Icon(Icons.create_new_folder, color: Colors.amber),
                    label: const Text('新建子文件夹', style: TextStyle(color: Colors.amber)),
                  ),
                  TextButton.icon(
                    onPressed: () => _showNewNodeDialog(path, true),
                    icon: const Icon(Icons.note_add, color: Colors.blueAccent),
                    label: const Text('新建单元(文件)', style: TextStyle(color: Colors.blueAccent)),
                  ),
                ],
              ),
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vocab = DataManager.instance.vocab;
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
        if (vocab.isEmpty)
          const Expanded(child: Center(child: Text('词库为空，请先新建根文件夹', style: TextStyle(color: Colors.grey)))),
        if (vocab.isNotEmpty)
          Expanded(
            child: ListView(
              children: vocab.entries.where((e) => e.key != '_type').map((entry) {
                return Row(
                  children: [
                    Expanded(child: _buildVocabTree((entry.value as Map).cast<String, dynamic>(), [entry.key])),
                    if (_isEditMode)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            vocab.remove(entry.key);
                          });
                          DataManager.instance.cleanEmptyNodes([entry.key]);
                        }
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// 导入与导出 Tab
class _ImportExportTab extends StatefulWidget {
  const _ImportExportTab();

  @override
  State<_ImportExportTab> createState() => _ImportExportTabState();
}

class _ImportExportTabState extends State<_ImportExportTab> {
  final TextEditingController textController = TextEditingController();

  void _safeCopy(BuildContext context, String text, String title) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text('已尝试复制: $title')));
  }

  void _importData() {
    try {
      final jsonStr = textController.text;
      final data = (jsonDecode(jsonStr) as Map).cast<String, dynamic>();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('高危操作确认'),
          content: const Text('确定要导入此数据吗？可能会覆盖或合并现有词库。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                bool isSingleUnit = false;
                if (data.values.isNotEmpty) {
                  for (var val in data.values) {
                    if (val is Map && (val.containsKey('单词') || val.containsKey('word'))) {
                      isSingleUnit = true;
                      break;
                    }
                  }
                }

                if (isSingleUnit) {
                  _showSingleUnitImportDialog(data);
                } else {
                  _mergeMultiUnit(data);
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导入失败: 格式错误')));
    }
  }

  void _showSingleUnitImportDialog(Map<String, dynamic> data) {
    final bookController = TextEditingController();
    final unitController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入单单元'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bookController, decoration: const InputDecoration(labelText: '书单名称')),
            TextField(controller: unitController, decoration: const InputDecoration(labelText: '单元名称')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final book = bookController.text.trim();
              final unit = unitController.text.trim();
              if (book.isEmpty || unit.isEmpty) return;
              final vocab = DataManager.instance.vocab;
              vocab[book] ??= {'_type': 'folder'};
              (vocab[book] as Map)[unit] ??= {'_type': 'file'};
              (vocab[book][unit] as Map).addAll(data);
              DataManager.instance.saveData();
              Navigator.pop(context);
              textController.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导入成功')));
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _deepMerge(Map target, Map source) {
    source.forEach((key, value) {
      if (value is Map) {
        if (!target.containsKey(key)) {
          target[key] = value;
        } else if (target[key] is Map) {
          _deepMerge(target[key] as Map, value);
        } else {
          target[key] = value; // Overwrite
        }
      } else {
        target[key] = value;
      }
    });
  }

  void _mergeMultiUnit(Map<String, dynamic> data) {
    _deepMerge(DataManager.instance.vocab, data);
    DataManager.instance.saveData();
    textController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('合并成功')));
  }

  void _downloadBackup() async {
    final data = {
      'vocab': DataManager.instance.vocab,
      'accounts': DataManager.instance.accounts,
      'global_settings': DataManager.instance.globalSettings,
    };
    final jsonStr = jsonEncode(data);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('\${dir.path}/backup.json');
      await file.writeAsString(jsonStr);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份已保存至: \${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: \$e')));
    }
  }

  void _copyVocabCode() {
    final jsonStr = jsonEncode(DataManager.instance.vocab);
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('词库代码已复制')));
  }

  @override
  Widget build(BuildContext context) {
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: _importData,
            child: const Text('智能校验并导入', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  onPressed: _downloadBackup,
                  icon: const Icon(Icons.download),
                  label: const Text('下载完整备份'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: _copyVocabCode,
                  icon: const Icon(Icons.content_copy),
                  label: const Text('复制词库代码'),
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

  final TextEditingController _perQTimeController = TextEditingController();
  final TextEditingController _hintDelayController = TextEditingController();
  final TextEditingController _hintLimitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _perQTimeController.dispose();
    _hintDelayController.dispose();
    _hintLimitController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
    final settings = currentAcc['settings'] ?? {};
    _hideConfig = settings['hide_test_config'] ?? false;
    _allowBackward = settings['allow_backward'] ?? true;
    _allowHint = settings['allow_hint'] ?? false;
    _timerLock = settings['timer_lock'] ?? true;
    _perQTime = (settings['per_q_time'] ?? 20.0).toDouble();
    _hintDelay = settings['hint_delay'] ?? 5;
    _hintLimit = settings['hint_limit'] ?? 0;

    _perQTimeController.text = _perQTime.toString();
    _hintDelayController.text = _hintDelay.toString();
    _hintLimitController.text = _hintLimit.toString();
  }

  void _saveSettings() {
    final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
    currentAcc['settings'] = {
      'hide_test_config': _hideConfig,
      'allow_backward': _allowBackward,
      'allow_hint': _allowHint,
      'timer_lock': _timerLock,
      'per_q_time': double.tryParse(_perQTimeController.text) ?? 20.0,
      'hint_delay': int.tryParse(_hintDelayController.text) ?? 5,
      'hint_limit': int.tryParse(_hintLimitController.text) ?? 0,
      'folders': currentAcc['settings']?['folders'] ?? [],
    };
    DataManager.instance.saveData();
  }

  void _clearStatsAndHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('高危操作确认'),
        content: const Text('确定要清空所有统计与历史记录吗？此操作不可逆！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
              currentAcc['stats'] = <String, dynamic>{};
                currentAcc['history'] = <dynamic>[];
              DataManager.instance.saveData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清空统计与历史记录')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _clearMistakes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('高危操作确认'),
        content: const Text('确定要清空错题本记录吗？此操作不可逆！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
              currentAcc['mistakes'] = [];
              DataManager.instance.saveData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清空错题本记录')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _eraseAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('危险操作'),
        content: const Text('确定要抹除所有数据吗？此操作不可逆！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              DataManager.instance.vocab.clear();
              DataManager.instance.accounts.clear();
              DataManager.instance.globalSettings.clear();
              DataManager.instance.saveData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('所有数据已抹除')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final _oldPassCtrl = TextEditingController();
        final _newPassCtrl = TextEditingController();
        final _confirmPassCtrl = TextEditingController();
        bool _obscureOld = true;
        bool _obscureNew = true;
        bool _obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              ),
              title: Text('修改系统管理员主密码', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _oldPassCtrl,
                      obscureText: _obscureOld,
                      decoration: InputDecoration(
                        labelText: '请输入原密码',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setStateDialog(() => _obscureOld = !_obscureOld),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newPassCtrl,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: '请输入新密码',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setStateDialog(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: '请再次输入新密码',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setStateDialog(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(backgroundColor: Colors.grey[500]),
                  child: const Text('取消', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    final encKey = CloudSyncService().encryptionPassword ?? '';
                    final currentEncryptedPass = DataManager.instance.globalSettings['password'] ?? '';
                    final oldInput = _oldPassCtrl.text;
                    final newInput = _newPassCtrl.text;
                    final confirmInput = _confirmPassCtrl.text;

                    // Verify old password
                    bool isOldCorrect = false;
                    if (currentEncryptedPass.isEmpty) {
                      isOldCorrect = oldInput == '123456';
                    } else {
                      isOldCorrect = CryptoUtils.verifyPassword(oldInput, currentEncryptedPass, encKey);
                    }

                    if (!isOldCorrect) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('原密码错误')));
                      return;
                    }

                    if (newInput.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新密码不能为空')));
                      return;
                    }

                    if (newInput != confirmInput) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次输入的新密码不一致')));
                      return;
                    }

                    // Save new password
                    final encryptedNewPass = CryptoUtils.encryptPassword(newInput, encKey);
                    DataManager.instance.globalSettings['password'] = encryptedNewPass;
                    DataManager.instance.saveData();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码修改成功，请妥善保管')));
                  },
                  child: const Text('确认修改', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                SwitchListTile(title: const Text('隐藏听写前配置界面 (直接使用默认)'), value: _hideConfig, onChanged: (v) { setState(() => _hideConfig = v); _saveSettings(); }),
                SwitchListTile(title: const Text('允许倒退与修改'), value: _allowBackward, onChanged: (v) { setState(() => _allowBackward = v); _saveSettings(); }),
                SwitchListTile(title: const Text('开启首字母提示'), value: _allowHint, onChanged: (v) { setState(() => _allowHint = v); _saveSettings(); }),
                SwitchListTile(title: const Text('限时关联计算锁 (时间到强制跳题)'), value: _timerLock, onChanged: (v) { setState(() => _timerLock = v); _saveSettings(); }),
                TextField(
                  decoration: const InputDecoration(labelText: '默认单题限时 (秒)'),
                  keyboardType: TextInputType.number,
                  controller: _perQTimeController,
                  onChanged: (v) { _saveSettings(); },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '提示亮起延迟 (秒)'),
                  keyboardType: TextInputType.number,
                  controller: _hintDelayController,
                  onChanged: (v) { _saveSettings(); },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '每局最大提示次数 (0为无限)'),
                  keyboardType: TextInputType.number,
                  controller: _hintLimitController,
                  onChanged: (v) { _saveSettings(); },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('[当前账户] 数据清理区', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
          onPressed: _clearStatsAndHistory,
          icon: const Icon(Icons.delete_sweep),
          label: const Text('清空所有统计与历史记录'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
          onPressed: _clearMistakes,
          icon: const Icon(Icons.playlist_remove),
          label: const Text('仅清空错题本记录'),
        ),
        const SizedBox(height: 16),
        const Text('全局外观与主题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('选择应用主题', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeModeType>(
                      segments: const [
                        ButtonSegment(value: ThemeModeType.light, label: Text('白天'), icon: Icon(Icons.light_mode)),
                        ButtonSegment(value: ThemeModeType.dark, label: Text('黑暗'), icon: Icon(Icons.dark_mode)),
                        ButtonSegment(value: ThemeModeType.cyberpunk, label: Text('赛博朋克'), icon: Icon(Icons.memory)),
                      ],
                      selected: {themeProvider.themeMode},
                      onSelectionChanged: (Set<ThemeModeType> newSelection) {
                        themeProvider.setTheme(newSelection.first);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('全局安全控制与密码管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('修改系统管理员主密码', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                  onPressed: _changePassword,
                  icon: const Icon(Icons.password),
                  label: const Text('修改密码', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('全局危险操作核心区', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
          onPressed: _eraseAllData,
          icon: const Icon(Icons.delete_forever),
          label: const Text('抹除所有账户及词库数据'),
        ),
      ],
    );
  }
}

// 个人听写明细 Tab
class _LogsTab extends StatefulWidget {
  const _LogsTab();

  @override
  State<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<_LogsTab> {
  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('高危操作确认'),
        content: const Text('确定要清空所有记录吗？此操作不可逆！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
              currentAcc['history'] = [];
              DataManager.instance.saveData();
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('记录已清空')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
    final history = (currentAcc['history'] as List?) ?? [];

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
                onPressed: _clearLogs,
                child: const Text('清空所有记录'),
              ),
            ],
          ),
        ),
        Expanded(
          child: history.isEmpty
            ? const Center(child: Text('暂无历史记录', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final log = history[index];
                  final details = (log['details'] as List?) ?? [];
                  return ExpansionTile(
                    title: Text("\${log['time'] ?? '未知时间'} (\${log['score'] ?? 0}分 - \${log['mode'] ?? '未知模式'} - 已完成)"),
                    subtitle: Text("总得分点: \${log['total_points'] ?? 0} | 提示使用: \${log['hints_used'] ?? 0}次", style: const TextStyle(color: Colors.grey)),
                    children: details.map<Widget>((d) {
                      final isCorrect = d['is_correct'] == true;
                      return ListTile(
                        title: Text("[\${d['type'] ?? '未知'}] \${d['word'] ?? ''} -> \${d['answer'] ?? ''} (标答:[\${d['correct_answer'] ?? ''}])", 
                          style: TextStyle(color: isCorrect ? Colors.green : Colors.red)),
                      );
                    }).toList(),
                  );
                },
              ),
        ),
      ],
    );
  }
}
