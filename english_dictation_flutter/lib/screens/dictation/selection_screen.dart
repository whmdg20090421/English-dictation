import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictation_provider.dart';
import '../../db/data_manager.dart';
import '../../app_state.dart';
import 'testing_screen.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({Key? key}) : super(key: key);

  @override
  _SelectionScreenState createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  int _spellingQty = 0;
  int _posQty = 0;
  int _translationQty = 0;
  
  bool _spellingEnabled = true;
  bool _posEnabled = false;
  bool _translationEnabled = false;

  int _totalWords = 0;
  List<Map<String, dynamic>> _vocab = [];

  @override
  void initState() {
    super.initState();
    _loadVocab();
  }

  void _loadVocab() {
    // Load from AppState if selectedWords is already set (e.g. from mistakes)
    if (AppState.instance.selectedWords.isNotEmpty) {
      _vocab = AppState.instance.selectedWords;
    } else {
      // Otherwise load all words
      _vocab = DataManager.getAllWords(DataManager.instance.vocab);
    }

    setState(() {
      _totalWords = _vocab.length;
      _spellingQty = _totalWords;
      _posQty = _totalWords;
      _translationQty = _totalWords;
    });

    if (mounted) {
      final provider = Provider.of<DictationProvider>(context, listen: false);
      provider.accountId = int.tryParse(AppState.instance.currentAccountId) ?? 0;
      provider.loadWords(_vocab);
      
      // Load account settings
      final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
      final settings = currentAcc['settings'] ?? {};
      provider.allowBackward = settings['allow_backward'] ?? true;
      provider.allowHint = settings['allow_hint'] ?? false;
      provider.perQTime = (settings['per_q_time'] ?? 20.0).toDouble();
    }
  }

  void _startMixedTest() {
    if (_totalWords == 0) {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(const SnackBar(content: Text('请先添加单词!')));
      return;
    }
    
    if (!_spellingEnabled && !_posEnabled && !_translationEnabled) {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(const SnackBar(content: Text('请至少勾选一种题型！')));
      return;
    }

    final provider = Provider.of<DictationProvider>(context, listen: false);
    provider.generateMixedTest(
      _spellingEnabled ? _spellingQty : 0,
      _posEnabled ? _posQty : 0,
      _translationEnabled ? _translationQty : 0
    );

    Navigator.push(context, MaterialPageRoute(builder: (_) => const TestingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('混合生成模式')),
      body: _vocab.isEmpty 
        ? const Center(child: Text("当前账户无单词，请先在数据浏览器添加单词。", style: TextStyle(color: Colors.white70)))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text('当前单词池容量: $_totalWords 个', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 20),
                const Text('题型与数量配置 (允许重复测试单词)', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildModeCard('拼写模式 (中译英)', _spellingEnabled, _spellingQty, (val) => setState(() => _spellingEnabled = val!), (val) => setState(() => _spellingQty = int.tryParse(val) ?? _totalWords)),
                _buildModeCard('词性辨析 (选词性)', _posEnabled, _posQty, (val) => setState(() => _posEnabled = val!), (val) => setState(() => _posQty = int.tryParse(val) ?? _totalWords)),
                _buildModeCard('翻译模式 (英译中)', _translationEnabled, _translationQty, (val) => setState(() => _translationEnabled = val!), (val) => setState(() => _translationQty = int.tryParse(val) ?? _totalWords)),
                
                const SizedBox(height: 20),
                const Text('全局难度配置', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Consumer<DictationProvider>(
                  builder: (context, provider, child) {
                    return Card(
                      color: Colors.white10,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('允许倒退与修改', style: TextStyle(color: Colors.white)),
                              value: provider.allowBackward,
                              onChanged: (val) => setState(() => provider.allowBackward = val),
                            ),
                            SwitchListTile(
                              title: const Text('开启首字母智能提示', style: TextStyle(color: Colors.white)),
                              value: provider.allowHint,
                              onChanged: (val) => setState(() => provider.allowHint = val),
                            ),
                            TextFormField(
                              initialValue: provider.perQTime.toString(),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: '单题限时 (秒)', labelStyle: TextStyle(color: Colors.white70)),
                              onChanged: (val) => setState(() => provider.perQTime = double.tryParse(val) ?? 20.0),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _startMixedTest,
                  child: const Text('融合生成试卷并开始', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
    );
  }

  Widget _buildModeCard(String title, bool enabled, int qty, void Function(bool?) onChecked, void Function(String) onChanged) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Checkbox(value: enabled, onChanged: onChecked),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
            if (enabled)
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: qty.toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onChanged: onChanged,
                ),
              )
          ],
        ),
      ),
    );
  }
}
