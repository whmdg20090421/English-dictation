import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictation_provider.dart';
import '../../db/data_manager.dart';
import '../../app_state.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DictationProvider>(context, listen: false);
    final total = provider.scoreLog.length;
    final totalScoreVal = provider.scoreLog.fold(0.0, (sum, l) => sum + (l['score_val'] ?? (l['correct'] ? 1.0 : 0.0)));
    final score = total > 0 ? ((totalScoreVal / total) * 100).toInt() : 0;
    final usedHints = provider.usedHints.length;

    // Save to DB or handle history can be added here if needed
    if (!provider.resultSaved) {
      provider.resultSaved = true;
      final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
      currentAcc.putIfAbsent('history', () => []);
      (currentAcc['history'] as List).add({
        "timestamp": DateTime.now().toString(),
        "mode": provider.testMode,
        "score": score,
        "total": total,
        "correct": totalScoreVal,
        "score_val": totalScoreVal,
        "used_hints": usedHints,
        "status": "已完成",
        "details": provider.scoreLog
      });
      
      for (var log in provider.scoreLog) {
        if (!log['needs_manual']) {
          DataManager.instance.updateWordStats(AppState.instance.currentAccountId, log['word'], log['correct']);
        }
      }
      DataManager.instance.saveData();
    }

    final color = score >= 80 ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('测试完成', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              Text('$score分', style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 10),
              Text('使用提示: $usedHints次', style: const TextStyle(fontSize: 20, color: Colors.grey)),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  provider.reset();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('重新配置题型 / 返回主页', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
