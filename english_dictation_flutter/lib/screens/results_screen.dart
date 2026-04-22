import 'package:flutter/material.dart';

class ResultsScreen extends StatefulWidget {
  final List<String> targetSentences;
  final List<String> userAnswers;
  final int totalSeconds;

  const ResultsScreen({
    Key? key,
    required this.targetSentences,
    required this.userAnswers,
    required this.totalSeconds,
  }) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late List<bool> _isCorrectList;
  late List<String> _manualGrades; // 'Correct', 'Incorrect', 'Partial'

  @override
  void initState() {
    super.initState();
    _calculateGrades();
  }

  void _calculateGrades() {
    _isCorrectList = [];
    _manualGrades = [];
    for (int i = 0; i < widget.targetSentences.length; i++) {
      String target = widget.targetSentences[i].trim().toLowerCase();
      String answer = widget.userAnswers.length > i ? widget.userAnswers[i].trim().toLowerCase() : "";
      
      // 简单的字符串匹配评分逻辑
      bool correct = target == answer;
      _isCorrectList.add(correct);
      _manualGrades.add(correct ? "Correct" : "Incorrect");
    }
  }

  void _showManualGradeModal(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Manual Grade for Q${index + 1}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text("Correct"),
                leading: const Icon(Icons.check, color: Colors.green),
                onTap: () {
                  setState(() {
                    _manualGrades[index] = "Correct";
                    _isCorrectList[index] = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Partial Correct"),
                leading: const Icon(Icons.warning, color: Colors.orange),
                onTap: () {
                  setState(() {
                    _manualGrades[index] = "Partial";
                    _isCorrectList[index] = false; // 按部分正确处理，可根据需求调整
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Incorrect"),
                leading: const Icon(Icons.close, color: Colors.red),
                onTap: () {
                  setState(() {
                    _manualGrades[index] = "Incorrect";
                    _isCorrectList[index] = false;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int get _score {
    return _isCorrectList.where((element) => element).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dictation Results"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Final Score: $_score / ${widget.targetSentences.length}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Total Time: ${widget.totalSeconds} seconds",
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.targetSentences.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text("Target: ${widget.targetSentences[index]}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Your Answer: ${widget.userAnswers.length > index ? widget.userAnswers[index] : ''}"),
                          Text(
                            "Status: ${_manualGrades[index]}",
                            style: TextStyle(
                              color: _manualGrades[index] == 'Correct'
                                  ? Colors.green
                                  : _manualGrades[index] == 'Partial'
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showManualGradeModal(index),
                        tooltip: "Manual Grade",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
