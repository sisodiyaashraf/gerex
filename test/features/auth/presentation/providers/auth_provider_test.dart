import 'package:flutter_test/flutter_test.dart';
import 'package:gerex/features/auth/presentation/providers/auth_provider.dart';
import 'package:gerex/features/auth/domain/repositories/auth_repository.dart';
import 'package:gerex/core/error/failures.dart';
import 'package:gerex/core/error/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository implements AuthRepository {
  bool shouldSucceed = true;
  User? mockUser;
  bool signOutCalled = false;

  @override
  Future<Result<User, Failure>> signInWithGoogle() async {
    if (shouldSucceed) {
      if (mockUser != null) {
        return Success(mockUser!);
      }
      return Success(
        const User(
          id: 'user_123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '',
        ),
      );
    } else {
      return const FailureResult(ServerFailure('Google sign in failed'));
    }
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    signOutCalled = true;
    return const Success(null);
  }

  @override
  User? get currentUser => mockUser;

  @override
  Stream<AuthState> get onAuthStateChanged => Stream.value(
        const AuthState(
          AuthChangeEvent.signedOut,
          null,
        ),
      );
}

void main() {
  group('AuthProvider Tests', () {
    late MockAuthRepository mockRepo;
    late AuthProvider authProvider;

    setUp(() {
      mockRepo = MockAuthRepository();
      authProvider = AuthProvider(mockRepo);
    });

    test('Initial state is correct', () {
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, null);
      expect(authProvider.user, null);
    });

    test('signInWithGoogle success sets user and clear error', () async {
      final success = await authProvider.signInWithGoogle();

      expect(success, true);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, null);
      expect(authProvider.user != null, true);
      expect(authProvider.user!.id, 'user_123');
    });

    test('signInWithGoogle failure sets error and loading false', () async {
      mockRepo.shouldSucceed = false;

      final success = await authProvider.signInWithGoogle();

      expect(success, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, 'Google sign in failed');
      expect(authProvider.user, null);
    });

    test('signOut clears user and calls repository signOut', () async {
      await authProvider.signInWithGoogle();
      expect(authProvider.user != null, true);

      await authProvider.signOut();

      expect(authProvider.user, null);
      expect(mockRepo.signOutCalled, true);
    });
  });
}
