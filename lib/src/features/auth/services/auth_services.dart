import '../models/user_model.dart';

abstract class AuthService {
  Future<UserModel> signUp({
    String? name,
    required String email,
    required String password,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<UserModel> signInWithGoogle();

  Future<UserModel> signInWithFacebook();

  Future<void> signOut();

  Future<void> verifyPassword(String password);

  Future<void> updatePassword(String newPassword);

  Future<void> requestAccountDeletion();

  Future<void> cancelAccountDeletion();

  Future<UserModel?> checkPendingDeletion();

  Future<String> get userToken;
}
