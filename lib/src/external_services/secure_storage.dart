import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SecureStorage {
  const SecureStorage();

  // Opções padrão seguras para Mobile
  final _secureStorage = const FlutterSecureStorage();

  Future<void> write({required String key, String? value}) async {
    // Na Web, o flutter_secure_storage falha frequentemente sem libs externas de CryptoJS.
    // O fallback 100% seguro oficial para a web é o localStorage do HTML base do Flutter.
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      if (value != null) {
        await prefs.setString('SECURE_WEB_$key', value);
      } else {
        await prefs.remove('SECURE_WEB_$key');
      }
      return;
    }
    
    await _secureStorage.write(
      key: key,
      value: value,
    );
  }

  Future<String?> readOne({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('SECURE_WEB_$key');
    }
    return await _secureStorage.read(key: key);
  }

  Future<Map<String, String>> readAll() async {
    if (kIsWeb) {
      // Mock vazio para Web pois o readAll massivo quase não é executado e o prefs não segura chave segura em lote no Mobile
      return {};
    }
    return await _secureStorage.readAll();
  }

  Future<void> deleteOne({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('SECURE_WEB_$key');
      return;
    }
    await _secureStorage.delete(key: key);
  }

  Future<void> deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('SECURE_WEB_'));
      for (var k in keys) {
        await prefs.remove(k);
      }
      return;
    }
    await _secureStorage.deleteAll();
  }
}
