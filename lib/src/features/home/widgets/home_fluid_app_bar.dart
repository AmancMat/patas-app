import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/features/home/notifications/notifications_page.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';
import 'package:patas_web_app/src/utils/to_publish_page.dart';
import 'package:patas_web_app/src/features/home/widgets/profile_switcher_bottom_sheet.dart';
import 'package:patas_web_app/src/features/home/widgets/overlapping_profile_avatars.dart';

/// ==============================================================================
/// NOVA APPBAR DA HOME DO PATAS — HARMONIZADA COM A BOTTOM FLUID TAB BAR
/// ==============================================================================

/// Delegate dinâmico para SliverPersistentHeader com barra cinza e abas sobrepostas
class HomeFluidHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final double statusBarHeight;
  final DarkMode thmode;

  const HomeFluidHeaderDelegate({
    required this.tabController,
    required this.statusBarHeight,
    required this.thmode,
  });

  static const double barHeight = 36.0;
  static const double tabsHeight = 48.0;

  @override
  double get maxExtent => statusBarHeight + tabsHeight;

  @override
  double get minExtent => 0.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = thmode.darkMode;
    // Mesma cor da tarja inativa da BottomFluidTabBar
    final inactiveBarBg =
        isDark ? const Color(0xFF323232) : const Color(0xFFDCDCDC);
    // Mesma cor da aba ativa para a Status Bar do Android
    final activeBg =
        isDark ? const Color(0xff1a1a1a) : const Color(0xffFAFAFA);

    final screenWidth = MediaQuery.of(context).size.width;
    // Cálculo responsivo e homogêneo:
    // Em telas mobile (340px a 420px), dimensionamos as abas para respirar sem colidir
    // com o logo à esquerda (~64px) e as ações à direita (notificação + switcher = ~76px).
    final double tabWidth = screenWidth < 410
        ? (screenWidth * 0.24).clamp(86.0, 96.0)
        : ((screenWidth - 160.0).clamp(170.0, 210.0) + 24.0) / 2.0;
    final double overlapOffset = tabWidth - (screenWidth < 410 ? 22.0 : 24.0);
    final double tabsTotalWidth = overlapOffset + tabWidth;

    // Distribuição balanceada no eixo horizontal:
    // Garante que as ações da direita tenham pelo menos 80px e o logo da esquerda tenha 66px,
    // mantendo as abas centralizadas sempre que houver folga geométrica.
    const double leftReserved = 66.0;
    const double rightReserved = 80.0;
    final double idealCenter = (screenWidth - tabsTotalWidth) / 2.0;
    final double maxLeft =
        (screenWidth - tabsTotalWidth - rightReserved).clamp(leftReserved, screenWidth);
    final double tabsLeft = idealCenter.clamp(leftReserved, maxLeft);

    final systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: activeBg, // Cor da aba ativa na status bar do Android
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    final double offset = shrinkOffset.clamp(0.0, maxExtent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minHeight: maxExtent,
          maxHeight: maxExtent,
          child: Transform.translate(
            offset: Offset(0, -offset),
            child: SizedBox(
              height: maxExtent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ─── CAMADA 1: BARRA SUPERIOR (TOOLBAR CINZA DE MENOR ALTURA) ──
                  Positioned(
                    top: statusBarHeight,
                    left: 0,
                    right: 0,
                    height: barHeight,
                    child: Container(
                      height: barHeight,
                      color: inactiveBarBg,
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Row(
                        children: [
                          Text(
                            'Patas',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.patasColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                              fontSize: 19,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          HomeNotificationButton(isDark: isDark),
                          const SizedBox(width: 2),
                          const HomeProfileSwitcherButton(),
                        ],
                      ),
                    ),
                  ),

                  // ─── CAMADA 2: AS DUAS ABAS FLUIDAS (CENTRALIZADAS E MAIORES) ──
                  // Ligeiramente maior que a barra cinza (48px vs 36px), cobrindo o cinza
                  Positioned(
                    top: statusBarHeight - 1.0,
                    left: tabsLeft,
                    width: tabsTotalWidth,
                    height: tabsHeight,
                    child: HomeFluidTabsBar(
                      tabController: tabController,
                      tabWidth: tabWidth,
                      overlapOffset: overlapOffset,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HomeFluidHeaderDelegate oldDelegate) {
    return oldDelegate.tabController != tabController ||
        oldDelegate.statusBarHeight != statusBarHeight ||
        oldDelegate.thmode.darkMode != thmode.darkMode;
  }
}

/// Barra de abas fluidas com formato em gota larga e sobreposição (Tab 0: Pet / Tab 1: Feed)
class HomeFluidTabsBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final double tabWidth;
  final double overlapOffset;

  const HomeFluidTabsBar({
    super.key,
    required this.tabController,
    this.tabWidth = 114.0,
    this.overlapOffset = 86.0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        return Consumer<ActiveAccountProvider>(
          builder: (context, activeProvider, _) {
            final activeAccount = activeProvider.activeAccount;
            final petName = (activeAccount?.name != null &&
                    activeAccount!.name.isNotEmpty)
                ? activeAccount.name
                : 'Perfil';
            final photoUrl = activeAccount?.photoUrl;

            return Container(
              height: 48,
              alignment: Alignment.topCenter,
              child: _HomeFluidTabsStack(
                selectedIndex: tabController.index,
                petName: petName,
                photoUrl: photoUrl,
                isDark: isDark,
                tabWidth: tabWidth,
                overlapOffset: overlapOffset,
                onTabSelected: (index) {
                  tabController.animateTo(index);
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Gerencia o empilhamento das camadas (Z-index) para sobreposição das abas
class _HomeFluidTabsStack extends StatelessWidget {
  final int selectedIndex;
  final String petName;
  final String? photoUrl;
  final bool isDark;
  final double tabWidth;
  final double overlapOffset;
  final ValueChanged<int> onTabSelected;

  const _HomeFluidTabsStack({
    required this.selectedIndex,
    required this.petName,
    required this.photoUrl,
    required this.isDark,
    required this.tabWidth,
    required this.overlapOffset,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isProfileActive = selectedIndex == 0;

    final activeBg = isDark ? const Color(0xff1a1a1a) : const Color(0xffFAFAFA);
    final inactiveBg =
        isDark ? const Color(0xFF383838) : const Color(0xFFCECECE);

    const double tabHeight = 48.0;
    final double totalWidth = overlapOffset + tabWidth;

    return SizedBox(
      height: tabHeight,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── CAMADA TRASEIRA (Inativa / Mais Escura / Encoberta) ──
          if (isProfileActive)
            Positioned(
              left: overlapOffset,
              top: 0.0,
              width: tabWidth,
              height: tabHeight,
              child: _buildFeedTab(
                isActive: false,
                backgroundColor: inactiveBg,
                width: tabWidth,
                height: tabHeight,
                onTap: () => onTabSelected(1),
              ),
            )
          else
            Positioned(
              left: 0.0,
              top: 0.0,
              width: tabWidth,
              height: tabHeight,
              child: _buildProfileTab(
                isActive: false,
                backgroundColor: inactiveBg,
                width: tabWidth,
                height: tabHeight,
                onTap: () => onTabSelected(0),
              ),
            ),

          // ── CAMADA DIANTEIRA (Ativa / Em Destaque / Por Cima) ─────
          if (isProfileActive)
            Positioned(
              left: 0.0,
              top: 0.0,
              width: tabWidth,
              height: tabHeight,
              child: _buildProfileTab(
                isActive: true,
                backgroundColor: activeBg,
                width: tabWidth,
                height: tabHeight,
                onTap: () => onTabSelected(0),
              ),
            )
          else
            Positioned(
              left: overlapOffset,
              top: 0.0,
              width: tabWidth,
              height: tabHeight,
              child: _buildFeedTab(
                isActive: true,
                backgroundColor: activeBg,
                width: tabWidth,
                height: tabHeight,
                onTap: () => onTabSelected(1),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Aba 1: Perfil do Pet ──────────────────────────────────────────────────
  Widget _buildProfileTab({
    required bool isActive,
    required Color backgroundColor,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    final textColor = isActive
        ? (isDark ? Colors.white : AppColors.darkBG)
        : (isDark ? Colors.white54 : Colors.black54);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _FluidTabPainter(
          color: backgroundColor,
          shadowColor: Colors.black.withValues(alpha: isActive ? 0.35 : 0.0),
          elevation: isActive ? 5 : 0,
        ),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 2),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar circular do pet ativo
              CircleAvatar(
                radius: 11,
                backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(Icons.pets, size: 11, color: AppColors.patasColor)
                    : null,
              ),
              const SizedBox(width: 5),
              // Nome do Pet Ativo
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: (width - 48).clamp(30.0, 70.0)),
                child: Text(
                  petName,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Aba 2: Feed Social ────────────────────────────────────────────────────
  Widget _buildFeedTab({
    required bool isActive,
    required Color backgroundColor,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    final textColor = isActive
        ? (isDark ? Colors.white : AppColors.darkBG)
        : (isDark ? Colors.white54 : Colors.black54);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _FluidTabPainter(
          color: backgroundColor,
          shadowColor: Colors.black.withValues(alpha: isActive ? 0.35 : 0.0),
          elevation: isActive ? 5 : 0,
        ),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 2),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título "Feed"
              Text(
                'Feed',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 6),
              // Ícone clássico do feed em círculo
              Material(
                elevation: isActive ? 2.0 : 0.0,
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                color: Colors.transparent,
                child: Ink.image(
                  image: const AssetImage('assets/feed.png'),
                  fit: BoxFit.cover,
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER VETORIAL: DESENHA A "GOTA LARGA" COM CURVAS BÉZIER CONTÍNUAS
// ─────────────────────────────────────────────────────────────────────────────
class _FluidTabPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final double elevation;

  _FluidTabPainter({
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

    // Proporção cartesiana com curvas côncavas invertidas (para fora) no topo:
    const double slopeX = 14.0; // Deslocamento horizontal da rampa
    const double r = 16.0;      // Raio arredondado suave nos cantos inferiores
    const double rTop = 12.0;   // Raio da curva côncava invertida (para fora) nos cantos superiores

    final path = Path();
    // Inicia sangrando 4px para dentro da AppBar à esquerda da curva invertida
    path.moveTo(-rTop, -4.0);
    path.lineTo(-rTop, 0.0);
    // ── CANTO SUPERIOR ESQUERDO: Curva côncava invertida (para fora) ──
    path.quadraticBezierTo(0.0, 0.0, slopeX * (rTop / h), rTop);

    // Linha reta contínua na rampa esquerda descendo até o início do canto arredondado
    path.lineTo(slopeX * ((h - r) / h), h - r);
    // Canto inferior esquerdo arredondado e suave
    path.quadraticBezierTo(slopeX, h, slopeX + r, h);
    // Base horizontal reta (deslocamento apenas em X)
    path.lineTo(w - (slopeX + r), h);
    // Canto inferior direito arredondado e suave
    path.quadraticBezierTo(w - slopeX, h, w - (slopeX * ((h - r) / h)), h - r);
    // Linha reta contínua na rampa direita subindo até o início da curva superior
    path.lineTo(w - (slopeX * (rTop / h)), rTop);

    // ── CANTO SUPERIOR DIREITO: Curva côncava invertida (para fora) ──
    path.quadraticBezierTo(w, 0.0, w + rTop, 0.0);
    path.lineTo(w + rTop, -4.0);
    path.close();

    if (elevation > 0) {
      canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FluidTabPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES DA APPBAR (Notificação, Troca de Pet e Botão Cápsula)
// ─────────────────────────────────────────────────────────────────────────────

/// Botão "+ Postar" em formato de pílula (cápsula) — Mantido como helper/compatibilidade
class HomePublishPillButton extends StatelessWidget {
  const HomePublishPillButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Postar nova publicação',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ToPublishPage()),
            );
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.patasColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.patasColor.withValues(alpha: 0.35),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white, size: 16),
                SizedBox(width: 3),
                Text(
                  'Postar',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ícone de notificações compacto com badge
class HomeNotificationButton extends StatelessWidget {
  final bool isDark;

  const HomeNotificationButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: SupabaseNotificationService().unreadCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notificações',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: SvgPicture.asset(
                'assets/icons/notification.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white70 : AppColors.patasColor,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xff1a1a1a)
                          : const Color(0xffFAFAFA),
                      width: 1.2,
                    ),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Botão de alternar pet / perfil ativo
class HomeProfileSwitcherButton extends StatelessWidget {
  const HomeProfileSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveAccountProvider>(
      builder: (context, provider, _) {
        return IconButton(
          tooltip: 'Trocar perfil ativo',
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => const ProfileSwitcherBottomSheet(),
            );
          },
          icon: OverlappingProfileAvatars(
            activeAccount: provider.activeAccount,
            previousAccount: provider.previousAccount,
            size: 28,
          ),
        );
      },
    );
  }
}
