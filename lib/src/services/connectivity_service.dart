import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Checks if the device is connected to any network (Wi-Fi, Mobile, etc.)
  /// and then verifies if it actually has internet access by looking up a host.
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        return false;
      }

      if (kIsWeb) {
        // Na Web, o navegador já gerencia a conectividade via DOM (window.navigator.onLine).
        // Fazer requisição HTTP para o Google ou terceiros falha por bloqueio de CORS.
        return true;
      }

      // Em mobile nativo: tenta DNS com fallback para HTTP probe (evita bloqueio de operadora em 3G/4G)
      try {
        final result = await InternetAddress.lookup('1.1.1.1').timeout(
          const Duration(seconds: 4),
        );
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // Fallback HTTP probe
      }

      final fallbackUri = Uri.parse('https://clients3.google.com/generate_204');
      final fallbackRes = await http.get(fallbackUri).timeout(const Duration(seconds: 4));
      return fallbackRes.statusCode == 204 || fallbackRes.statusCode == 200;
    } catch (e) {
      debugPrint('ConnectivityService: hasInternetConnection erro: $e');
      return false;
    }
  }

  /// Stream to monitor connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
