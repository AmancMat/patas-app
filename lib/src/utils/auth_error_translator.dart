class AuthErrorTranslator {
  static String translate(String error) {
    // Email não confirmado
    if (error.toLowerCase().contains('email not confirmed')) {
      return 'Por favor, confirme seu email antes de fazer login. Verifique sua caixa de entrada e clique no link de confirmação.';
    }

    // Credenciais inválidas ou usuário não encontrado (Anti-Enumeração)
    if (error.toLowerCase().contains('invalid login credentials') ||
        error.toLowerCase().contains('invalid email or password') ||
        error.toLowerCase().contains('user not found') ||
        error.toLowerCase().contains('no user found')) {
      return 'Email ou senha incorretos. Verifique seus dados e tente novamente.';
    }

    // Usuário já existe
    if (error.toLowerCase().contains('user already registered') ||
        error.toLowerCase().contains('email already exists')) {
      return 'Este email já está cadastrado. Tente fazer login ou recuperar sua senha.';
    }

    // Senha fraca
    if (error.toLowerCase().contains('password') &&
        error.toLowerCase().contains('weak')) {
      return 'Senha muito fraca. Use pelo menos 8 caracteres com letras maiúsculas e números.';
    }

    // Email inválido
    if (error.toLowerCase().contains('invalid email')) {
      return 'Email inválido. Verifique o formato do email.';
    }

    // Sessão expirada
    if (error.toLowerCase().contains('session') &&
        (error.toLowerCase().contains('expired') ||
            error.toLowerCase().contains('not logged in'))) {
      return 'Sua sessão expirou. Por favor, faça login novamente.';
    }

    // Erro de rede
    if (error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }

    // Erro genérico
    return 'Ocorreu um erro inesperado. Tente novamente mais tarde.';
  }
}
