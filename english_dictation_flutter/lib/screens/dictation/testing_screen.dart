import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../providers/dictation_provider.dart';
import 'interim_report_screen.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({Key? key}) : super(key: key);

  @override
  _TestingScreenState createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  late DictationProvider _provider;
  Timer? _timer;
  final FlutterTts _tts = FlutterTts();

  // Spelling state
  String _spellingText = "";
  bool _spellingCaps = false;
  bool _spellingSym = false;

  // Translation state
  final TextEditingController _transController = TextEditingController();

  // POS state
  Set<String> _selectedPos = {};

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<DictationProvider>(context, listen: false);
    _initTts();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentQuestionState();
      _playCurrentWord();
    });
  }

  void _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _provider.tick();
      if (_provider.totLeft <= 0) {
        _timer?.cancel();
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(const SnackBar(content: Text('总时间耗尽！系统已强制交卷。')));
        _actionSubmit();
      }
    });
  }

  void _playCurrentWord() async {
    if (_provider.currentQIndex < _provider.testQueue.length) {
      await _tts.speak(_provider.testQueue[_provider.currentQIndex]['word']);
    }
  }

  void _loadCurrentQuestionState() {
    _spellingText = "";
    _transController.clear();
    _selectedPos.clear();

    if (_provider.userAnswers.containsKey(_provider.currentQIndex)) {
      final ans = _provider.userAnswers[_provider.currentQIndex]!['ans'] as String;
      if (ans != "跳过/未作答" && ans != "未选择") {
        final mode = _provider.testQueue[_provider.currentQIndex]['_test_mode'] ?? 'spelling';
        if (mode == 'spelling') _spellingText = ans;
        else if (mode == 'translation') _transController.text = ans;
        else if (mode == 'pos') _selectedPos = ans.split(',').toSet();
      }
    }
    setState(() {});
  }

  void _popHint() {
    if (!_provider.allowHint) return;
    final meta = _provider.testQueue[_provider.currentQIndex];
    final mode = meta['_test_mode'] ?? 'spelling';
    final target = mode == 'spelling' ? meta['word'] as String : meta['translation'] as String? ?? "";
    
    _provider.useHint();
    String hintText = "";
    
    if (mode == 'spelling') {
      int lcp = 0;
      for (int i = 0; i < target.length && i < _spellingText.length; i++) {
        if (target[i].toLowerCase() == _spellingText[i].toLowerCase()) lcp++;
        else break;
      }
      if (lcp < target.length) {
        hintText = "Next: ${target[lcp]}";
      } else {
        hintText = "Perfect match so far!";
      }
    } else {
      hintText = "Start with: ${target.isNotEmpty ? target[0] : ''}";
    }

    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text('提示: $hintText'), duration: const Duration(seconds: 2)));
  }

  bool _checkSpelling(String rawAns, String target) {
    return rawAns.trim().toLowerCase() == target.trim().toLowerCase();
  }

  void _submitSpelling() {
    if (_provider.isSubmitting) return;
    _provider.isSubmitting = true;
    final meta = _provider.testQueue[_provider.currentQIndex];
    final target = meta['word'] as String;
    final isCorrect = _checkSpelling(_spellingText, target);
    final qStr = meta['translation'] as String? ?? "";
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _provider.isSubmitting = false;
      _provider.recordAnswerAndNext(isCorrect, 'spelling', qStr, _spellingText, false, [target], isCorrect ? 1.0 : 0.0);
      _loadCurrentQuestionState();
      _playCurrentWord();
    });
  }

  void _submitPos() {
    _provider.isSubmitting = true;
    final meta = _provider.testQueue[_provider.currentQIndex];
    final target = meta['word'] as String;
    
    // Find all parts of speech in the dictionary for this word
    final List<String> validPosList = meta.keys.where((k) => k.toString().endsWith('.') && k != 'translation' && k != 'word' && k != '_test_mode').map((e) => e.toString()).toList();
    final List<String> expectedPos = validPosList.isNotEmpty ? validPosList : ['n.']; 
    
    bool isCorrect = _selectedPos.isNotEmpty; // simplistic check
    final ansStr = _selectedPos.isNotEmpty ? _selectedPos.join(',') : "未选择";
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _provider.isSubmitting = false;
      _provider.recordAnswerAndNext(isCorrect, 'pos', target, ansStr, false, expectedPos, isCorrect ? 1.0 : 0.0);
      _loadCurrentQuestionState();
      _playCurrentWord();
    });
  }

  void _submitTranslation() {
    if (_provider.isSubmitting) return;
    _provider.isSubmitting = true;
    final meta = _provider.testQueue[_provider.currentQIndex];
    final target = meta['word'] as String;
    final expected = meta['translation'] as String? ?? "";
    final validTranslations = expected.split(RegExp(r'[,;]')).map((e) => e.trim()).toList();
    
    final ans = _transController.text.trim();
    final isCorrect = validTranslations.contains(ans);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _provider.isSubmitting = false;
      _provider.recordAnswerAndNext(isCorrect, 'translation', target, ans, !isCorrect, validTranslations, isCorrect ? 1.0 : 0.0);
      _loadCurrentQuestionState();
      _playCurrentWord();
    });
  }

  void _actionNext() {
    _provider.forceNext();
    _loadCurrentQuestionState();
    _playCurrentWord();
  }

  void _actionPrev() {
    _provider.forcePrev();
    _loadCurrentQuestionState();
    _playCurrentWord();
  }

  void _actionSubmit() {
    _timer?.cancel();
    _provider.submitTest();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InterimReportScreen()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    _transController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Consumer<DictationProvider>(
          builder: (context, prov, child) => Text("${prov.currentQIndex + 1}/${prov.testQueue.length}"),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: () => Navigator.pop(context))
        ],
      ),
      body: Consumer<DictationProvider>(
        builder: (context, prov, child) {
          if (prov.testQueue.isEmpty) return const Center(child: Text("无题目"));
          
          final meta = prov.testQueue[prov.currentQIndex];
          final mode = meta['_test_mode'] ?? 'spelling';
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("交卷倒计时: ${prov.totLeft.toInt()}s", style: const TextStyle(color: Colors.amber, fontFamily: 'monospace')),
                    Text("本题剩余: ${prov.qTimeLeft.toInt()}s", style: TextStyle(color: prov.qTimeLeft < 0 ? Colors.red : Colors.greenAccent, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Card(
                    color: Colors.white10,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10, right: 10,
                          child: IconButton(icon: const Icon(Icons.volume_up, color: Colors.lightBlueAccent), onPressed: _playCurrentWord),
                        ),
                        if (prov.allowHint)
                          Positioned(
                            top: 10, left: 10,
                            child: IconButton(icon: Icon(Icons.lightbulb, color: prov.qTimeLeft <= prov.perQTime - 5 ? Colors.amber : Colors.grey), onPressed: _popHint),
                          ),
                        Center(
                          child: _buildQuestionContent(mode, meta),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: prov.allowBackward ? Colors.blue : Colors.grey),
                      icon: Icon(prov.allowBackward ? Icons.arrow_back : Icons.lock),
                      label: const Text("上一题"),
                      onPressed: prov.allowBackward ? _actionPrev : null,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      icon: const Icon(Icons.skip_next),
                      label: const Text("跳过"),
                      onPressed: _actionNext,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      icon: const Icon(Icons.done_all),
                      label: const Text("交卷"),
                      onPressed: _actionSubmit,
                    ),
                  ],
                )
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildQuestionContent(String mode, Map<String, dynamic> meta) {
    if (mode == 'spelling') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(meta['translation'] ?? "", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white54))),
            child: Text(_spellingText.isEmpty ? " " : _spellingText, style: const TextStyle(fontSize: 28, color: Colors.greenAccent, letterSpacing: 2, fontFamily: 'monospace')),
          ),
          const SizedBox(height: 30),
          _buildVirtualKeyboard(),
        ],
      );
    } else if (mode == 'pos') {
      // Collect available parts of speech from vocab structure or use defaults
      final Set<String> allPossiblePos = {'n.', 'v.', 'adj.', 'adv.', 'prep.', 'conj.', 'pron.', 'num.', 'art.', 'int.'};
      final List<String> wordPosList = meta.keys.where((k) => k.toString().endsWith('.') && k != 'translation' && k != 'word' && k != '_test_mode').map((e) => e.toString()).toList();
      allPossiblePos.addAll(wordPosList);
      final List<String> opts = allPossiblePos.toList()..sort();
      
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(meta['word'] ?? "", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text('多选题 (漏选得部分分，错选不得分)', style: TextStyle(color: Colors.amber)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
            children: opts.map((o) {
              final isSel = _selectedPos.contains(o);
              return ChoiceChip(
                label: Text(o),
                selected: isSel,
                onSelected: (val) => setState(() {
                  if (val) _selectedPos.add(o); else _selectedPos.remove(o);
                }),
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey.shade800,
                labelStyle: const TextStyle(color: Colors.white),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(200, 50)),
            onPressed: _submitPos,
            child: const Text('确定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          )
        ],
      );
    } else if (mode == 'translation') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(meta['word'] ?? "", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _transController,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(hintText: '输入中文释义', hintStyle: TextStyle(color: Colors.white30)),
              onSubmitted: (_) => _submitTranslation(),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(200, 50)),
            onPressed: _submitTranslation,
            child: const Text('确定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          )
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildVirtualKeyboard() {
    List<String> rows = _spellingSym 
        ? ["1 2 3 4 5 6 7 8 9 0", "- / : ; ( ) \$ & @ \"", ". , ? ! '"]
        : ["q w e r t y u i o p", "a s d f g h j k l", "z x c v b n m"];
    
    if (_spellingCaps && !_spellingSym) rows = rows.map((r) => r.toUpperCase()).toList();

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (i == 2 && !_spellingSym)
                _kbdKey('⬆', flex: 2, color: _spellingCaps ? Colors.grey : Colors.white12, onPressed: () => setState(() => _spellingCaps = !_spellingCaps)),
              if (i == 2 && _spellingSym)
                _kbdKey('[]=', flex: 2, color: Colors.white12),
              
              for (var k in rows[i].split(' '))
                _kbdKey(k, onPressed: () => setState(() => _spellingText += k)),
                
              if (i == 2)
                _kbdKey('⌫', flex: 2, onPressed: () => setState(() {
                  if (_spellingText.isNotEmpty) _spellingText = _spellingText.substring(0, _spellingText.length - 1);
                })),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _kbdKey(_spellingSym ? 'ABC' : '?123', flex: 2, onPressed: () => setState(() => _spellingSym = !_spellingSym)),
            _kbdKey('空 格', flex: 4, onPressed: () => setState(() => _spellingText += ' ')),
            _kbdKey('确定', flex: 3, color: Colors.blue, onPressed: _submitSpelling),
          ],
        )
      ],
    );
  }

  Widget _kbdKey(String label, {int flex = 1, Color color = Colors.white12, VoidCallback? onPressed}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }
}
