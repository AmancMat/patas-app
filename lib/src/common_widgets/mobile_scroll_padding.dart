import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';

/// Widget de padding dinâmico para o rodapé de telas mobile e tablet.
///
/// ## Por que isso existe?
///
/// O app usa `extendBody: true` + barra inferior (`BottomFluidTabBar` / `AnimatedNotchBottomBar`)
/// no Scaffold principal (`bottom_navi_bar.dart`). Isso faz o corpo de cada página
/// renderizar por baixo da barra de navegação.
///
/// Em telas mobile e tablet (`!context.isDesktop`), seja em app nativo ou em navegadores Web,
/// é obrigatório compensar a altura da barra inferior (~76-88dp) mais o inset do sistema operacional.
class MobileScrollPadding extends StatelessWidget {
  /// Buffer de segurança adicional. Padrão: 24dp.
  final double offset;

  const MobileScrollPadding({super.key, this.offset = 24});

  /// Retorna o inset dinâmico correto para o rodapé em contexto mobile/tablet.
  static double bottomInset(BuildContext context, {double offset = 24}) {
    if (context.isDesktop) return 0;
    final sysPadding = MediaQuery.paddingOf(context).bottom;
    return math.max(sysPadding + offset, 88.0 + offset);
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return const SizedBox.shrink();
    final sysPadding = MediaQuery.paddingOf(context).bottom;
    final effectiveHeight = math.max(sysPadding + offset, 88.0 + offset);
    return SizedBox(height: effectiveHeight);
  }
}
