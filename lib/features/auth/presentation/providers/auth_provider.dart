import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/config/rate_limit_config.dart';
import '../../../../core/utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  supabase.User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _onboardingCompleted = false;
  bool _onboardingLoaded = false;
  bool _authLoaded = false;
  late final StreamSubscription<supabase.AuthState> _authSubscription;

  AuthProvider(this._authRepository) {
    _user = _authRepository.currentUser;
    _loadOnboardingStatus();
    _authSubscription = _authRepository.onAuthStateChanged.listen((data) {
      _user = data.session?.user;
      _authLoaded = true;
      _checkInitialization();
    });
  }

  void _checkInitialization() {
    if (_authLoaded && _onboardingLoaded) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadOnboardingStatus() async {
    try {
      const storage = FlutterSecureStorage();
      final val = await storage.read(key: 'onboarding_completed');
      _onboardingCompleted = val == 'true';
    } catch (_) {
      _onboardingCompleted = false;
    } finally {
      _onboardingLoaded = true;
      _checkInitialization();
    }
  }

  void completeOnboarding() {
    _onboardingCompleted = true;
    notifyListeners();
  }

  supabase.User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  DateTime? get lockoutUntil => _lockoutUntil;

  Future<bool> signInWithGoogle() async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final secondsLeft = _lockoutUntil!.difference(DateTime.now()).inSeconds + 1;
      _errorMessage = 'Too many attempts. Please try again in $secondsLeft seconds.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    final result = await _authRepository.signInWithGoogle();

    return result.fold(
      onSuccess: (user) {
        _user = user;
        _failedAttempts = 0;
        _lockoutUntil = null;
        _setLoading(false);
        return true;
      },
      onFailure: (failure) {
        SecureLogger.logError('signInWithGoogle failed', failure.message);
        _failedAttempts++;
        if (_failedAttempts >= RateLimitConfig.authMaxFailedAttempts) {
          final factor = 1 << (_failedAttempts - RateLimitConfig.authMaxFailedAttempts);
          final backoffMs = min(
            RateLimitConfig.authBaseBackoffMs * factor,
            RateLimitConfig.authMaxBackoffMs,
          );
          _lockoutUntil = DateTime.now().add(Duration(milliseconds: backoffMs));
          final seconds = (backoffMs / 1000).round();
          _errorMessage = 'Too many attempts. Locked out for $seconds seconds.';
        } else {
          _errorMessage = SecureLogger.sanitizeException(failure.message);
        }
        _setLoading(false);
        return false;
      },
    );
  }

  Future<bool> signInWithDemoUser() async {
    _setLoading(true);
    _clearError();

    await Future.delayed(const Duration(milliseconds: 600));

    _user = const supabase.User(
      id: 'demo-guest-athlete-id',
      appMetadata: {},
      userMetadata: {
        'full_name': 'Gerex Athlete',
        'avatar_url': null,
      },
      aud: 'authenticated',
      email: 'athlete@gerex.com',
      createdAt: '',
    );

    _setLoading(false);
    return true;
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    final result = await _authRepository.signOut();

    result.fold(
      onSuccess: (_) {
        _user = null;
        _failedAttempts = 0;
        _lockoutUntil = null;
        _setLoading(false);
      },
      onFailure: (failure) {
        SecureLogger.logError('signOut failed', failure.message);
        _errorMessage = SecureLogger.sanitizeException(failure.message);
        _setLoading(false);
      },
    );
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
