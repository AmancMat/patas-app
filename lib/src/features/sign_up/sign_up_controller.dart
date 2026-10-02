import 'package:flutter/foundation.dart';
import '../../external_services/secure_storage.dart';
import '../auth/services/auth_services.dart';
import 'package:patas_web_app/src/features/home/rewards/services/gamification_service.dart';
import 'sign_up_state.dart';

class SignUpController extends ChangeNotifier {
  final AuthService authService;
  final SecureStorage secureStorage;

  SignUpController({required this.authService, required this.secureStorage});

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

  SignUpState _state = SignUpStateInitial();

  SignUpState get state => _state;

  void _changeState(SignUpState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    _changeState(SignUpStateLoading());

    try {
      final user = await authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      if (_disposed) return;

      if (user.id != null) {
        await secureStorage.write(key: "CURRENT_USER", value: user.toJson());
        if (_disposed) return;

        // [PATAS REWARDS] Processa o código de convite (se houver)
        if (referralCode != null && referralCode.trim().isNotEmpty) {
          // Não bloqueia o fluxo com await longo, apenas manda rodar
          GamificationService().processReferral(
            newUserId: user.id!,
            referralCode: referralCode.trim(),
          );
        }

        _changeState(SignUpStateSuccess());
      } else {
        throw Exception();
      }
    } catch (e) {
      if (!_disposed) {
        _changeState(SignUpStateError(e.toString()));
      }
    }
  }

  Future<void> signInWithGoogle() async {
    _changeState(SignUpStateLoading());

    try {
      await authService.signInWithGoogle();
      // Não mudamos o estado aqui.
    } catch (e) {
      _changeState(SignUpStateError(e.toString()));
    }
  }

  Future<void> signInWithFacebook() async {
    _changeState(SignUpStateLoading());

    try {
      await authService.signInWithFacebook();
      // Não mudamos o estado aqui.
    } catch (e) {
      _changeState(SignUpStateError(e.toString()));
    }
  }
}
