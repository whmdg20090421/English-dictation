import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictation_provider.dart';
import '../../db/data_manager.dart';
import '../../app_state.dart';
import 'results_screen.dart';

class ManualGradeScreen extends StatefulWidget {
  const ManualGradeScreen({Key? key}) : super(key: key);

  @override
  _ManualGradeScreenState createState() => _ManualGradeScreenState();
}

class _ManualGradeScreenState extends State<ManualGradeScreen> {
  void _markAll(bool isCorrect) {
    final provider = Provider.of<DictationProvider>(context, listen: false);
    for (var log in provider.scoreLog) {
      if (log['needs_manual'] == true) {
        log['correct'] = isCorrect;
        log['score_val'] = isCorrect ? 1.0 : 0.0;
        log['needs_manual'] = false;
        DataManager.instance.updateWordStats(AppState.instance.currentAccountId, log['word'], isCorrect);
      }
    }
    _goToResults();
  }

  void _markSingle(Map<String, dynamic> log, bool isCorrect) {
    setState(() {
      log['correct'] = isCorrect;
      log['score_val'] = isCorrect ? 1.0 : 0.0;
      log['needs_manual'] = false;
    });
    DataManager.instance.updateWordStats(AppState.instance.currentAccountId, log['word'], isCorrect);

    final provider = Provider.of<DictationProvider>(context, listen: false);
    if (!provider.scoreLog.any((l) => l['needs_manual'] == true)) {
      Future.delayed(const Duration(milliseconds: 500), _goToResults);
    }
  }

  void _goToResults() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ResultsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DictationProvider>(context);
    final items = provider.scoreLog.where((l) => l['needs_manual'] == true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(title: const Text('人工判定', style: TextStyle(color: Colors.amber))),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => _markAll(false), child: const Text('剩余全错', style: TextStyle(color: Colors.redAccent))),
              TextButton(onPressed: () => _markAll(true), child: const Text('剩余全对', style: TextStyle(color: Colors.greenAccent))),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final log = items[index];
                return Card(
                  color: Colors.white10,
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("[${log['mode']}] ${log['q']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
                        const SizedBox(height: 8),
                        Text("你的输入: ${log['ans']}", style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("标准释义: ${(log['expected'] as List).join(', ')}", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent, size: 36),
                              onPressed: () => _markSingle(log, false),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.greenAccent, size: 36),
                              onPressed: () => _markSingle(log, true),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
