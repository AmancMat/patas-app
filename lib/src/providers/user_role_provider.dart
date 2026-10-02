import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Define os níveis de acesso de um usuário na plataforma.
enum UserRole {
  user,   // Usuário comum — acessa apenas features públicas
  tester, // Testador — acessa features em desenvolvimento
  admin,  // Administrador — acessa tudo, sempre
}

/// Provider responsável por carregar e expor a role (nível de acesso) do
/// usuário autenticado. Permite que features em desenvolvimento sejam visíveis
/// apenas para admins/testers, mesmo que a flag global esteja desligada.
class UserRoleProvider extends ChangeNotifier {
  UserRole _role = UserRole.user;
  bool _isLoaded = false;

  UserRole get role => _role;

  /// Retorna true se o usuário tem permissão para ver features em desenvolvimento.
  /// Isso é true para 'admin' e 'tester', independente do estado das feature flags.
  bool get isPrivileged =>
      _role == UserRole.admin || _role == UserRole.tester;

  /// Indica se a role já foi carregada do banco. Útil para evitar
  /// piscar o botão enquanto aguarda a resposta do Supabase.
  bool get isLoaded => _isLoaded;

  /// Busca a role do usuário logado na tabela `users`.
  /// Deve ser chamado logo após o login ou inicialização da conta.
  Future<void> fetchRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _role = UserRole.user;
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && response['role'] != null) {
        _role = _parseRole(response['role'] as String);
      } else {
        _role = UserRole.user;
      }
    } catch (e) {
      debugPrint('[UserRoleProvider] Erro ao buscar role: $e');
      // Em caso de falha, assume o nível mais restrito por segurança
      _role = UserRole.user;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Reseta a role ao fazer logout.
  void clearRole() {
    _role = UserRole.user;
    _isLoaded = false;
    notifyListeners();
  }

  UserRole _parseRole(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'tester':
        return UserRole.tester;
      default:
        return UserRole.user;
    }
  }
}
