import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/features/health/utils/health_icon_helper.dart';
import 'package:patas_web_app/src/common_widgets/settings_lines_icon.dart';

/// ==============================================================================
/// NOVA BOTTOM NAVIGATION BAR DO PATAS — ABAS FLUIDAS INVERTIDAS & LINHA DE BASE
/// ==============================================================================

class BottomFluidTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const BottomFluidTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  static const double activeTabHeight = 48.0;
  static const double inactiveStripHeight = 34.0;
  static const double baseLineHeight = 5.0;

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xff1a1a1a) : const Color(0xffFAFAFA);
    final inactiveBg = isDark ? const Color(0xFF323232) : const Color(0xFFDCDCDC);
    final baseLineColor = activeBg;

    final screenWidth = MediaQuery.of(context).size.width;
    final double slotWidth = screenWidth / 5.0;
    // Largura da aba ativa com rampa lateral para encaixe orgânico
    final double tabWidth = (slotWidth + 14.0).clamp(64.0, 96.0);

    return SizedBox(
      width: screenWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── CAMADA SUPERIOR: TARJA INATIVA CONTÍNUA + ABA ATIVA ELEVADA ──
          SizedBox(
            height: activeTabHeight,
            width: screenWidth,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // 1. TARJA INATIVA CONTÍNUA DE MENOR ALTURA (DE PONTA A PONTA)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: inactiveStripHeight,
                  child: Container(
                    color: inactiveBg,
                  ),
                ),

                // 2. ÍCONES INATIVOS CENTRALIZADOS NA TARJA CONTÍNUA
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: inactiveStripHeight,
                  child: Row(
                    children: List.generate(5, (i) {
                      final iconColor =
                          isDark ? Colors.white54 : Colors.black45;
                      return Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: (i == currentIndex)
                              ? const SizedBox.shrink()
                              : _buildIconForIndex(i, iconColor, false),
                        ),
                      );
                    }),
                  ),
                ),

                // 3. ABA ATIVA ELEVADA COM GEOMETRIA EM GOTA (DESLIZANTE)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: (currentIndex * slotWidth) +
                      ((slotWidth - tabWidth) / 2.0),
                  bottom: 0,
                  width: tabWidth,
                  height: activeTabHeight,
                  child: _buildActiveTab(
                    index: currentIndex,
                    backgroundColor: activeBg,
                    width: tabWidth,
                    height: activeTabHeight,
                  ),
                ),

                // 4. CAMADA DE TOQUE RESPONSIVA (5 slots imediatos)
                Row(
                  children: List.generate(5, (i) {
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: const SizedBox(height: activeTabHeight),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ─── LINHA DE SUSTENTAÇÃO DE BASE (5PX) DE PONTA A PONTA DA TELA ─
          Container(
            height: baseLineHeight,
            width: screenWidth,
            color: baseLineColor,
          ),

          // ─── PREENCHIMENTO SÓLIDO ATÉ A BARRA DE GESTOS DO ANDROID ───────
          // No modo de gestos, preenche a área do traço do sistema com a mesma cor sólida.
          // No modo clássico de 3 botões (bottomInset == 0), encosta diretamente na barra.
          if (MediaQuery.of(context).padding.bottom > 0)
            Container(
              height: MediaQuery.of(context).padding.bottom,
              width: screenWidth,
              color: baseLineColor,
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTab({
    required int index,
    required Color backgroundColor,
    required double width,
    required double height,
  }) {
    return CustomPaint(
      painter: _BottomFluidTabPainter(
        color: backgroundColor,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        elevation: 6.0,
      ),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: _buildIconForIndex(index, AppColors.patasColor, true),
      ),
    );
  }

  Widget _buildIconForIndex(int index, Color iconColor, bool isActive) {
    const double iconSize = 22.0;

    switch (index) {
      case 0:
        return SvgPicture.asset(
          'assets/icons/search.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
      case 1:
        return SvgPicture.asset(
          'assets/icons/essential.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
      case 2:
        return SvgPicture.asset(
          'assets/icons/home.svg',
          width: iconSize + 2.0,
          height: iconSize + 2.0,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
      case 3:
        return Consumer<ActiveAccountProvider>(
          builder: (context, accProvider, _) {
            final accType = accProvider.activeAccount?.type;
            if (accType == AccountType.ong) {
              return Icon(
                Icons.volunteer_activism_rounded,
                size: iconSize,
                color: iconColor,
              );
            } else if (accType == AccountType.company) {
              return Icon(
                Icons.calendar_month_rounded,
                size: iconSize,
                color: iconColor,
              );
            }
            return Consumer<ActivePetProvider>(
              builder: (context, petProvider, _) {
                final iconPath = HealthIconHelper.getHealthIconPath(
                  species: petProvider.activePet?.species,
                  isActive: isActive,
                );
                return SvgPicture.asset(
                  iconPath,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                );
              },
            );
          },
        );
      case 4:
        return _buildSettingsLinesIcon(iconColor, iconSize);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Ícone autoral de Ajustes/Configurações com 3 linhas horizontais:
  /// Alinhadas à direita na vertical, com comprimentos escalonados (6, 9, 3).
  Widget _buildSettingsLinesIcon(Color color, double iconSize) {
    return SettingsLinesIcon(color: color, size: iconSize);
  }
}

/// Painter matemático com geometria de aba invertida verticalmente (espelhada da AppBar)
class _BottomFluidTabPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final double elevation;

  const _BottomFluidTabPainter({
    required this.color,
    required this.shadowColor,
    required this.elevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation * 1.5);

    final w = size.width;
    final h = size.height;

    // Proporções invertidas da AppBar da Home:
    // Na AppBar:
    //   - Topo: curva côncava invertida para fora (rTop)
    //   - Fundo: canto arredondado convexo (r)
    // Na BottomBar (Invertida verticalmente):
    //   - Fundo (Base): curva côncava invertida para fora (rBase) se fundindo à linha de base
    //   - Topo (Cúpula): cantos arredondados convexos (rTop)
    const double slopeX = 12.0; // Deslocamento horizontal da rampa
    const double rTop = 14.0;   // Raio arredondado convexo nos cantos superiores
    const double rBase = 12.0;  // Raio da curva côncava invertida (para fora) na base

    final path = Path();
    // 1. Inicia sangrando 4px para dentro da linha base à esquerda
    path.moveTo(-rBase, h + 4.0);
    path.lineTo(-rBase, h);

    // 2. Curva côncava invertida (para fora) na base esquerda:
    path.quadraticBezierTo(0.0, h, slopeX * (rBase / h), h - rBase);

    // 3. Rampa esquerda reta subindo até o canto superior:
    path.lineTo(slopeX * ((h - rTop) / h), rTop);

    // 4. Canto superior esquerdo convexo suave:
    path.quadraticBezierTo(slopeX, 0.0, slopeX + rTop, 0.0);

    // 5. Topo horizontal reto:
    path.lineTo(w - (slopeX + rTop), 0.0);

    // 6. Canto superior direito convexo suave:
    path.quadraticBezierTo(w - slopeX, 0.0, w - (slopeX * ((h - rTop) / h)), rTop);

    // 7. Rampa direita reta descendo até a base:
    path.lineTo(w - (slopeX * (rBase / h)), h - rBase);

    // 8. Curva côncava invertida (para fora) na base direita:
    path.quadraticBezierTo(w, h, w + rBase, h);

    // 9. Sangra 4px para dentro da linha base à direita e fecha
    path.lineTo(w + rBase, h + 4.0);
    path.close();

    if (elevation > 0) {
      canvas.drawPath(path.shift(const Offset(0, -3)), shadowPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BottomFluidTabPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation;
  }
}
