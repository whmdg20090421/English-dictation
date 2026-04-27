import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeModeType _themeMode = ThemeModeType.dark;
  ThemeModeType get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('app_theme');
    if (savedTheme != null) {
      _themeMode = ThemeModeType.values.firstWhere((e) => e.name == savedTheme, orElse: () => ThemeModeType.dark);
      notifyListeners();
    }
  }

  Future<void> setTheme(ThemeModeType mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', mode.name);
  }

  ThemeData get currentThemeData {
    switch (_themeMode) {
      case ThemeModeType.light:
        return AppTheme.lightTheme;
      case ThemeModeType.dark:
        return AppTheme.darkTheme;
      case ThemeModeType.cyberpunk:
        return AppTheme.cyberpunkTheme;
    }
  }
}

enum ThemeModeType { light, dark, cyberpunk }

class AppTheme {
  // Dark colors (existing)
  static const Color primaryBlue = Color(0xFF0A192F);
  static const Color secondaryBlue = Color(0xFF112240);
  static const Color accentCyan = Color(0xFF64FFDA);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // Cyberpunk colors
  static const Color cyberBackground = Color(0xFF0D0221); // Deep dark purple/blue
  static const Color cyberSurface = Color(0xFF1A0B2E);
  static const Color cyberNeonPink = Color(0xFFFF007F);
  static const Color cyberNeonCyan = Color(0xFF00F0FF);
  static const Color cyberNeonYellow = Color(0xFFFEE715);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.black54,
        indicatorColor: Colors.blue,
      ),
      colorScheme: const ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.blueAccent,
        surface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.1),
          foregroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.blue),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white70,
        elevation: 0,
        centerTitle: true,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        indicatorColor: Colors.white,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Colors.black,
        secondary: Colors.white70,
        surface: Color(0xFF111111),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white60),
      ),
    );
  }

  static ThemeData get cyberpunkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: cyberBackground,
      scaffoldBackgroundColor: Colors.transparent, // Background will be handled by a Container with gradient
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: cyberNeonCyan,
        elevation: 0,
        centerTitle: true,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: cyberNeonCyan,
        unselectedLabelColor: cyberNeonPink,
        indicatorColor: cyberNeonCyan,
      ),
      colorScheme: const ColorScheme.dark(
        primary: cyberNeonCyan,
        secondary: cyberNeonPink,
        surface: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cyberSurface.withOpacity(0.6),
        elevation: 8,
        shadowColor: cyberNeonCyan.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cyberNeonCyan, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyberNeonCyan.withOpacity(0.2),
          foregroundColor: cyberNeonCyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: cyberNeonCyan, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: cyberNeonCyan, fontWeight: FontWeight.bold, shadows: [Shadow(color: cyberNeonCyan, blurRadius: 10)]),
        titleLarge: TextStyle(color: cyberNeonCyan, fontWeight: FontWeight.w600, shadows: [Shadow(color: cyberNeonCyan, blurRadius: 5)]),
        bodyLarge: TextStyle(color: cyberNeonCyan),
        bodyMedium: TextStyle(color: cyberNeonCyan),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: cyberNeonCyan),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: cyberNeonCyan)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: cyberNeonPink, width: 2)),
      ),
    );
  }
}

// Glassmorphism Widget Utility
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
