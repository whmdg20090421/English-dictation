import 'package:flutter/material.dart';
import '../theme.dart';
import '../db/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _refreshAccounts();
  }

  Future<void> _refreshAccounts() async {
    final data = await DatabaseHelper.instance.getAccounts();
    setState(() {
      _accounts = data;
      _isLoading = false;
      if (_accounts.isNotEmpty && _selectedAccountId == null) {
        _selectedAccountId = _accounts.first['id'];
      } else if (_accounts.isEmpty) {
        _selectedAccountId = null;
      }
    });
  }

  Future<void> _addAccount() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlue,
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter account name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await DatabaseHelper.instance.createAccount(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                }
                _refreshAccounts();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(int id) async {
    await DatabaseHelper.instance.deleteAccount(id);
    if (_selectedAccountId == id) {
      _selectedAccountId = null;
    }
    _refreshAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('English Dictation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addAccount,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Accounts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  if (_accounts.isEmpty)
                    const GlassContainer(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No accounts found.\nPlease create one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _accounts.length,
                        itemBuilder: (context, index) {
                          final account = _accounts[index];
                          final isSelected = account['id'] == _selectedAccountId;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAccountId = account['id'];
                              });
                            },
                            child: GlassContainer(
                              margin: const EdgeInsets.only(right: 16),
                              width: 150,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 32,
                                    color: isSelected ? AppTheme.accentCyan : Colors.white54,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    account['name'],
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.accentCyan : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isSelected) ...[
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _deleteAccount(account['id']),
                                      child: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                                    )
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: _selectedAccountId == null
                          ? const Center(
                              child: Text(
                                'Select an account to view dashboard',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.analytics, size: 64, color: AppTheme.accentCyan),
                                const SizedBox(height: 16),
                                Text(
                                  'Welcome back!',
                                  style: Theme.of(context).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ready for your daily dictation?',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Start dictation
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start Session'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(200, 50),
                                  ),
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
}
