import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  supabase.User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  late final StreamSubscription<supabase.AuthState> _authSubscription;

  AuthProvider(this._authRepository) {
    _user = _authRepository.currentUser;
    _authSubscription = _authRepository.onAuthStateChanged.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  supabase.User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    final result = await _authRepository.signInWithGoogle();

    return result.fold(
      onSuccess: (user) {
        _user = user;
        _setLoading(false);
        return true;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _setLoading(false);
        return false;
      },
    );
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    final result = await _authRepository.signOut();

    result.fold(
      onSuccess: (_) {
        _user = null;
        _setLoading(false);
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
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
