import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

abstract class AuthRepository {
  Future<Result<User, Failure>> signInWithGoogle();
  Future<Result<void, Failure>> signOut();
  Stream<AuthState> get onAuthStateChanged;
  User? get currentUser;
}
