import 'dart:math';
import 'package:flutter/material.dart';

class DictationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> selectedWords = [];
  List<Map<String, dynamic>> testQueue = [];
  int currentQIndex = 0;
  
  Map<int, Map<String, dynamic>> userAnswers = {};
  List<Map<String, dynamic>> scoreLog = [];
  Set<int> usedHints = {};

  bool allowBackward = true;
  bool allowHint = false;
  double perQTime = 20.0;
  double totalTime = 0.0;
  double totLeft = 0.0;
  double qTimeLeft = 20.0;

  String testMode = "混合模式";
  bool isSubmitting = false;
  bool resultSaved = false;

  int accountId = 0;

  void reset() {
    selectedWords = [];
    testQueue = [];
    currentQIndex = 0;
    userAnswers = {};
    scoreLog = [];
    usedHints = {};
    totLeft = totalTime;
    qTimeLeft = perQTime;
    isSubmitting = false;
    resultSaved = false;
    notifyListeners();
  }

  void loadWords(List<Map<String, dynamic>> words) {
    selectedWords = words;
    notifyListeners();
  }

  void generateMixedTest(int spellingQty, int posQty, int translationQty) {
    testQueue.clear();
    List<Map<String, dynamic>> temp = [];

    if (spellingQty > 0) {
      temp.addAll(_sample(selectedWords, spellingQty).map((e) => {...e, '_test_mode': 'spelling'}));
    }
    if (posQty > 0) {
      temp.addAll(_sample(selectedWords, posQty).map((e) => {...e, '_test_mode': 'pos'}));
    }
    if (translationQty > 0) {
      temp.addAll(_sample(selectedWords, translationQty).map((e) => {...e, '_test_mode': 'translation'}));
    }

    testQueue = temp..shuffle();
    currentQIndex = 0;
    userAnswers.clear();
    scoreLog.clear();
    usedHints.clear();
    
    int totalQ = testQueue.length;
    if (totalQ == 0) totalQ = 1;
    totalTime = double.parse((perQTime * totalQ * 0.9).toStringAsFixed(1));
    totLeft = totalTime;
    qTimeLeft = perQTime;
    
    notifyListeners();
  }

  List<T> _sample<T>(List<T> list, int count) {
    if (list.isEmpty) return [];
    var random = Random();
    var result = <T>[];
    for (int i = 0; i < count; i++) {
      result.add(list[random.nextInt(list.length)]);
    }
    return result;
  }

  void tick() {
    if (isSubmitting) return;
    totLeft -= 1;
    qTimeLeft -= 1;
    notifyListeners();
  }

  void recordAnswerAndNext(bool isCorrect, String mode, String q, String ans, bool manual, List<String> expected, double scoreVal) {
    final word = testQueue[currentQIndex]['word'] as String;
    userAnswers[currentQIndex] = {
      "word": word,
      "mode": mode,
      "q": q,
      "ans": ans,
      "correct": isCorrect,
      "score_val": scoreVal,
      "needs_manual": manual,
      "expected": expected
    };

    if (currentQIndex < testQueue.length - 1) {
      currentQIndex++;
      qTimeLeft = perQTime;
    }
    notifyListeners();
  }
  
  void forceNext() {
    if (currentQIndex < testQueue.length - 1) {
      currentQIndex++;
      qTimeLeft = perQTime;
    }
    notifyListeners();
  }
  
  void forcePrev() {
    if (currentQIndex > 0 && allowBackward) {
      currentQIndex--;
      qTimeLeft = perQTime;
    }
    notifyListeners();
  }

  void submitTest() {
    scoreLog.clear();
    for (int i = 0; i < testQueue.length; i++) {
      var meta = testQueue[i];
      var word = meta["word"];
      if (userAnswers.containsKey(i)) {
        scoreLog.add(userAnswers[i]!);
      } else {
        var mode = meta['_test_mode'] ?? testMode;
        var qStr = word;
        var expected = [word.toString()];
        if (mode == 'translation') {
          qStr = word;
          expected = [meta['translation'] ?? ""];
        } else if (mode == 'spelling') {
          qStr = meta['translation'] ?? "";
          expected = [word];
        } else if (mode == 'pos') {
          qStr = word;
          expected = []; // simplification
        }
        
        scoreLog.add({
          "word": word,
          "mode": mode,
          "q": qStr,
          "ans": "跳过/未作答",
          "correct": false,
          "score_val": 0.0,
          "needs_manual": false,
          "expected": expected
        });
      }
    }
    notifyListeners();
  }

  void useHint() {
    usedHints.add(currentQIndex);
    notifyListeners();
  }
}
