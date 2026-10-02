import 'package:flutter/material.dart';

/// Ícone autoral estilizado com 3 linhas horizontais escalonadas e cantos arredondados,
/// mantendo a mesma identidade visual da BottomFluidTabBar e do ecossistema Patas.
class SettingsLinesIcon extends StatelessWidget {
  final Color color;
  final double size;
  final CrossAxisAlignment alignment;

  const SettingsLinesIcon({
    super.key,
    required this.color,
    this.size = 24.0,
    this.alignment = CrossAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    // Proporção base (tamanho 24px)
    final double scale = (size / 24.0) * 2.2;
    final double line1Width = 6.0 * scale; // ~13.2px em 24px
    final double line2Width = 9.0 * scale; // ~19.8px em 24px
    final double line3Width = 4.0 * scale; // ~8.8px em 24px
    final double lineHeight = (size / 24.0) * 2.4;
    final double lineSpacing = (size / 24.0) * 3.2;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            Container(
              width: line1Width,
              height: lineHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(lineHeight / 2),
              ),
            ),
            SizedBox(height: lineSpacing),
            Container(
              width: line2Width,
              height: lineHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(lineHeight / 2),
              ),
            ),
            SizedBox(height: lineSpacing),
            Container(
              width: line3Width,
              height: lineHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(lineHeight / 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
