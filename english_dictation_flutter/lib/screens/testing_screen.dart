import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'results_screen.dart';

class TestingScreen extends StatefulWidget {
  final List<String> targetSentences;

  const TestingScreen({Key? key, required this.targetSentences}) : super(key: key);

  @override
  _TestingScreenState createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  int _currentIndex = 0;
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  // Timers
  Timer? _totalTimer;
  Timer? _questionTimer;
  int _totalSeconds = 0;
  int _questionSeconds = 0;

  List<String> _userAnswers = [];
  String _currentHint = "";

  @override
  void initState() {
    super.initState();
    _initTts();
    _startTimers();
    _textController.addListener(_onTextChanged);
    // 延迟播放第一个句子的发音
    Future.delayed(const Duration(milliseconds: 500), () => _speakCurrent());
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  void _startTimers() {
    _totalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalSeconds++;
      });
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _questionSeconds++;
      });
    });
  }

  void _resetQuestionTimer() {
    setState(() {
      _questionSeconds = 0;
    });
  }

  @override
  void dispose() {
    _totalTimer?.cancel();
    _questionTimer?.cancel();
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakCurrent() async {
    if (_currentIndex < widget.targetSentences.length) {
      await _flutterTts.speak(widget.targetSentences[_currentIndex]);
    }
  }

  void _onTextChanged() {
    String currentInput = _textController.text;
    String target = widget.targetSentences[_currentIndex];

    // LCP-based hint system (Longest Common Prefix)
    int lcpLength = 0;
    int minLength = currentInput.length < target.length ? currentInput.length : target.length;

    for (int i = 0; i < minLength; i++) {
      if (currentInput[i].toLowerCase() == target[i].toLowerCase()) {
        lcpLength++;
      } else {
        break;
      }
    }

    setState(() {
      if (lcpLength < target.length) {
        // 如果用户输入卡住或者错误，给出下一个正确的字符作为提示
        _currentHint = "Next char: '${target[lcpLength]}'";
      } else {
        _currentHint = "Perfect match!";
      }
    });
  }

  void _nextQuestion() {
    _userAnswers.add(_textController.text);
    
    if (_currentIndex < widget.targetSentences.length - 1) {
      setState(() {
        _currentIndex++;
        _textController.clear();
        _currentHint = "";
      });
      _resetQuestionTimer();
      _speakCurrent();
    } else {
      // 听写结束，跳转到结果页面
      _totalTimer?.cancel();
      _questionTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            targetSentences: widget.targetSentences,
            userAnswers: _userAnswers,
            totalSeconds: _totalSeconds,
          ),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetSentences.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Dictation Testing")),
        body: const Center(child: Text("No sentences available.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dictation Testing"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Total Time: ${_formatTime(_totalSeconds)}",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Question ${_currentIndex + 1} of ${widget.targetSentences.length}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Q-Time: ${_formatTime(_questionSeconds)}",
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _speakCurrent,
              icon: const Icon(Icons.volume_up),
              label: const Text("Play Pronunciation"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Type what you hear",
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Text(
              "Hint: $_currentHint",
              style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                _currentIndex < widget.targetSentences.length - 1 ? "Next" : "Finish",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
