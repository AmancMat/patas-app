import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla o multiplicador de tamanho de fonte global do app.
/// Usa [TextScaler.linear] via MediaQuery — sem alterar nenhum widget existente.
///
/// Níveis disponíveis:
/// - small:  0.85 (−15%)
/// - normal: 1.00 (padrão)
/// - large:  1.20 (+20%)
class FontSizeProvider with ChangeNotifier {
  static const String _prefsKey = 'font_size_level';

  static const double _small = 0.85;
  static const double _normal = 1.00;
  static const double _large = 1.20;

  double _multiplier = _normal;
  String _level = 'normal';

  double get multiplier => _multiplier;
  String get level => _level;

  FontSizeProvider(double savedMultiplier, String savedLevel) {
    _multiplier = savedMultiplier;
    _level = savedLevel;
  }

  /// Carrega o nível salvo do SharedPreferences.
  static Future<FontSizeProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getString(_prefsKey) ?? 'normal';
    return FontSizeProvider(_levelToMultiplier(level), level);
  }

  void setSmall() => _setLevel('small', _small);
  void setNormal() => _setLevel('normal', _normal);
  void setLarge() => _setLevel('large', _large);

  void _setLevel(String level, double multiplier) async {
    if (_level == level) return;
    _level = level;
    _multiplier = multiplier;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, level);
  }

  static double _levelToMultiplier(String level) {
    switch (level) {
      case 'small':
        return _small;
      case 'large':
        return _large;
      default:
        return _normal;
    }
  }
}
