import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/providers/profile_view_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/corp_service.dart';
import 'package:patas_web_app/src/features/home/widgets/profile_switcher_bottom_sheet.dart';
import 'package:patas_web_app/src/features/pets/pets_create/create_pet_page.dart';
import 'package:patas_web_app/src/features/health/utils/health_icon_helper.dart';

/// Notifier global para persistir o estado de colapso da Sidebar no Desktop
final ValueNotifier<bool> isSidebarCollapsedNotifier = ValueNotifier<bool>(
  false,
);

class WebSidebar extends StatelessWidget {
  final int?
  currentNavIndex; // Se nulo, significa que estamos em uma tela externa (como o Encontra)
  final int? currentHomeTabIndex; // Aba interna da Home (Perfil/Timeline)
  final VoidCallback?
  onCustomNavigate; // Callback executado ao clicar em qualquer item

  const WebSidebar({
    super.key,
    this.currentNavIndex,
    this.currentHomeTabIndex,
    this.onCustomNavigate,
  });

  static const List<_SidebarNavItem> _navItems = [
    _SidebarNavItem(label: 'Buscar', icon: 'assets/icons/search.svg', index: 0),
    _SidebarNavItem(
      label: 'Essencial',
      icon: 'assets/icons/essential.svg',
      index: 1,
    ),
    _SidebarNavItem(label: 'Início', icon: 'assets/icons/home.svg', index: 2),
    _SidebarNavItem(
      label: 'Saúde',
      icon: 'assets/icons/patas_saude_out.svg',
      index: 3,
    ),
    _SidebarNavItem(
      label: 'Ajustes',
      icon: 'assets/icons/settings.svg',
      index: 4,
    ),
  ];

