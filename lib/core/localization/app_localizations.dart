import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patas_web_app/core/localization/translations_en.dart';
import 'package:patas_web_app/core/localization/translations_pt.dart';

/// Motor de localização oficial do Patas Web App.
/// 
/// Fornece resolução rápida de strings em tempo de execução com fallback seguro.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en', 'US'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('pt', 'BR'),
  ];

  bool get isEn => locale.languageCode.toLowerCase() != 'pt';
  bool get isPt => locale.languageCode.toLowerCase() == 'pt';

  Map<String, String> get _currentDictionary {
    if (isPt) {
      return ptTranslations;
    }
    return enTranslations;
  }

  /// Traduz uma chave com substituição opcional de parâmetros no formato {param}.
  String translate(String key, [Map<String, String>? params]) {
    String? value = _currentDictionary[key];

    // Fallback: se não encontrar no idioma atual, tenta no dicionário alternativo
    value ??= (locale.languageCode == 'pt' ? enTranslations[key] : ptTranslations[key]);

    // Se ainda não encontrar, retorna a própria chave para fácil diagnóstico visual
    if (value == null) {
      if (kDebugMode) {
        debugPrint('⚠️ [i18n] Chave de tradução não encontrada: "$key"');
      }
      return key;
    }

    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramVal) {
        value = value!.replaceAll('{$paramKey}', paramVal);
      });
    }

    return value!;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'pt'].contains(locale.languageCode.toLowerCase());
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extensão de conveniência para uso ergonômico no BuildContext.
/// Exemplo: `Text(context.tr('nav.feed'))` ou `context.l10n.translate('auth.login')`
extension AppLocalizationsContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key, [Map<String, String>? params]) =>
      AppLocalizations.of(this).translate(key, params);
  bool get isEn => AppLocalizations.of(this).isEn;
  bool get isPt => AppLocalizations.of(this).isPt;
}
