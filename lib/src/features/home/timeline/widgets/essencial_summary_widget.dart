import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/providers/connectivity_provider.dart';
import 'package:patas_web_app/src/features/encontra/services/encontra_service.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';

class EssencialSummaryWidget extends StatefulWidget {
  const EssencialSummaryWidget({super.key});

  @override
  State<EssencialSummaryWidget> createState() => _EssencialSummaryWidgetState();
}

class _EssencialSummaryWidgetState extends State<EssencialSummaryWidget> {
  final _encontraService = EncontraService();
  List<Map<String, dynamic>> _lostPets = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadLostPets();
  }

  Future<void> _loadLostPets() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final lostPets = await _encontraService.getLostPets();
      if (mounted) {
        setState(() {
          _lostPets = lostPets;
          _hasError = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar pets perdidos no summary widget: $e');
      if (mounted) {
        setState(() {
          _lostPets = [];
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    
    // Verifica se a tela atual é um dispositivo móvel/tela estreita
    final bool isMobile = context.isMobile;
    
    // Padding vertical e horizontal responsivos para evitar desproporção
    final double verticalPadding = isMobile ? 14.0 : 22.0;
    final double horizontalPadding = isMobile ? 12.0 : 16.0;
    final double titleFontSize = isMobile ? 15.0 : 18.0;
    final double dividerVerticalPadding = isMobile ? 6.0 : 8.0;

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 15),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho da ferramenta com botão de refresh alinhado à direita
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Patas Encontra',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.patasColor,
                    ),
                  ),
                  if (!_isLoading && _lostPets.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      color: isDark ? Colors.white54 : Colors.black54,
                      tooltip: 'Recarregar',
                      onPressed: _loadLostPets,
                    ),
                ],
              ),
              
              // Divider horizontal com espessura 3, contraste e padding horizontal de 5px
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: dividerVerticalPadding),
                child: Divider(
                  thickness: 3,
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(height: 8),

              // Conteúdo Dinâmico com animação
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _buildContent(isDark, isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: CircularProgressIndicator(color: AppColors.patasColor),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState(isDark, isMobile);
    }

    if (_lostPets.isEmpty) {
      return _buildEmptyState(isDark, isMobile);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dimensões do card de pet adaptadas a telas desktop vs mobile
        final double itemWidth = isMobile ? 95.0 : 110.0;
        final double spacing = isMobile ? 10.0 : 12.0;
        final double containerWidth = constraints.maxWidth;

        // Calcula a quantidade máxima de itens por linha
        int maxItemsPerLine = (containerWidth / (itemWidth + spacing)).floor();
        if (maxItemsPerLine < 1) maxItemsPerLine = 1;

        final bool hasMoreThanLine = _lostPets.length > maxItemsPerLine;

        List<Widget> itemsToDisplay = [];

        if (!_isExpanded && hasMoreThanLine) {
          // No modo comprimido, exibe (maxItemsPerLine - 1) cards e depois o card "Ver Mais"
          final int displayCount = maxItemsPerLine - 1;
          for (int i = 0; i < displayCount; i++) {
            itemsToDisplay.add(_buildPetCard(_lostPets[i], isDark, isMobile));
          }
          itemsToDisplay.add(_buildToggleCard(
            isDark: isDark,
            isVerMais: true,
            isMobile: isMobile,
            onTap: () => setState(() => _isExpanded = true),
          ));
        } else {
          // No modo expandido ou quando cabe tudo, exibe todos os itens
          for (final petData in _lostPets) {
            itemsToDisplay.add(_buildPetCard(petData, isDark, isMobile));
          }
          if (hasMoreThanLine) {
            itemsToDisplay.add(_buildToggleCard(
              isDark: isDark,
              isVerMais: false,
              isMobile: isMobile,
              onTap: () => setState(() => _isExpanded = false),
            ));
          }
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: itemsToDisplay,
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, bool isMobile) {
    // Escala os tamanhos de ícone e fonte para telas mobile estreitas
    final double iconContainerSize = isMobile ? 44.0 : 54.0;
    final double shieldIconSize = isMobile ? 22.0 : 28.0;
    final double titleFontSize = isMobile ? 14.0 : 16.0;
    final double descFontSize = isMobile ? 11.0 : 12.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tudo sob controle por aqui!',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Os pets reportados como perdidos na sua região aparecerão aqui. No momento, nenhum pet está perdido e a proteção ativa do Patas Encontra segue atenta.',
                style: TextStyle(
                  fontSize: descFontSize,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: iconContainerSize,
          height: iconContainerSize,
          decoration: BoxDecoration(
            color: isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            border: Border.all(
              color: isDark
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.green.shade200.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.shield_outlined,
              size: shieldIconSize,
              color: isDark ? Colors.green.shade400 : Colors.green.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark, bool isMobile) {
    final double iconContainerSize = isMobile ? 44.0 : 54.0;
    final double alertIconSize = isMobile ? 22.0 : 28.0;
    final double titleFontSize = isMobile ? 14.0 : 16.0;
    final double descFontSize = isMobile ? 11.0 : 12.0;

    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    final bool isRealOffline = connectivity.isOffline;

    final IconData errorIcon = isRealOffline
        ? Icons.wifi_off_rounded
        : Icons.cloud_off_rounded;
    final String errorTitle = isRealOffline
        ? 'Sem conexão com a internet'
        : 'Instabilidade no servidor';
    final String errorSubtitle = isRealOffline
        ? 'Conecte-se à internet para consultar os alertas de pets perdidos.'
        : 'Não foi possível consultar os alertas no momento. Tente novamente em instantes.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorTitle,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    errorSubtitle,
                    style: TextStyle(
                      fontSize: descFontSize,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.withValues(alpha: 0.12) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                border: Border.all(
                  color: isDark
                      ? Colors.amber.withValues(alpha: 0.3)
                      : Colors.amber.shade300,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  errorIcon,
                  size: alertIconSize,
                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _loadLostPets,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 6),
                Text(
                  'Toque para tentar novamente',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetCard(Map<String, dynamic> tagData, bool isDark, bool isMobile) {
    final pet = tagData['pets'] as Map<String, dynamic>?;
    final petName = pet?['name'] ?? 'Pet';
    final petPhoto = pet?['photo_url'] as String?;
    final petBreed = pet?['breed'] as String?;
    final petSpecies = pet?['species'] as String?;
    final breedOrSpecies = (petBreed != null && petBreed.isNotEmpty)
        ? petBreed
        : (petSpecies ?? 'Pet');

    // Dimensionamento responsivo
    final double cardWidth = isMobile ? 95.0 : 110.0;
    final double cardHeight = isMobile ? 135.0 : 150.0;
    final double photoSize = isMobile ? 48.0 : 60.0;
    final double nameFontSize = isMobile ? 11.0 : 12.0;
    final double breedFontSize = isMobile ? 8.0 : 9.0;
    final double badgeFontSize = isMobile ? 7.0 : 7.5;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: isMobile ? 8 : 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Foto do Pet
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: photoSize,
                  height: photoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.shade400,
                      width: isMobile ? 1.5 : 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.15),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: petPhoto != null && petPhoto.isNotEmpty
                        ? Image.network(
                            petPhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              child: Icon(
                                Icons.pets_rounded,
                                size: isMobile ? 22 : 30,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          )
                        : Container(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            child: Icon(
                              Icons.pets_rounded,
                              size: isMobile ? 22 : 30,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: isMobile ? 8 : 10,
                    height: isMobile ? 8 : 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),

            // Nome do Pet com contraste dependente do tema (WCAG)
            Text(
              petName,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: nameFontSize,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),

            // Raça
            Text(
              breedOrSpecies,
              style: TextStyle(
                fontSize: breedFontSize,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 4 : 6),

            // Badge "PERDIDO"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'PERDIDO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: badgeFontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required bool isDark,
    required bool isVerMais,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    // Dimensionamento responsivo
    final double cardWidth = isMobile ? 95.0 : 110.0;
    final double cardHeight = isMobile ? 135.0 : 150.0;
    final double circleSize = isMobile ? 36.0 : 44.0;
    final double iconSize = isMobile ? 22.0 : 28.0;
    final double titleFontSize = isMobile ? 11.0 : 12.0;
    final double subtitleFontSize = isMobile ? 8.0 : 9.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVerMais ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                color: AppColors.patasColor,
                size: iconSize,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              isVerMais ? 'Ver Mais' : 'Ver Menos',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.patasColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isVerMais ? 'Expandir' : 'Recolher',
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
