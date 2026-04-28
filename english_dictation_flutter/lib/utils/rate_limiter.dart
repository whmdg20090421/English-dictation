import 'package:shared_preferences/shared_preferences.dart';

class RateLimiter {
  static const int maxAttempts = 5;
  static const int lockoutMinutes = 15;
  static const String attemptsKey = 'auth_failed_attempts';
  static const String lockoutUntilKey = 'auth_lockout_until';

  static Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getInt(lockoutUntilKey);
    if (lockoutUntil != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < lockoutUntil) {
        return true; // Still locked out
      } else {
        // Lockout period expired
        await resetAttempts();
        return false;
      }
    }
    return false;
  }

  static Future<void> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    int attempts = prefs.getInt(attemptsKey) ?? 0;
    attempts += 1;
    await prefs.setInt(attemptsKey, attempts);

    if (attempts >= maxAttempts) {
      final lockoutUntil = DateTime.now().add(const Duration(minutes: lockoutMinutes)).millisecondsSinceEpoch;
      await prefs.setInt(lockoutUntilKey, lockoutUntil);
    }
  }

  static Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(attemptsKey);
    await prefs.remove(lockoutUntilKey);
  }

  static Future<String?> getLockoutRemainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getInt(lockoutUntilKey);
    if (lockoutUntil != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < lockoutUntil) {
        final remainingMs = lockoutUntil - now;
        final minutes = (remainingMs / (1000 * 60)).ceil();
        return '$minutes分钟';
      }
    }
    return null;
  }
}
