import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const EnglishDictationApp());
}

class EnglishDictationApp extends StatelessWidget {
  const EnglishDictationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Dictation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
