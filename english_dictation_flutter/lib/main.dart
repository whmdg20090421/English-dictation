import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';
import 'providers/dictation_provider.dart';
import 'components/error_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _writeErrorLogToFile(String error, String stack) async {
  try {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    if (directory != null) {
      final file = File('${directory.path}/english_dictation_error_log.txt');
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '\n--- Error at $timestamp ---\n$error\n$stack\n';
      await file.writeAsString(logMessage, mode: FileMode.append);
      debugPrint('Error log written to ${file.path}');
    }
  } catch (e) {
    debugPrint('Failed to write error log: $e');
  }
}

void _showGlobalError(String error, String stack) {
  _writeErrorLogToFile(error, stack);
  final context = navigatorKey.currentContext;
  if (context != null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ErrorDialog(
          errorMessage: error,
          stackTrace: stack,
        );
      },
    );
  } else {
    debugPrint('Navigator context is null. Error: $error');
  }
}

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _showGlobalError(details.exceptionAsString(), details.stack.toString());
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _showGlobalError(error.toString(), stack.toString());
      return true;
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFF2C313C),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              const Text('渲染时发生错误', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showGlobalError(details.exceptionAsString(), details.stack.toString()),
                child: const Text('查看错误详情'),
              ),
            ],
          ),
        ),
      );
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DictationProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const EnglishDictationApp(),
      ),
    );
  }, (error, stack) {
    _showGlobalError(error.toString(), stack.toString());
  });
}

class EnglishDictationApp extends StatelessWidget {
  const EnglishDictationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'English Dictation',
          theme: themeProvider.currentThemeData,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            if (themeProvider.themeMode == ThemeModeType.cyberpunk) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D0221), // Deep dark purple
                      Color(0xFF1A0B2E), // Darker purple
                      Color(0xFF0F0014), // Almost black purple
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: child,
              );
            }
            return child!;
          },
        );
      },
    );
  }
}
