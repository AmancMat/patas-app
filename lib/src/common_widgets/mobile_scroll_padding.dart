import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Widget de padding dinâmico para o rodapé de telas mobile.
///
/// ## Por que isso existe?
///
/// O app usa `extendBody: true` + `AnimatedNotchBottomBar` no Scaffold principal
/// (`bottom_navi_bar.dart`). Com `extendBody: true`, o Flutter injeta no
/// `MediaQuery.padding.bottom` do corpo a **altura total** da barra de navegação
/// (barra animada + inset do sistema operacional).
///
/// ## ⚠️ ERRO COMUM — viewPadding vs padding
///
/// - `MediaQuery.viewPadding.bottom` → apenas o inset do sistema (~34dp em
///   navegação gestual). NÃO inclui a altura da `AnimatedNotchBottomBar`.
/// - `MediaQuery.padding.bottom` → inset do sistema + altura da barra animada.
///   É o valor CORRETO a usar no contexto do body do Scaffold com `extendBody: true`.
///
/// ## Quando usar
///
/// Adicione como **último item** de qualquer `ListView`, `GridView` ou
/// `Column` scrollável em telas que **não** possuem seu próprio
/// `bottomNavigationBar` no Scaffold.
///
/// **Na Web**, o widget retorna um `SizedBox.shrink()` (tamanho zero).
///
/// ## Exemplos de uso
///
/// ```dart
/// // ListView — adicionar como último item:
/// ListView(
///   children: [
///     ...itens,
///     const MobileScrollPadding(),
///   ],
/// )
///
/// // GridView — usar no parâmetro padding:
/// GridView.count(
///   padding: EdgeInsets.only(
///     left: 16,
///     right: 16,
///     top: 16,
///     bottom: MobileScrollPadding.bottomInset(context),
///   ),
///   ...
/// )
/// ```
class MobileScrollPadding extends StatelessWidget {
  /// Buffer de segurança adicionado ao `padding.bottom` do sistema.
  /// 24dp e suficiente pois `padding.bottom` ja inclui toda a barra animada.
  final double offset;

  const MobileScrollPadding({super.key, this.offset = 24});

  /// Retorna o inset dinamico correto para o rodape em contexto mobile.
  ///
  /// Usa `MediaQuery.padding.bottom` (que com `extendBody: true` ja contem
  /// a altura total da `AnimatedNotchBottomBar`) mais um buffer de seguranca.
  static double bottomInset(BuildContext context, {double offset = 24}) {
    if (kIsWeb) return 0;
    // padding.bottom (nao viewPadding!) contem: sistema + barra animada.
    return MediaQuery.of(context).padding.bottom + offset;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return SizedBox(
      height: MediaQuery.of(context).padding.bottom + offset,
    );
  }
}
