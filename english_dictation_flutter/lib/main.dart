import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';
import 'providers/dictation_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DictationProvider()),
      ],
      child: const EnglishDictationApp(),
    ),
  );
}

class EnglishDictationApp extends StatelessWidget {
  const EnglishDictationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Dictation',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
