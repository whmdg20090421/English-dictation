import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';
import 'providers/dictation_provider.dart';
import 'components/error_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _showGlobalError(String error, String stack) {
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'English Dictation',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
