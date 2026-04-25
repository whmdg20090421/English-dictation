import 'package:flutter/material.dart';
import '../theme.dart';
import '../app_state.dart';
import '../components/cloud_status_indicator.dart';
import 'dictation/selection_screen.dart';
import '../db/data_manager.dart';
import '../utils/dialogs.dart';
import 'data_browser_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await DataManager.instance.loadLocalDataOnly();
      AppState.instance.init();
      if (mounted) setState(() {});
      
      // Now sync with cloud in background
      await DataManager.instance.syncWithCloud();
    } catch (e, stack) {
      debugPrint('Error in _loadData: $e\n$stack');
      if (DataManager.instance.accounts.isEmpty) {
        DataManager.instance.accounts['default'] = {
          "name": "默认账户",
          "role": "admin",
          "history": [],
          "stats": {},
          "settings": {
            "allow_backward": true,
            "allow_hint": false,
            "timer_lock": true,
            "per_q_time": 20.0,
            "hide_test_config": false,
            "hint_delay": 5,
            "hint_limit": 0,
            "folders": []
          }
        };
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showAccountSwitch() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          final accounts = DataManager.instance.accounts;
          final currentAccId = AppState.instance.currentAccountId;

          return AlertDialog(
            backgroundColor: AppTheme.secondaryBlue.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: AppTheme.glassBorder, width: 1),
            ),
            title: const Text('切换或管理账户', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final accId = accounts.keys.elementAt(index);
                        final acc = accounts[accId];
                        final isCurrent = accId == currentAccId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: isCurrent ? Colors.green : Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${acc['name'] ?? ''} ${acc['role'] == 'admin' ? '[管理员]' : '[普通]'}',
                                  style: TextStyle(
                                    color: isCurrent ? Colors.blue[300] : Colors.white,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrent)
                                const Text('当前', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                                onPressed: () {
                                  DialogUtils.requirePassword(context, () {
                                    DialogUtils.promptDialog(context, '重命名账户', '新账户名', acc['name'], (newName) {
                                      if (newName.isNotEmpty && newName != acc['name']) {
                                        acc['name'] = newName;
                                        DataManager.instance.saveData().then((_) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text('已重命名为: $newName'), backgroundColor: Colors.green));
                                            setStateDialog(() {});
                                            setState(() {});
                                          }
                                        });
                                      }
                                    });
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                onPressed: () {
                                  if (accounts.length <= 1) {
                                    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(const SnackBar(content: Text('这是系统中最后一个账户，无法删除！请先创建新账户。'), backgroundColor: Colors.orange));
                                    return;
                                  }
                                  DialogUtils.requirePassword(context, () {
                                    DialogUtils.multiActionDialog(context, '危险操作', '确定要彻底删除账户 [${acc['name']}] 吗？此操作不可逆！', [
                                      {'label': '取消', 'color': Colors.grey, 'callback': () {}},
                                      {'label': '确认删除', 'color': Colors.red, 'callback': () {
                                        accounts.remove(accId);
                                        if (isCurrent) {
                                          AppState.instance.currentAccountId = accounts.keys.first;
                                        }
                                        DataManager.instance.saveData().then((_) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text('账户 [${acc['name']}] 已彻底删除'), backgroundColor: Colors.green));
                                            setStateDialog(() {});
                                            setState(() {});
                                          }
                                        });
                                      }},
                                    ]);
                                  });
                                },
                              ),
                              if (!isCurrent)
                                ElevatedButton(
                                  onPressed: () {
                                    DialogUtils.requirePassword(context, () {
                                      AppState.instance.currentAccountId = accId;
                                      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text('已切换至账户: ${acc['name']}'), backgroundColor: Colors.green));
                                      Navigator.pop(context);
                                      setState(() {});
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                                  child: const Text('切换', style: TextStyle(color: Colors.white)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      DialogUtils.requirePassword(context, () {
                        DialogUtils.promptAccountDialog(context, (name, role) {
                          if (name.isNotEmpty) {
                            final newId = DateTime.now().millisecondsSinceEpoch.toString();
                            final baseSettings = DataManager.instance.getAcc("default")["settings"] ?? {};
                            DataManager.instance.accounts[newId] = {
                              "name": name,
                              "role": role,
                              "history": [],
                              "stats": {},
                              "settings": Map.from(baseSettings)
                            };
                            DataManager.instance.saveData().then((_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text('账户 $name ($role) 已创建'), backgroundColor: Colors.green));
                                setStateDialog(() {});
                                setState(() {});
                              }
                            });
                          }
                        });
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+ 新建账户 (需验密)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _startMistakes() {
    final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
    final myStats = currentAcc['stats'] ?? {};
    
    List<Map<String, dynamic>> mistakes = [];
    final allWords = DataManager.getAllWords(DataManager.instance.vocab);
    
    for (var meta in allWords) {
      final word = meta['单词'] ?? meta['word'];
      if (word != null && myStats[word] != null && myStats[word]['wrong'] > 0) {
        mistakes.add(meta);
      }
    }
    
    if (mistakes.isEmpty) {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(const SnackBar(content: Text('太棒了，当前账户没有错题记录！'), backgroundColor: Colors.green));
      return;
    }
    
    // Implement mistakes selection dialog
    showDialog(
      context: context,
      builder: (context) {
        bool selectAll = true;
        Map<String, bool> selectedMap = { for (var m in mistakes) m['_uid']: true };
        
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.secondaryBlue.withOpacity(0.9),
            title: Text('选择错题 (共 ${mistakes.length} 题)', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('默认全选', style: TextStyle(color: Colors.grey)),
                      Switch(
                        value: selectAll,
                        onChanged: (val) {
                          setStateDialog(() {
                            selectAll = val;
                            for (var key in selectedMap.keys) {
                              selectedMap[key] = val;
                            }
                          });
                        },
                      )
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: mistakes.length,
                      itemBuilder: (context, index) {
                        final m = mistakes[index];
                        final word = m['单词'] ?? m['word'];
                        final wrongCount = myStats[word]?['wrong'] ?? 0;
                        
                        return CheckboxListTile(
                          title: Text(word, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('错 $wrongCount 次', style: const TextStyle(color: Colors.redAccent)),
                          value: selectedMap[m['_uid']],
                          onChanged: (val) {
                            setStateDialog(() {
                              selectedMap[m['_uid']] = val ?? false;
                              selectAll = selectedMap.values.every((v) => v);
                            });
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () {
                  final selected = mistakes.where((m) => selectedMap[m['_uid']] == true).toList();
                  if (selected.isEmpty) {
                    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(const SnackBar(content: Text('请至少选择一题'), backgroundColor: Colors.orange));
                    return;
                  }
                  AppState.instance.selectedWords = selected;
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectionScreen()));
                },
                child: const Text('确认'),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (DataManager.instance.accounts.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                '正在同步数据，请稍候...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final currentAcc = DataManager.instance.getAcc(AppState.instance.currentAccountId);
    final myHistory = currentAcc['history'] as List? ?? [];
    final myStats = currentAcc['stats'] as Map<String, dynamic>? ?? {};
    
    int totalTests = myHistory.length;
    int totalPracticed = 0;
    int totalCorrect = 0;
    
    for (var s in myStats.values) {
      totalPracticed += (s['total'] as int? ?? 0);
      totalCorrect += (s['correct'] as int? ?? 0);
    }
    
    int acc = totalPracticed > 0 ? ((totalCorrect / totalPracticed) * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: const CloudStatusIndicator(),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: _showAccountSwitch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currentAcc['name'] ?? '', style: TextStyle(color: Colors.blue[300], fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.manage_accounts, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            ),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text('移动端听写系统', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryBlue.withOpacity(0.5),
                        border: Border.all(color: AppTheme.glassBorder),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(totalTests.toString(), '听写次数'),
                          _buildStatColumn(totalPracticed.toString(), '练词数'),
                          _buildStatColumn('$acc%', '正确率'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: () {
                        if (DataManager.instance.vocab.isEmpty) {
                          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(const SnackBar(content: Text('暂无词库请先导入'), backgroundColor: Colors.orange));
                          return;
                        }
                        AppState.instance.selectedWords = []; // clear to use all words
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectionScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DataManager.instance.vocab.isEmpty ? Colors.grey[600] : Colors.green[500],
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('开始听写', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _startMistakes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('错题本重练', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DataBrowserScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('专属数据详情', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: () {
                        DialogUtils.requirePassword(context, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBlue.withOpacity(0.5),
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: AppTheme.glassBorder),
                        ),
                      ),
                      child: const Text('系统管理后台', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[300])),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
