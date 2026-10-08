import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provedor global de idioma e localização (i18n) do Patas.
/// 
/// Regra de Detecção & Fallback Inteligente:
/// 1. Preferência salva pelo usuário em SharedPreferences ('app_user_language').
/// 2. Se primeiro acesso:
///    - Dispositivo em Português ('pt') ➔ [Locale('pt', 'BR')].
///    - Dispositivo em QUALQUER OUTRO idioma (Inglês, Italiano, Espanhol, Francês, etc.)
///      ➔ [Locale('en', 'US')] (Fallback prioritário para avaliação global).
class LocaleProvider with ChangeNotifier {
  static const String _prefsKey = 'app_user_language';

  Locale _locale;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isPortuguese => _locale.languageCode == 'pt';
  bool get isEnglish => _locale.languageCode == 'en';

  LocaleProvider(this._locale);

  /// Carrega o idioma com fallback prioritário para Inglês se não for Português.
  static Future<LocaleProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);

    if (savedCode != null) {
      if (savedCode == 'pt') {
        return LocaleProvider(const Locale('pt', 'BR'));
      } else {
        return LocaleProvider(const Locale('en', 'US'));
      }
    }

    // Regra de primeira abertura:
    final deviceLocale = ui.PlatformDispatcher.instance.locale;
    if (deviceLocale.languageCode.toLowerCase() == 'pt') {
      return LocaleProvider(const Locale('pt', 'BR'));
    }

    // Fallback mandatório internacional:
    return LocaleProvider(const Locale('en', 'US'));
  }

  /// Define um novo idioma, notifica ouvintes e persiste no disco.
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }

  Future<void> setPortuguese() => setLocale(const Locale('pt', 'BR'));
  Future<void> setEnglish() => setLocale(const Locale('en', 'US'));
  Future<void> toggleLocale() => isPortuguese ? setEnglish() : setPortuguese();
}
