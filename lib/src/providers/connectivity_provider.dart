import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider inteligente e resiliente de conectividade.
/// 
/// Evita falsos positivos e travamentos com:
/// 1. Debounce de 4s ao desconectar (ignora oscilações momentâneas de antena).
/// 2. Janela de estabilização (Grace Retry) em transição de rede / troca de Wi-Fi.
/// 3. Loop periódico de auto-recuperação (Heartbeat a cada 4s) quando estiver offline.
/// 4. Múltiplos probes ultraleves (Google 204, Cloudflare Trace e Supabase).
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOffline = false;
  bool _wasReconnected = false;
  bool _isChecking = false;
  Timer? _offlineDebounceTimer;
  Timer? _reconnectBannerTimer;
  Timer? _offlineRecoveryTimer;
  Timer? _transitionTimer;

  bool get isOffline => _isOffline;
  bool get wasReconnected => _wasReconnected;
  bool get isChecking => _isChecking;

  ConnectivityProvider() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    // Checagem inicial silenciosa com margem para estabilização
    checkConnectionNow(silent: true, isTransition: true);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (kIsWeb) {
      final bool hasNet = results.any((r) => r != ConnectivityResult.none);
      _offlineDebounceTimer?.cancel();
      _setOffline(!hasNet);
      return;
    }

    final bool hasHardwareConnection = results.any(
      (r) => r == ConnectivityResult.wifi ||
             r == ConnectivityResult.mobile ||
             r == ConnectivityResult.ethernet,
    );

    if (!hasHardwareConnection) {
      // O rádio físico desligou ou perdeu antena.
      // Aguarda 4 segundos contínuos antes de alertar (ignora oscilação rápida)
      _transitionTimer?.cancel();
      _offlineDebounceTimer?.cancel();
      _offlineDebounceTimer = Timer(const Duration(seconds: 4), () {
        _setOffline(true);
      });
    } else {
      // O rádio reconectou / trocou de rede: cancela debounce de offline
      _offlineDebounceTimer?.cancel();
      _transitionTimer?.cancel();
      // Aguarda 800ms para DHCP/DNS inicial do roteador e faz probe com retry
      _transitionTimer = Timer(const Duration(milliseconds: 800), () {
        checkConnectionNow(silent: true, isTransition: true);
      });
    }
  }

  /// Verifica se há internet real trafegando dados.
  /// 
  /// [isTransition]: Quando verdadeiro, se a primeira tentativa falhar, aguarda 1.5s
  /// e tenta novamente antes de considerar o app offline (filtra troca de Wi-Fi/DNS).
  Future<bool> checkConnectionNow({bool silent = false, bool isTransition = false}) async {
    if (_isChecking) return !_isOffline;
    _isChecking = true;
    if (!silent) notifyListeners();

    bool hasInternet = false;
    try {
      hasInternet = await _runConnectivityProbe();

      // Se falhou durante transição de rede ou quando estava online, dá uma segunda chance
      // antes de marcar como offline (absorve o tempo de negociação de rota)
      if (!hasInternet && (isTransition || !_isOffline)) {
        await Future.delayed(const Duration(milliseconds: 1500));
        hasInternet = await _runConnectivityProbe();
      }
    } catch (e) {
      debugPrint('ConnectivityProvider probe erro: $e');
      hasInternet = false;
    } finally {
      _isChecking = false;
      _setOffline(!hasInternet);
    }

    return hasInternet;
  }

  Future<bool> _runConnectivityProbe() async {
    final results = await _connectivity.checkConnectivity();
    final hasInterface = results.any(
      (r) => r != ConnectivityResult.none,
    );

    if (!hasInterface) {
      return false;
    }

    if (kIsWeb) {
      // Na Web, o navegador já monitora a conectividade via window.navigator.onLine.
      // Probes HTTP para Google 204 ou Cloudflare falham devido à política de CORS do browser.
      return true;
    }

    return await _probeHttp();
  }

  Future<bool> _probeHttp() async {
    // 1. Endpoint padrão Google 204 No Content (0 bytes, ultra-rápido)
    try {
      final uri = Uri.parse('https://clients3.google.com/generate_204');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // 2. Fallback Google alternativo
    try {
      final uri = Uri.parse('https://www.google.com/generate_204');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // 3. Fallback Cloudflare Trace (independente de infra Google/DNS de emulador)
    try {
      final uri = Uri.parse('https://1.1.1.1/cdn-cgi/trace');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // 4. Fallback: URL da REST API do Supabase configurada no app
    try {
      final restUrl = Supabase.instance.client.rest.url;
      final uri = Uri.parse(restUrl);
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 3));
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  void _setOffline(bool offline) {
    if (_isOffline == offline) {
      // Se continua offline, garante que o timer de auto-recuperação está rodando
      if (_isOffline && (_offlineRecoveryTimer == null || !_offlineRecoveryTimer!.isActive)) {
        _startOfflineRecoveryTimer();
      }
      return;
    }

    final previouslyOffline = _isOffline;
    _isOffline = offline;

    if (_isOffline) {
      _startOfflineRecoveryTimer();
    } else {
      _stopOfflineRecoveryTimer();
      if (previouslyOffline) {
        // Acabou de voltar a ficar online
        _wasReconnected = true;
        _reconnectBannerTimer?.cancel();
        _reconnectBannerTimer = Timer(const Duration(seconds: 3), () {
          _wasReconnected = false;
          notifyListeners();
        });
      }
    }

    notifyListeners();
  }

  /// Monitoramento periódico leve enquanto estiver offline para auto-recuperar assim que a internet voltar
  void _startOfflineRecoveryTimer() {
    _offlineRecoveryTimer?.cancel();
    _offlineRecoveryTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!_isOffline) {
        _stopOfflineRecoveryTimer();
        return;
      }
      // Checa silenciosamente sem notificar spinner
      await checkConnectionNow(silent: true);
    });
  }

  void _stopOfflineRecoveryTimer() {
    _offlineRecoveryTimer?.cancel();
    _offlineRecoveryTimer = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _offlineDebounceTimer?.cancel();
    _reconnectBannerTimer?.cancel();
    _transitionTimer?.cancel();
    _stopOfflineRecoveryTimer();
    super.dispose();
  }
}
