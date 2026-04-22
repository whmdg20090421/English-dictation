import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictation_provider.dart';
import 'manual_grade_screen.dart';
import 'results_screen.dart';

class InterimReportScreen extends StatelessWidget {
  const InterimReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DictationProvider>(context, listen: false);
    final total = provider.scoreLog.length;
    final autoCorrect = provider.scoreLog.where((l) => l['correct'] == true).length;
    final needsManual = provider.scoreLog.where((l) => l['needs_manual'] == true).length;
    final usedHints = provider.usedHints.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('听写汇报', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 30),
              Card(
                color: Colors.white10,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text('总题目数: $total', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('自动判对: $autoCorrect', style: const TextStyle(fontSize: 22, color: Colors.greenAccent)),
                      const SizedBox(height: 10),
                      Text('提示使用: $usedHints 次', style: const TextStyle(fontSize: 22, color: Colors.grey)),
                      const SizedBox(height: 20),
                      if (needsManual > 0)
                        Text('待人工判定: $needsManual', style: const TextStyle(fontSize: 24, color: Colors.amber, fontWeight: FontWeight.bold))
                      else
                        const Text('所有题目已自动批改完毕！', style: TextStyle(fontSize: 20, color: Colors.lightBlueAccent)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (needsManual > 0)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 60)),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('进行人工判定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManualGradeScreen()));
                  },
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 60)),
                  icon: const Icon(Icons.analytics),
                  label: const Text('查看最终成绩', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ResultsScreen()));
                  },
                )
            ],
          ),
        ),
      ),
    );
  }
}
