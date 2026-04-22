import 'package:flutter/material.dart';

class DataBrowserScreen extends StatefulWidget {
  const DataBrowserScreen({super.key});

  @override
  State<DataBrowserScreen> createState() => _DataBrowserScreenState();
}

class _DataBrowserScreenState extends State<DataBrowserScreen> {
  // Mock data structure
  final List<BookData> _books = [
    BookData(
      name: '七年级上册',
      units: [
        UnitData(
          name: 'Unit 1 Making new friends',
          words: [
            WordData(word: 'good', translation: '好的', testedCount: 5, incorrectCount: 1),
            WordData(word: 'morning', translation: '早晨', testedCount: 3, incorrectCount: 0),
          ],
        ),
        UnitData(
          name: 'Unit 2 Looking different',
          words: [
            WordData(word: 'look', translation: '看', testedCount: 8, incorrectCount: 2),
            WordData(word: 'different', translation: '不同的', testedCount: 4, incorrectCount: 3),
          ],
        ),
      ],
    ),
    BookData(
      name: '七年级下册',
      units: [
        UnitData(
          name: 'Unit 5 Our School Life',
          words: [
            WordData(word: 'school', translation: '学校', testedCount: 10, incorrectCount: 1),
            WordData(word: 'life', translation: '生活', testedCount: 6, incorrectCount: 0),
          ],
        ),
      ],
    ),
  ];

  void _showFolderStats(BuildContext context, String folderName, int totalWords, int totalTested, int totalIncorrect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$folderName 统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('总单词数: $totalWords'),
            const SizedBox(height: 8),
            Text('总测试次数: $totalTested'),
            const SizedBox(height: 8),
            Text('总错误次数: $totalIncorrect'),
            const SizedBox(height: 8),
            Text('错误率: ${totalTested > 0 ? ((totalIncorrect / totalTested) * 100).toStringAsFixed(1) : 0}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showWordHistory(BuildContext context, WordData word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${word.word} 历史记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('释义: ${word.translation}'),
            const SizedBox(height: 16),
            Text('测试次数: ${word.testedCount}'),
            const SizedBox(height: 8),
            Text('错误次数: ${word.incorrectCount}'),
            const SizedBox(height: 16),
            const Text('近期记录:'),
            const SizedBox(height: 8),
            // Mock history
            if (word.testedCount > 0) ...[
              const Text('- 2023-10-01: 正确'),
              if (word.incorrectCount > 0) const Text('- 2023-09-28: 拼写错误'),
            ] else
              const Text('暂无测试记录'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据浏览'),
      ),
      body: ListView.builder(
        itemCount: _books.length,
        itemBuilder: (context, bookIndex) {
          final book = _books[bookIndex];
          int bookTotalWords = 0;
          int bookTotalTested = 0;
          int bookTotalIncorrect = 0;
          for (var unit in book.units) {
            bookTotalWords += unit.words.length;
            for (var word in unit.words) {
              bookTotalTested += word.testedCount;
              bookTotalIncorrect += word.incorrectCount;
            }
          }

          return ExpansionTile(
            leading: const Icon(Icons.book),
            title: Text(book.name),
            subtitle: Text('测$bookTotalTested次·错$bookTotalIncorrect次'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showFolderStats(context, book.name, bookTotalWords, bookTotalTested, bookTotalIncorrect),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
            children: book.units.map((unit) {
              int unitTotalTested = 0;
              int unitTotalIncorrect = 0;
              for (var word in unit.words) {
                unitTotalTested += word.testedCount;
                unitTotalIncorrect += word.incorrectCount;
              }

              return ExpansionTile(
                tilePadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                leading: const Icon(Icons.folder_open),
                title: Text(unit.name),
                subtitle: Text('测$unitTotalTested次·错$unitTotalIncorrect次'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showFolderStats(context, unit.name, unit.words.length, unitTotalTested, unitTotalIncorrect),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
                children: unit.words.map((word) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 64.0, right: 16.0),
                    title: Text(word.word),
                    subtitle: Text(word.translation),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '测${word.testedCount}次·错${word.incorrectCount}次',
                          style: TextStyle(
                            color: word.incorrectCount > 0 ? Colors.red : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.history, size: 20),
                      ],
                    ),
                    onTap: () => _showWordHistory(context, word),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// Data Models
class BookData {
  final String name;
  final List<UnitData> units;

  BookData({required this.name, required this.units});
}

class UnitData {
  final String name;
  final List<WordData> words;

  UnitData({required this.name, required this.words});
}

class WordData {
  final String word;
  final String translation;
  final int testedCount;
  final int incorrectCount;

  WordData({
    required this.word,
    required this.translation,
    required this.testedCount,
    required this.incorrectCount,
  });
}
