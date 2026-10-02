import 'package:flutter/foundation.dart';
import 'package:patas_web_app/src/features/auth/models/user_model.dart';
import 'package:patas_web_app/src/features/auth/services/auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; // Importando o cliente Supabase globalmente

class SupabaseAuthService implements AuthService {
  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return UserModel(
          id: response.user!.id,
          name: response
              .user!
              .userMetadata?['name'], // Supabase stores metadata in user_metadata
          email: response.user!.email,
        );
      } else {
        throw Exception("Sign in failed: No user in response.");
      }
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final String redirectTo =
          kIsWeb ? Uri.base.origin : 'io.supabase.patasapp://login-callback/';

      final bool success = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );

      if (!success) {
        throw Exception("Falha ao iniciar o login com Google.");
      }

      return UserModel(id: 'oauth-flow', email: '', name: 'Google User');
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> signInWithFacebook() async {
    try {
      final String redirectTo =
          kIsWeb ? Uri.base.origin : 'io.supabase.patasapp://login-callback/';

      final success = await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        throw Exception("Sign in with Facebook failed.");
      }

      return UserModel(id: 'oauth', email: '', name: '');
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> signUp({
    String? name,
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Store name in user_metadata
      );

      if (response.user != null) {
        return UserModel(
          id: response.user!.id,
          name: response.user!.userMetadata?['name'],
          email: response.user!.email,
        );
      } else {
        throw Exception("Sign up failed: No user in response.");
      }
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> verifyPassword(String password) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null || user.email == null) {
        throw 'Usuário não autenticado';
      }

      // Tenta fazer login com o e-mail atual e a senha fornecida para verificar se está correta
      await supabase.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw 'A senha atual está incorreta';
      }
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> get userToken async {
    try {
      final Session? session = supabase.auth.currentSession;
      if (session != null) {
        return session.accessToken;
      } else {
        throw Exception('User not logged in or session expired.');
      }
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> requestAccountDeletion() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Atualiza o campo deletion_requested_at para NOW()
      await supabase
          .from('users')
          .update({'deletion_requested_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      // Faz logout após marcar para exclusão
      await signOut();
    } on PostgrestException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> cancelAccountDeletion() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Remove a marcação de exclusão (define como NULL)
      await supabase
          .from('users')
          .update({'deletion_requested_at': null})
          .eq('id', user.id);
    } on PostgrestException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> checkPendingDeletion() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // Busca os dados do usuário incluindo deletion_requested_at
      final response = await supabase
          .from('users')
          .select('id, name, email, photo_url, deletion_requested_at')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      final userModel = UserModel.fromMap(response);

      // Retorna o modelo apenas se houver exclusão pendente
      return userModel.isPendingDeletion ? userModel : null;
    } on PostgrestException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }
}
