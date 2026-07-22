import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final supabase.SupabaseClient _supabaseClient;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(this._supabaseClient, this._googleSignIn);

  @override
  supabase.User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  Stream<supabase.AuthState> get onAuthStateChanged =>
      _supabaseClient.auth.onAuthStateChange;

  @override
  Future<Result<supabase.User, Failure>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const FailureResult(
          ServerFailure('Google sign-in aborted by user'),
        );
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        return const FailureResult(
          ServerFailure('Google authentication tokens are missing.'),
        );
      }

      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) {
        return const FailureResult(
          ServerFailure('User object is null after sign-in.'),
        );
      }

      return Success(user);
    } on supabase.AuthException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    try {
      await Future.wait([
        _supabaseClient.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Success(null);
    } on supabase.AuthException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
