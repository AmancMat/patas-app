import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorBlindMode { none, protanopia, deuteranopia, tritanopia }

/// Gerencia as preferências de acessibilidade do usuário (exceto tamanho de fonte).
class AccessibilityProvider extends ChangeNotifier {
  static const String _reduceMotionKey = 'accessibility_reduce_motion';
  static const String _expandedSpacingKey = 'accessibility_expanded_spacing';
  static const String _colorBlindModeKey = 'accessibility_color_blind';

  bool _reduceMotion = false;
  bool _expandedSpacing = false;
  ColorBlindMode _colorBlindMode = ColorBlindMode.none;

  bool get reduceMotion => _reduceMotion;
  bool get expandedSpacing => _expandedSpacing;
  ColorBlindMode get colorBlindMode => _colorBlindMode;

  /// Retorna o padding ampliado para ser usado em widgets quando ativado.
  EdgeInsets get customPadding {
    return _expandedSpacing 
        ? const EdgeInsets.all(24.0) 
        : const EdgeInsets.all(16.0);
  }

  // Factory assíncrona para carregar a instância antes de inicializar o app
  static Future<AccessibilityProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = AccessibilityProvider();
    
    provider._reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    provider._expandedSpacing = prefs.getBool(_expandedSpacingKey) ?? false;
    
    final cbModeString = prefs.getString(_colorBlindModeKey);
    if (cbModeString != null) {
      provider._colorBlindMode = ColorBlindMode.values.firstWhere(
        (e) => e.toString() == cbModeString,
        orElse: () => ColorBlindMode.none,
      );
    }
    
    return provider;
  }

  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, value);
  }

  Future<void> setExpandedSpacing(bool value) async {
    if (_expandedSpacing == value) return;
    _expandedSpacing = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_expandedSpacingKey, value);
  }

  Future<void> setColorBlindMode(ColorBlindMode mode) async {
    if (_colorBlindMode == mode) return;
    _colorBlindMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorBlindModeKey, mode.toString());
  }

  // Matrizes de filtro de cor para simulação/correção leve
  static const List<double> protanopiaMatrix = [
    0.567, 0.433, 0.000, 0, 0,
    0.558, 0.442, 0.000, 0, 0,
    0.000, 0.242, 0.758, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> deuteranopiaMatrix = [
    0.625, 0.375, 0.000, 0, 0,
    0.700, 0.300, 0.000, 0, 0,
    0.000, 0.300, 0.700, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> tritanopiaMatrix = [
    0.950, 0.050, 0.000, 0, 0,
    0.000, 0.433, 0.567, 0, 0,
    0.000, 0.475, 0.525, 0, 0,
    0, 0, 0, 1, 0,
  ];

  ColorFilter? get currentColorFilter {
    switch (_colorBlindMode) {
      case ColorBlindMode.protanopia:
        return const ColorFilter.matrix(protanopiaMatrix);
      case ColorBlindMode.deuteranopia:
        return const ColorFilter.matrix(deuteranopiaMatrix);
      case ColorBlindMode.tritanopia:
        return const ColorFilter.matrix(tritanopiaMatrix);
      case ColorBlindMode.none:
        return null;
    }
  }
}
