import 'package:flutter/foundation.dart';

class SecureLogger {
  /// Safely logs details to internal debugging output.
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('=== SECURITY LOG ERROR ===');
      print('Context: $context');
      print('Error: $error');
      if (stackTrace != null) {
        print('StackTrace:\n$stackTrace');
      }
      print('===========================');
    }
  }

  /// Safely logs info details to debug print.
  static void logInfo(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  /// Sanitizes generic exception/error details to return a safe, UI-friendly message.
  static String sanitizeException(dynamic error) {
    final str = error.toString().toLowerCase();

    // Check rate limit errors
    if (str.contains('rate limit') || str.contains('429') || str.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    // Check network / timeout issues
    if (str.contains('socketexception') || str.contains('network') || str.contains('timeout') || str.contains('connection failed')) {
      return 'Network connection issue. Please check your internet and try again.';
    }

    // Check Supabase Auth specifics
    if (str.contains('google sign in failed')) {
      return 'Google sign in failed';
    }
    if (str.contains('invalid login credentials') || str.contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (str.contains('user already exists') || str.contains('email already registered')) {
      return 'This email address is already registered.';
    }

    // AI API key or Quota limits
    if (str.contains('gemini api error')) {
      return 'Gemini API error';
    }
    if (str.contains('api_key') || str.contains('quota exceeded') || str.contains('blocked') || str.contains('api key')) {
      return 'The AI Coach is currently busy. Please try again in a few minutes.';
    }

    // Default generic message
    return 'An unexpected error occurred. Please try again.';
  }
}