  void _navigateTo(BuildContext context, int navIndex, {int? homeTabIndex}) {
    if (onCustomNavigate != null) {
      onCustomNavigate!();
    }

    if (homeTabIndex != null) {
      if (homeTabIndex == 0) {
        Provider.of<ProfileViewProvider>(context, listen: false).clear();
      }
      homeTabIndexNotifier.value = homeTabIndex;
      if (bottomNavIndexNotifier.value != 2) {
        bottomNavIndexNotifier.value = 2;
      }
    } else {
      if (navIndex == 2) {
        homeTabIndexNotifier.value = 1;
      }
      if (bottomNavIndexNotifier.value != navIndex) {
        bottomNavIndexNotifier.value = navIndex;
      }
    }

    // Reseta o navegador interno do conteúdo desktop se houver sub-rotas empilhadas
    if (desktopContentNavigatorKey.currentState?.canPop() == true) {
      desktopContentNavigatorKey.currentState!.popUntil((route) => route.isFirst);
    }

    // Se estiver em uma tela secundária/externa no root, volta para a Home/Layout principal
    if (ModalRoute.of(context)?.settings.name != NamedRoute.home) {
      Navigator.of(
        context,
      ).popUntil((route) => route.settings.name == NamedRoute.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final railBg = isDark ? const Color(0xff1a1a1a) : const Color(0xffFAFAFA);
    final labelColor = isDark
        ? Colors.white70
        : AppColors.darkBG.withValues(alpha: 0.7);
    final selectedLabelColor = isDark ? Colors.white : AppColors.patasColor;

    return ValueListenableBuilder<bool>(
      valueListenable: isSidebarCollapsedNotifier,
      builder: (context, isCollapsed, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isCollapsed
              ? 80 + 24
              : 220 +
                    24, // Adiciona 24px de folga na largura total para o botão
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // Fundo visual real da sidebar (limitado a 80 ou 220px)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: 24, // Libera os 24px da direita para o botão
                child: Container(
                  decoration: BoxDecoration(
                    color: railBg,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Conteúdo da sidebar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right:
                    24, // Libera os 24px da direita para o conteúdo não transbordar
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // Logo e nome alinhados
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCollapsed ? 8 : 16,
                                    vertical: 8,
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    child: Row(
                                      mainAxisAlignment: isCollapsed
                                          ? MainAxisAlignment.center
                                          : MainAxisAlignment.start,
                                      children: [
                                        Image.asset(
                                          'assets/logo.png',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.contain,
                                        ),
                                        if (!isCollapsed) ...[
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              'Patas',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.patasColor,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Fredoka',
                                                fontSize: 22,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                const SizedBox(height: 16),

                                // ── SEÇÃO SUPERIOR (Perfil e Timeline) ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Consumer<ActiveAccountProvider>(
                                    builder: (context, accProvider, _) {
                                      final isHomeActive = currentNavIndex == 2;
                                      final isPerfilActive =
                                          isHomeActive &&
                                          currentHomeTabIndex == 0;
                                      final isTimelineActive =
                                          isHomeActive &&
                                          currentHomeTabIndex == 1;

                                      return Column(
                                        children: [
                                          _SidebarItem(
                                            label: 'Perfil',
                                            icon: _getAccountIcon(
                                              accProvider.activeAccount,
                                              isDark,
                                              isPerfilActive,
                                              labelColor,
                                            ),
                                            isSelected: isPerfilActive,
                                            labelColor: labelColor,
                                            selectedLabelColor:
                                                selectedLabelColor,
                                            onTap: () => _navigateTo(
                                              context,
                                              2,
                                              homeTabIndex: 0,
                                            ),
                                            isCollapsed: isCollapsed,
                                          ),
                                          _SidebarItem(
                                            label: 'Timeline',
                                            icon: SvgPicture.asset(
                                              'assets/icons/timeline.svg',
                                              width: 22,
                                              height: 22,
                                              colorFilter: ColorFilter.mode(
                                                isTimelineActive
                                                    ? AppColors.patasColor
                                                    : labelColor,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            isSelected: isTimelineActive,
                                            labelColor: labelColor,
                                            selectedLabelColor:
                                                selectedLabelColor,
                                            onTap: () => _navigateTo(
                                              context,
                                              2,
                                              homeTabIndex: 1,
                                            ),
                                            isCollapsed: isCollapsed,
                                          ),
                                          const SizedBox(height: 10),
                                          _ActivePetSidebarCard(isCollapsed: isCollapsed),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                const Spacer(),

                                // ── SEÇÃO INFERIOR (Buscar, Essencial, Saúde, Ajustes) ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    children: [
                                      // Renderiza os itens reordenados [Buscar, Essencial, Saúde, Ajustes]
                                      ...[2, 0, 1, 3, 4].map((index) {
                                        final item = _navItems[index];
                                        final isSelected =
                                            currentNavIndex == item.index;

                                        if (item.index == 1) {
                                          return Consumer<ActiveAccountProvider>(
                                            builder: (context, accProvider, _) {
                                              final accType = accProvider.activeAccount?.type;
                                              final String dynamicLabel;

                                              if (accType == AccountType.ong) {
                                                dynamicLabel = 'Acolhe';
                                              } else if (accType == AccountType.company) {
                                                dynamicLabel = 'Negócios';
                                              } else {
                                                dynamicLabel = item.label;
                                              }

                                              return _SidebarItem(
                                                label: dynamicLabel,
                                                icon: SvgPicture.asset(
                                                  item.icon,
                                                  width: 22,
                                                  height: 22,
                                                  colorFilter: ColorFilter.mode(
                                                    isSelected
                                                        ? AppColors.patasColor
                                                        : labelColor,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                                isSelected: isSelected,
                                                labelColor: labelColor,
                                                selectedLabelColor:
                                                    selectedLabelColor,
                                                onTap: () => _navigateTo(
                                                    context, item.index),
                                                isCollapsed: isCollapsed,
                                              );
                                            },
                                          );
                                        }

                                        if (item.index == 3) {
                                          return Consumer<ActiveAccountProvider>(
                                            builder: (context, accProvider, _) {
                                              final accType = accProvider.activeAccount?.type;
                                              if (accType == AccountType.ong) {
                                                return _SidebarItem(
                                                  label: 'Acolhidos',
                                                  icon: Icon(
                                                    Icons.volunteer_activism_rounded,
                                                    size: 22,
                                                    color: isSelected
                                                        ? AppColors.patasColor
                                                        : labelColor,
                                                  ),
                                                  isSelected: isSelected,
                                                  labelColor: labelColor,
                                                  selectedLabelColor:
                                                      selectedLabelColor,
                                                  onTap: () => _navigateTo(
                                                      context, item.index),
                                                  isCollapsed: isCollapsed,
                                                );
                                              } else if (accType == AccountType.company) {
                                                return _SidebarItem(
                                                  label: 'Agenda',
                                                  icon: Icon(
                                                    Icons.calendar_month_rounded,
                                                    size: 22,
                                                    color: isSelected
                                                        ? AppColors.patasColor
                                                        : labelColor,
                                                  ),
                                                  isSelected: isSelected,
                                                  labelColor: labelColor,
                                                  selectedLabelColor:
                                                      selectedLabelColor,
                                                  onTap: () => _navigateTo(
                                                      context, item.index),
                                                  isCollapsed: isCollapsed,
                                                );
                                              }

                                              return Consumer<ActivePetProvider>(
                                                builder: (context, petProvider, _) {
                                                  final iconPath =
                                                      HealthIconHelper.getHealthIconPath(
                                                    species: petProvider.activePet?.species,
                                                    isActive: isSelected,
                                                  );
                                                  return _SidebarItem(
                                                    label: item.label,
                                                    icon: SvgPicture.asset(
                                                      iconPath,
                                                      width: 22,
                                                      height: 22,
                                                      colorFilter: ColorFilter.mode(
                                                        isSelected
                                                            ? AppColors.patasColor
                                                            : labelColor,
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                                    isSelected: isSelected,
                                                    labelColor: labelColor,
                                                    selectedLabelColor:
                                                      selectedLabelColor,
                                                    onTap: () => _navigateTo(
                                                        context, item.index),
                                                    isCollapsed: isCollapsed,
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        }

                                        return _SidebarItem(
                                          label: item.label,
                                          icon: SvgPicture.asset(
                                            item.icon,
                                            width: 22,
                                            height: 22,
                                            colorFilter: ColorFilter.mode(
                                              isSelected
                                                  ? AppColors.patasColor
                                                  : labelColor,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          isSelected: isSelected,
                                          labelColor: labelColor,
                                          selectedLabelColor:
                                              selectedLabelColor,
                                          onTap: () =>
                                              _navigateTo(context, item.index),
                                          isCollapsed: isCollapsed,
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right:
                    0, // Sempre alinhado à extrema direita do Stack de 104/244px
                top: 90, // Altura padrão bem distribuída
                width: 24,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    isSidebarCollapsedNotifier.value = !isCollapsed;
                  },
                  child: CustomPaint(
                    painter: SidebarTogglePainter(
                      color: railBg,
                      borderColor: isDark
                          ? Colors.white10
                          : Colors.grey.shade200,
                      isDark: isDark,
                    ),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 3),
                      child: Icon(
                        isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                        color: isDark ? Colors.white70 : AppColors.patasColor,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getAccountIcon(
    ActiveAccount? account,
    bool isDark,
    bool isSelected,
    Color labelColor,
  ) {
    if (account?.photoUrl != null && account!.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(account.photoUrl!),
        radius: 11,
      );
    }
    IconData icon;
    switch (account?.type) {
      case AccountType.pet:
        icon = Icons.pets_rounded;
        break;
      case AccountType.ong:
        icon = Icons.volunteer_activism_rounded;
        break;
      case AccountType.company:
        icon = Icons.store_rounded;
        break;
      default:
        icon = Icons.person_rounded;
    }
    return Icon(
      icon,
      size: 22,
      color: isSelected ? AppColors.patasColor : labelColor,
    );
  }
}

class _SidebarNavItem {
  final String label;
  final String icon;
  final int index;
  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.index,
  });
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isSelected;
  final Color labelColor;
  final Color selectedLabelColor;
  final VoidCallback onTap;
  final bool isCollapsed;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.labelColor,
    required this.selectedLabelColor,
    required this.onTap,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final itemContent = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: isCollapsed ? 8 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.patasColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              SizedBox(width: 24, child: Center(child: icon)),
              if (!isCollapsed) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? selectedLabelColor : labelColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        child: itemContent,
      );
    }

    return itemContent;
  }
}

class SidebarTogglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isDark;

  SidebarTogglePainter({
    required this.color,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();

    // Curva de entrada superior (côncava para fora)
    // Curva do ponto (0, 0) para o ponto (6, 8)
    path.moveTo(0, 0);
    path.quadraticBezierTo(0, 8, 6, 8);

    // Saliência redonda do botão (curva convexa)
    // De (6, 8) para (6, 42) com ápice arredondado projetando-se à direita (x=24, y=25)
    path.cubicTo(24, 8, 24, 42, 6, 42);

    // Curva de saída inferior (côncava para dentro)
    // De (6, 42) voltando para (0, 50)
    path.quadraticBezierTo(0, 42, 0, 50);

    path.close();

    // Desenha sombra para dar profundidade física de botão projetado
    if (!isDark) {
      canvas.drawShadow(
        path.shift(const Offset(1, 1)),
        Colors.black.withValues(alpha: 0.12),
        4.0,
        true,
      );
    } else {
      canvas.drawShadow(
        path.shift(const Offset(1, 1)),
        Colors.black.withValues(alpha: 0.4),
        4.0,
        true,
      );
    }

    canvas.drawPath(path, paint);

    // Desenha apenas a borda de contorno da curva externa,
    // sem desenhar a linha vertical interna (que encosta na sidebar)
    final borderPath = Path();
    borderPath.moveTo(0, 0.5);
    borderPath.quadraticBezierTo(0, 8, 6, 8);
    borderPath.cubicTo(24, 8, 24, 42, 6, 42);
    borderPath.quadraticBezierTo(0, 42, 0, 49.5);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActivePetSidebarCard extends StatefulWidget {
  final bool isCollapsed;
  const _ActivePetSidebarCard({required this.isCollapsed});

  @override
  State<_ActivePetSidebarCard> createState() => _ActivePetSidebarCardState();
}

class _ActivePetSidebarCardState extends State<_ActivePetSidebarCard> {
  bool _isExpanded = false;
  bool _isHovered = false;
  List<ActiveAccount> _allAccounts = [];
  bool _isLoadingAccounts = false;

  @override
  void didUpdateWidget(covariant _ActivePetSidebarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed && _isExpanded) {
      setState(() => _isExpanded = false);
    }
  }

  Future<void> _fetchUserAccounts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoadingAccounts = true);
    try {
      List<ActiveAccount> accounts = [];

      // 1. Perfil Pessoal
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        accounts.add(ActiveAccount(
          id: user.id,
          name: userData?['name'] ?? 'Meu Perfil',
          photoUrl: userData?['photo_url'],
          type: AccountType.user,
        ));
      } catch (e) {
        debugPrint('Erro ao buscar perfil pessoal: $e');
      }

      // 2. Meus Pets
      try {
        final pets = await PetService().getPetsByUserId(user.id);
        for (var pet in pets) {
          accounts.add(ActiveAccount(
            id: pet.id,
            name: pet.name,
            photoUrl: pet.photoUrl,
            type: AccountType.pet,
          ));
        }
      } catch (e) {
        debugPrint('Erro ao buscar pets na sidebar: $e');
      }

      // 3. Minhas ONGs
      try {
        final ongs = await OngService().getUserOngProfiles(user.id);
        for (var ong in ongs) {
          accounts.add(ActiveAccount(
            id: ong.id,
            name: ong.name,
            photoUrl: ong.photoUrl,
            type: AccountType.ong,
          ));
        }
      } catch (e) {
        debugPrint('Erro ao buscar ONGs na sidebar: $e');
      }

      // 4. Minhas Empresas
      try {
        final corps = await CorpService().getUserCorpProfiles(user.id);
        for (var corp in corps) {
          accounts.add(ActiveAccount(
            id: corp.id,
            name: corp.name,
            photoUrl: corp.photoUrl,
            type: AccountType.company,
          ));
        }
      } catch (e) {
        debugPrint('Erro ao buscar empresas na sidebar: $e');
      }

      if (mounted) {
        setState(() {
          _allAccounts = accounts;
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      debugPrint('Erro geral ao buscar contas na sidebar: $e');
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  void _openProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
          child: const ProfileSwitcherBottomSheet(isDialog: true),
        ),
      ),
    );
  }

  void _toggleExpand() {
    if (widget.isCollapsed) {
      _openProfileDialog(context);
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _fetchUserAccounts();
    }
  }

  Widget _buildSpeciesBadge(String? species, {double fontSize = 16}) {
    final s = (species ?? '').toLowerCase().trim();
    String emoji = '🐶';
    if (s.contains('gato') || s.contains('felino') || s.contains('cat')) {
      emoji = '🐱';
    } else if (s.contains('ave') || s.contains('pássaro') || s.contains('passaro') || s.contains('bird')) {
      emoji = '🦜';
    } else if (s.contains('roedor') || s.contains('hamster') || s.contains('coelho') || s.contains('rabbit')) {
      emoji = '🐹';
    } else if (s.contains('exotico') || s.contains('exótico') || s.contains('reptil') || s.contains('peixe')) {
      emoji = '🦎';
    }

    return Text(
      emoji,
      style: TextStyle(fontSize: fontSize),
    );
  }

  IconData _getTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.user:
        return Icons.person_rounded;
      case AccountType.pet:
        return Icons.pets_rounded;
      case AccountType.ong:
        return Icons.volunteer_activism_rounded;
      case AccountType.company:
        return Icons.store_rounded;
    }
  }

  Color _getTypeColor(AccountType type) {
    switch (type) {
      case AccountType.user:
      case AccountType.pet:
        return AppColors.patasColor;
      case AccountType.ong:
        return Colors.purpleAccent;
      case AccountType.company:
        return Colors.teal;
    }
  }

  String _getTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.user:
        return 'Perfil Pessoal';
      case AccountType.pet:
        return 'Pet Ativo';
      case AccountType.ong:
        return 'ONG Ativa';
      case AccountType.company:
        return 'Empresa Ativa';
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final accProvider = Provider.of<ActiveAccountProvider>(context);
    final activePetProvider = Provider.of<ActivePetProvider>(context);
    final currentAccount = accProvider.activeAccount;
    final activePet = activePetProvider.activePet;

    // Se a conta ativa ainda não estiver carregada, tenta fallback pelo pet
    final effectiveAccount = currentAccount ??
        (activePet != null
            ? ActiveAccount(
                id: activePet.id,
                name: activePet.name,
                photoUrl: activePet.photoUrl,
                type: AccountType.pet,
              )
            : null);

    if (effectiveAccount == null) {
      return const SizedBox.shrink();
    }

    final typeColor = _getTypeColor(effectiveAccount.type);
    final typeLabel = _getTypeLabel(effectiveAccount.type);
    final typeIcon = _getTypeIcon(effectiveAccount.type);

    final isActiveOrHovered = _isExpanded || _isHovered;
    final cardBgColor = isActiveOrHovered
        ? typeColor.withValues(alpha: isDark ? 0.15 : 0.08)
        : Colors.transparent;
    final borderColor = isActiveOrHovered
        ? typeColor.withValues(alpha: _isExpanded ? 0.6 : 0.3)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: _isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header do Perfil Ativo (Pet, ONG, Empresa ou Usuário)
            InkWell(
              onTap: _toggleExpand,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: widget.isCollapsed ? 6 : 10,
                  horizontal: widget.isCollapsed ? 2 : 10,
                ),
                child: widget.isCollapsed
                    ? Tooltip(
                        message: '${effectiveAccount.name} ($typeLabel)',
                        child: Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: typeColor.withValues(alpha: 0.2),
                                backgroundImage: effectiveAccount.photoUrl != null &&
                                        effectiveAccount.photoUrl!.isNotEmpty
                                    ? NetworkImage(effectiveAccount.photoUrl!)
                                    : null,
                                child: effectiveAccount.photoUrl == null ||
                                        effectiveAccount.photoUrl!.isEmpty
                                    ? (effectiveAccount.type == AccountType.pet
                                        ? _buildSpeciesBadge(activePet?.species, fontSize: 14)
                                        : Icon(typeIcon, color: typeColor, size: 16))
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 7, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: 176,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: typeColor.withValues(alpha: 0.15),
                                backgroundImage: effectiveAccount.photoUrl != null &&
                                        effectiveAccount.photoUrl!.isNotEmpty
                                    ? NetworkImage(effectiveAccount.photoUrl!)
                                    : null,
                                child: effectiveAccount.photoUrl == null ||
                                        effectiveAccount.photoUrl!.isEmpty
                                    ? (effectiveAccount.type == AccountType.pet
                                        ? _buildSpeciesBadge(activePet?.species, fontSize: 16)
                                        : Icon(typeIcon, color: typeColor, size: 18))
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      effectiveAccount.name,
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.darkBG,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: typeColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          typeLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: typeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: typeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            // Seção Expandida com Lista Unificada de Perfis
            if (_isExpanded && !widget.isCollapsed) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: typeColor.withValues(alpha: 0.2),
              ),
              if (_isLoadingAccounts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.patasColor),
                    ),
                  ),
                )
              else if (_allAccounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Center(
                    child: Text(
                      'Nenhum perfil encontrado.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                )
              else ...[
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._allAccounts.map((account) {
                          final isSelected = account.id == effectiveAccount.id &&
                              account.type == effectiveAccount.type;
                          final accColor = _getTypeColor(account.type);
                          final accIcon = _getTypeIcon(account.type);

                          return InkWell(
                            onTap: () async {
                              await accProvider.setActiveAccount(
                                account,
                                petProvider: activePetProvider,
                              );
                              if (context.mounted) {
                                Provider.of<ProfileViewProvider>(context,
                                        listen: false)
                                    .clear();
                              }
                              setState(() => _isExpanded = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: isSelected
                                  ? accColor.withValues(alpha: isDark ? 0.2 : 0.1)
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: accColor.withValues(alpha: 0.2),
                                    backgroundImage: account.photoUrl != null &&
                                            account.photoUrl!.isNotEmpty
                                        ? NetworkImage(account.photoUrl!)
                                        : null,
                                    child: account.photoUrl == null ||
                                            account.photoUrl!.isEmpty
                                        ? Icon(accIcon, color: accColor, size: 12)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          account.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected
                                                ? accColor
                                                : (isDark ? Colors.white70 : AppColors.darkBG),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          _getTypeLabel(account.type),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white38 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_rounded, color: accColor, size: 16),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.patasColor.withValues(alpha: 0.15),
                ),

                // Rodapé com Ações Rápidas (Diálogo completo / Cadastrar Pet)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => _isExpanded = false);
                            _openProfileDialog(context);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.manage_accounts_outlined, size: 15, color: AppColors.patasColor),
                                SizedBox(width: 4),
                                Text(
                                  'Ver Todos',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.patasColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 14,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => _isExpanded = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreatePetPage(species: 'Cão')),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 15, color: AppColors.patasColor),
                                SizedBox(width: 4),
                                Text(
                                  'Novo Pet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.patasColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}


