import 'package:flutter/material.dart';
import '../theme.dart';
import '../app_state.dart';
import '../db/data_manager.dart';

class DataBrowserScreen extends StatefulWidget {
  const DataBrowserScreen({super.key});

  @override
  State<DataBrowserScreen> createState() => _DataBrowserScreenState();
}

class _DataBrowserScreenState extends State<DataBrowserScreen> {
  late Map<String, dynamic> _currentAcc;
  late Map<String, dynamic> _myStats;
  late List<dynamic> _myHistory;

  @override
  void initState() {
    super.initState();
    _currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
    _myStats = _currentAcc['stats'] ?? {};
    _myHistory = _currentAcc['history'] ?? [];
  }

  Set<String> _getAllWordsInNode(Map<String, dynamic> nodeDict) {
    Set<String> words = {};
    for (var data in nodeDict.values) {
      if (data['_units'] != null) {
        final units = data['_units'] as Map<String, dynamic>;
        for (var uWords in units.values) {
          for (var meta in (uWords as Map<String, dynamic>).values) {
            words.add(meta['单词'] ?? '');
          }
        }
      }
      if (data['children'] != null) {
        words.addAll(_getAllWordsInNode(data['children']));
      }
    }
    return words;
  }

  void _showFolderStats(String title, Set<String> wordSet) {
    if (wordSet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该目录下没有有效单词'), backgroundColor: Colors.orange));
      return;
    }

    int fTotal = 0, fCorrect = 0, fWrong = 0;
    for (var w in wordSet) {
      final st = _myStats[w] ?? {};
      fTotal += (st['total'] as int? ?? 0);
      fCorrect += (st['correct'] as int? ?? 0);
      fWrong += (st['wrong'] as int? ?? 0);
    }

    List<Map<String, dynamic>> involvedHistory = [];
    for (var sess in _myHistory.reversed) {
      final details = sess['details'] as List? ?? [];
      final matchDetails = details.where((d) => wordSet.contains(d['word'])).toList();
      
      if (matchDetails.isNotEmpty) {
        int sessC = matchDetails.where((d) => d['correct'] == true).length;
        int sessW = matchDetails.length - sessC;
        involvedHistory.add({
          'time': sess['timestamp'],
          'involved_count': matchDetails.length,
          'correct': sessC,
          'wrong': sessW,
          'words': matchDetails.map((d) => d['word'].toString()).toList(),
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlue.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppTheme.glassBorder)),
          title: Text(title, style: const TextStyle(color: Colors.amberAccent, fontSize: 20, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('涉及词量: ${wordSet.length}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      Text('总听写频次: $fTotal', style: TextStyle(color: Colors.blue[300], fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('对 $fCorrect / 错 $fWrong', style: const TextStyle(color: Colors.greenAccent, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('包含此目录单词的历史会话', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(
                  child: involvedHistory.isEmpty
                      ? const Text('未找到听写记录', style: TextStyle(color: Colors.grey))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: involvedHistory.length,
                          itemBuilder: (context, index) {
                            final h = involvedHistory[index];
                            return ExpansionTile(
                              title: Text("\${h['time']} (抽查 \${h['involved_count']} 词)", style: const TextStyle(color: Colors.white, fontSize: 14)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("对 \${h['correct']} | 错 \${h['wrong']}", style: TextStyle(color: Colors.purple[300], fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text((h['words'] as List).join(', '), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭', style: TextStyle(color: Colors.grey))),
          ],
        );
      },
    );
  }

  void _showWordStats(String word) {
    final st = _myStats[word] ?? {};
    final hList = st['history'] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlue.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppTheme.glassBorder)),
          title: Text(word, style: TextStyle(color: Colors.purple[400], fontSize: 24, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("总次: \${st['total'] ?? 0}", style: TextStyle(color: Colors.blue[300], fontSize: 14)),
                      Text("对: \${st['correct'] ?? 0}", style: const TextStyle(color: Colors.greenAccent, fontSize: 14)),
                      Text("错: \${st['wrong'] ?? 0}", style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text("累计用时: \${st['cumulative_seconds'] ?? 0} 秒", style: TextStyle(color: Colors.yellow[300], fontSize: 12)),
                const SizedBox(height: 16),
                const Text('精确历史流水 (最近 50 条)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(
                  child: hList.isEmpty
                      ? const Text('该单词尚无听写记录', style: TextStyle(color: Colors.grey))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: hList.length > 50 ? 50 : hList.length,
                          itemBuilder: (context, index) {
                            final h = hList[hList.length - 1 - index];
                            final isCorrect = h['result'] == '对';
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(h['time'] ?? '未知时间', style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace')),
                                  Row(
                                    children: [
                                      Text(h['result'] ?? '', style: TextStyle(color: isCorrect ? Colors.greenAccent : Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.greenAccent : Colors.redAccent, size: 16),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭', style: TextStyle(color: Colors.grey))),
          ],
        );
      },
    );
  }

  Widget _buildTree(Map<String, dynamic> tree) {
    List<Widget> nodes = [];
    tree.forEach((name, data) {
      final bookPath = data['_book_path'] as String;
      final children = data['children'] as Map<String, dynamic>;
      final units = data['_units'] as Map<String, dynamic>;

      nodes.add(
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(bookPath),
            initiallyExpanded: AppState.instance.browserExpandedPaths.contains(bookPath),
            onExpansionChanged: (val) {
              if (val) AppState.instance.browserExpandedPaths.add(bookPath);
              else AppState.instance.browserExpandedPaths.remove(bookPath);
            },
            title: Text(name, style: const TextStyle(color: Colors.white)),
            leading: const Icon(Icons.folder, color: Colors.white),
            trailing: IconButton(
              icon: const Icon(Icons.info, color: Colors.yellow),
              onPressed: () => _showFolderStats("目录聚合: $bookPath", _getAllWordsInNode({name: data})),
            ),
            children: [
              if (children.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: _buildTree(children),
                ),
              ...units.entries.map((uEntry) {
                final unitName = uEntry.key;
                final words = uEntry.value as Map<String, dynamic>;
                final unitPath = "$bookPath:::$unitName";

                return ExpansionTile(
                  key: PageStorageKey(unitPath),
                  initiallyExpanded: AppState.instance.browserExpandedPaths.contains(unitPath),
                  onExpansionChanged: (val) {
                    if (val) AppState.instance.browserExpandedPaths.add(unitPath);
                    else AppState.instance.browserExpandedPaths.remove(unitPath);
                  },
                  title: Text(unitName, style: const TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.description, color: Colors.purpleAccent),
                  trailing: IconButton(
                    icon: const Icon(Icons.info, color: Colors.yellow),
                    onPressed: () {
                      Set<String> uWordSet = words.values.map((m) => (m['单词'] ?? '').toString()).toSet();
                      _showFolderStats("单词集: $unitName", uWordSet);
                    },
                  ),
                  children: words.values.map((meta) {
                    final wordTxt = meta['单词'] ?? '';
                    final st = _myStats[wordTxt] ?? {};
                    final totalC = st['total'] ?? 0;
                    final wrongC = st['wrong'] ?? 0;

                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 48, right: 16),
                      title: Text(wordTxt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: totalC > 0
                          ? Text("测\${totalC}次 · 错\${wrongC}次", style: TextStyle(color: wrongC > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 12))
                          : const Text('未测试', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.info, color: Colors.blueAccent),
                        onPressed: () => _showWordStats(wordTxt),
                      ),
                    );
                  }).toList(),
                );
              }).toList()
            ],
          ),
        ),
      );
    });

    return Column(children: nodes);
  }

  @override
  Widget build(BuildContext context) {
    if (DataManager.instance.vocab.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: Text("[\${_currentAcc['name']}] 数据追踪", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: Text('词库为空，无法呈现数据', style: TextStyle(color: Colors.grey, fontSize: 16))),
      );
    }

    // Build tree map
    Map<String, dynamic> tree = {};
    DataManager.instance.vocab.forEach((bookPath, units) {
      final parts = bookPath.split('/');
      Map<String, dynamic> curr = tree;
      List<String> pathSoFar = [];
      for (var p in parts) {
        pathSoFar.add(p);
        if (!curr.containsKey(p)) {
          curr[p] = {'_units': {}, '_book_path': pathSoFar.join('/'), 'children': <String, dynamic>{}};
        }
        curr = curr[p]['children'];
      }
    });

    DataManager.instance.vocab.forEach((bookPath, units) {
      final parts = bookPath.split('/');
      Map<String, dynamic> curr = tree;
      for (int i = 0; i < parts.length - 1; i++) {
        curr = curr[parts[i]]['children'];
      }
      curr[parts.last]['_units'] = units;
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("[\${_currentAcc['name']}] 数据追踪", style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildTree(tree),
      ),
    );
  }
}
