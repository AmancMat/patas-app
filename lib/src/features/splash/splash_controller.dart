import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_state.dart';
import '../../external_services/secure_storage.dart';
import '../../services/connectivity_service.dart';
import '../../../main.dart'; // Import to access 'supabase' global variable

class SplashController extends ChangeNotifier {
  final SecureStorage secureStorage;
  final PetServiceCallback petServiceCallback;
  final OngServiceCallback ongServiceCallback;
  final CorpServiceCallback corpServiceCallback;
  final ConnectivityService connectivityService;

  SplashController({
    required this.secureStorage,
    required this.petServiceCallback,
    required this.ongServiceCallback,
    required this.corpServiceCallback,
    required this.connectivityService,
  });

  SplashState _state = SplashStateInitial();
  bool _isDisposed = false;

  SplashState get state => _state;

  void _changeState(SplashState newState) {
    _state = newState;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> isUserLogged() async {
    // 1. Verificar Conexão antes de tudo
    final hasInternet = await connectivityService.hasInternetConnection();
    if (_isDisposed) return;

    if (!hasInternet) {
      _changeState(NoInternet());
      return;
    }

    // 2. Verificar Sessão no Supabase (mais confiável que SecureStorage direto)
    var session = supabase.auth.currentSession;
    var user = supabase.auth.currentUser;

    // Na Web, após redirecionamento do Google OAuth, a URL contém parâmetros de autenticação (#access_token, ?code=)
    // que o cliente Supabase processa assincronamente. Damos tempo para o token ser resolvido antes de deslogar.
    if (kIsWeb && session == null) {
      final uriStr = Uri.base.toString();
      final hasOAuthParams = uriStr.contains('access_token') ||
          uriStr.contains('code=') ||
          Uri.base.fragment.contains('access_token');

      if (hasOAuthParams) {
        debugPrint('🔄 [Splash] Parâmetros de OAuth detectados na URL Web. Aguardando resolução da sessão...');
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 250));
          if (_isDisposed) return;
          session = supabase.auth.currentSession;
          user = supabase.auth.currentUser;
          if (session != null && user != null && !session.isExpired) {
            debugPrint('✅ [Splash] Sessão OAuth detectada com sucesso na tentativa ${i + 1}!');
            break;
          }
        }
      }
    }

    if (session != null && user != null && !session.isExpired) {
      try {
        if (_isDisposed) return;

        // 1. Verificar se o modo de login ativo é 'vet'
        final prefs = await SharedPreferences.getInstance();
        final loginMode = prefs.getString('LAST_LOGIN_MODE') ?? 'tutor';

        if (loginMode == 'vet') {
          final vetProfile = await supabase
              .from('vet_profiles')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

          if (_isDisposed) return;

          if (vetProfile != null) {
            _changeState(AuthenticatedVetUser());
            return;
          }
        }

        // 2. Se não for vet, verifica se tem perfil de Tutor (Pet, ONG ou Empresa)
        final results = await Future.wait([
          petServiceCallback(user.id),
          ongServiceCallback(user.id),
          corpServiceCallback(user.id),
        ]);

        if (_isDisposed) return;

        final hasPets = results[0].isNotEmpty;
        final hasOngs = results[1].isNotEmpty;
        final hasCorps = results[2].isNotEmpty;

        if (hasPets || hasOngs || hasCorps) {
          _changeState(AuthenticatedUser());
        } else {
          _changeState(AuthenticatedUserNoPets());
        }
      } catch (e) {
        debugPrint("Erro ao verificar perfis no Splash: $e");
        // Em caso de falha de validação ou sessão inválida, limpa os dados e desloga por segurança
        try {
          await supabase.auth.signOut();
          await secureStorage.deleteOne(key: "CURRENT_USER");
        } catch (_) {}
        if (!_isDisposed) {
          _changeState(UnauthenticatedUser());
        }
      }
    } else {
      // Se não tem sessão ativa válida, limpa dados residuais e redireciona para a tela inicial deslogado
      try {
        await secureStorage.deleteOne(key: "CURRENT_USER");
      } catch (_) {}
      if (!_isDisposed) {
        _changeState(UnauthenticatedUser());
      }
    }
  }
}

// Definição dos callbacks para desacoplar ou facilitar testes
typedef PetServiceCallback = Future<List<dynamic>> Function(String userId);
typedef OngServiceCallback = Future<List<dynamic>> Function(String userId);
typedef CorpServiceCallback = Future<List<dynamic>> Function(String userId);
