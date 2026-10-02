import 'package:flutter/foundation.dart';
import '../../external_services/secure_storage.dart';
import '../auth/services/auth_services.dart';
import 'sign_in_state.dart';

class SignInController extends ChangeNotifier {
  final AuthService authService;
  final SecureStorage secureStorage;

  SignInController({required this.authService, required this.secureStorage});

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  SignInState _state = SignInStateInitial();

  SignInState get state => _state;

  void _changeState(SignInState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    _changeState(SignInStateLoading());

    try {
      final user = await authService.signIn(email: email, password: password);
      if (_disposed) return;

      if (user.id != null) {
        await secureStorage.write(key: "CURRENT_USER", value: user.toJson());
        if (_disposed) return;

        _changeState(SignInStateSuccess());
      } else {
        throw Exception();
      }
    } catch (e) {
      if (!_disposed) {
        _changeState(SignInStateError(e.toString()));
      }
    }
  }

  Future<void> signInWithGoogle() async {
    _changeState(SignInStateLoading());
    debugPrint("=== Iniciando Login com Google (SignInController) ===");

    try {
      debugPrint("Chamando authService.signInWithGoogle()...");
      await authService.signInWithGoogle();
      if (_disposed) return;
      debugPrint("authService retornou sem erros. O redirect/popup deve ter acontecido ou estar acontecendo.");
      // Não mudamos o estado aqui para Success, pois o redirect ou onAuthStateChange assumirá.
    } catch (e) {
      debugPrint("=== ERRO AO LOGAR COM GOOGLE ===");
      debugPrint(e.toString());
      if (!_disposed) {
        _changeState(SignInStateError(e.toString()));
      }
    }
  }

  Future<void> signInWithFacebook() async {
    _changeState(SignInStateLoading());

    try {
      await authService.signInWithFacebook();
      if (_disposed) return;
      // Não mudamos o estado aqui.
    } catch (e) {
      if (!_disposed) {
        _changeState(SignInStateError(e.toString()));
      }
    }
  }
}

