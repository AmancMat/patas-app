import 'package:patas_web_app/src/features/home/widgets/patas_hub_bottom_sheet.dart';
import 'package:patas_web_app/src/features/home/widgets/home_fluid_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patas_web_app/src/features/home/profile/profile_page.dart';
import 'package:patas_web_app/src/features/home/timeline/time_line_page.dart';
import 'package:patas_web_app/src/features/home/widgets/home_right_panel.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../constants/app_colors.dart';
import 'package:patas_web_app/src/features/home/notifications/notifications_page.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/org_profile_page.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';
import 'package:patas_web_app/src/providers/profile_view_provider.dart';
import 'package:patas_web_app/src/providers/user_role_provider.dart';
import 'package:patas_web_app/src/features/notifications/widgets/web_notification_prompt_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRewardsActive = false;

  Future<void> _checkFeatureFlag() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('system_settings')
          .select('setting_value')
          .eq('setting_key', 'is_rewards_active')
          .maybeSingle();

      // A feature é visível se a flag global estiver ativa
      final bool flagAtiva =
          response != null && response['setting_value'] == true;

      // OU se o usuário for admin/tester (verificado via UserRoleProvider)
      if (mounted) {
        final roleProvider = Provider.of<UserRoleProvider>(
          context,
          listen: false,
        );
        final bool isPrivileged = roleProvider.isPrivileged;

        setState(() {
          _isRewardsActive = flagAtiva || isPrivileged;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar feature flag: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Inicializa o TabController com o valor atual do notifier global,
    // garantindo sincronia imediata (por exemplo, ao navegar diretamente para o perfil)
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: homeTabIndexNotifier.value,
    );
    _tabController.addListener(_handleTabIndex);
    homeTabIndexNotifier.addListener(_syncTabFromNotifier);
    _checkFeatureFlag();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accountProvider = Provider.of<ActiveAccountProvider>(
        context,
        listen: false,
      );
      final petProvider = Provider.of<ActivePetProvider>(
        context,
        listen: false,
      );
      final roleProvider = Provider.of<UserRoleProvider>(
        context,
        listen: false,
      );

      if (accountProvider.activeAccount == null) {
        await accountProvider.initialize(roleProvider: roleProvider);
      }

      // Agora que a role foi carregada, reavalia a feature flag
      await _checkFeatureFlag();

      final activeAcc = accountProvider.activeAccount;
      if (activeAcc != null && activeAcc.type == AccountType.pet) {
        try {
          final petData = await PetService().getPetById(activeAcc.id);
          if (petData != null) {
            petProvider.setActivePet(petData);
          }
        } catch (e) {
          debugPrint('Erro ao sincronizar pet na inicialização: $e');
        }
      }

      if (petProvider.activePet == null) {
        await petProvider.initialize();
      }

      // Ativa o listener de notificações em tempo real na Web para disparos no navegador
      if (kIsWeb) {
        SupabaseNotificationService().initWebRealtimeListener();
      }

      // Convite educativo para ativar notificações no Navegador Web (Desktop, Tablet, Mobile Web)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          WebNotificationPromptDialog.checkAndShow(context);
        }
      });
    });
  }

  void _syncTabFromNotifier() {
    if (_tabController.index != homeTabIndexNotifier.value) {
      if (context.isDesktop) {
        // No Desktop, a troca de abas deve ser instantânea, sem animação de deslize
        _tabController.index = homeTabIndexNotifier.value;
      } else {
        _tabController.animateTo(homeTabIndexNotifier.value);
      }
    }
  }

  @override
  void dispose() {
    homeTabIndexNotifier.removeListener(_syncTabFromNotifier);
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabIndex() {
    if (!mounted) return;
    if (homeTabIndexNotifier.value != _tabController.index) {
      homeTabIndexNotifier.value = _tabController.index;
    }
    setState(() {});
  }

  // ─── Profile view baseado na conta ativa ou perfil externo selecionado ─────
  Widget _buildProfileView(ActiveAccountProvider provider) {
    // Verifica se há um perfil externo sendo visualizado (ex: vindo do Stories no Desktop)
    final viewProvider = Provider.of<ProfileViewProvider>(context);
    if (viewProvider.hasTarget) {
      if (viewProvider.targetPet != null) {
        return ProfilePage(pet: viewProvider.targetPet);
      }
      if (viewProvider.targetOng != null || viewProvider.targetCorp != null) {
        return OrgProfilePage(
          ong: viewProvider.targetOng,
          corp: viewProvider.targetCorp,
        );
      }
    }

    final account = provider.activeAccount;
    if (account == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (account.type == AccountType.pet) {
      return ProfilePage(key: ValueKey('profile_pet_${account.id}'));
    } else if (account.type == AccountType.ong ||
        account.type == AccountType.company) {
      return OrgProfilePage(
        key: ValueKey('profile_org_${account.type.name}_${account.id}'),
        ongId: account.type == AccountType.ong ? account.id : null,
        corpId: account.type == AccountType.company ? account.id : null,
        ong: account.type == AccountType.ong
            ? OngProfile(
                id: account.id,
                name: account.name,
                photoUrl: account.photoUrl,
                userId: '',
                createdAt: DateTime.now(),
              )
            : null,
        corp: account.type == AccountType.company
            ? CorpProfile(
                id: account.id,
                userId: '',
                name: account.name,
                photoUrl: account.photoUrl,
                cnpj: '',
                category: '',
                address: '',
                phone: '',
                email: '',
                createdAt: DateTime.now(),
              )
            : null,
      );
    } else {
      return ProfilePage(
        key: ValueKey('profile_user_${account.id}'),
        userId: account.id,
      );
    }
  }

  // ─── Ícone de notificações com badge ────────────────────────────────────
  Widget _buildNotificationIcon({Color iconColor = AppColors.patasColor}) {
    return StreamBuilder<int>(
      stream: SupabaseNotificationService().unreadCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                mouseCursor: SystemMouseCursors.click,
                tooltip: context.tr('nav.notifications'),
                icon: IgnorePointer(
                  child: SvgPicture.asset(
                    'assets/icons/notification.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                ),
                onPressed: () {
                  if (context.isDesktop) {
                    showDialog(
                      context: context,
                      builder: (context) => const Dialog(
                        insetPadding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        child: NotificationsPage(isDialog: true),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                  }
                },
              ),
              if (count > 0)
                Positioned(
                  right: 7,
                  top: 7,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Provider.of<DarkMode>(context).darkMode
                              ? const Color(0xff1a1a1a)
                              : const Color(0xffFAFAFA),
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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

  // ─── FAB Unificado da Home (Patas Hub BottomSheet) ───────────────────────
  Widget _buildFloatingButtons({bool isMobile = false}) {
    final double bottomPadding = isMobile ? 100.0 : 20.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: FloatingActionButton(
        heroTag: null,
        tooltip: context.tr('home.patas_hub_tooltip'),
        elevation: 6,
        highlightElevation: 10,
        backgroundColor: AppColors.patasColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          PatasHubBottomSheet.show(context, isRewardsActive: _isRewardsActive);
        },
        child: const Icon(Icons.auto_awesome_rounded, size: 24),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE / TABLET — Nova HomeFluidAppBar retrátil com abas orgânicas
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, DarkMode thmode) {
    final isDark = thmode.darkMode;
    final bgColor = isDark ? AppColors.bodygray : const Color(0xffF5F5F5);
    // Mesma cor da aba ativa para manter o background da status bar permanente
    final activeBg = isDark ? const Color(0xff1a1a1a) : const Color(0xffFAFAFA);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    final systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: activeBg, // Cor da aba ativa na status bar do Android
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: Scaffold(
        backgroundColor: bgColor,
        floatingActionButton: _buildFloatingButtons(isMobile: true),
        body: Stack(
          children: [
            NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverPersistentHeader(
                        pinned: false,
                        floating: true,
                        delegate: HomeFluidHeaderDelegate(
                          tabController: _tabController,
                          statusBarHeight: statusBarHeight,
                          thmode: thmode,
                        ),
                      ),
                    ];
                  },
              body: TabBarView(
                controller: _tabController,
                clipBehavior: Clip.none,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: Consumer<ActiveAccountProvider>(
                      builder: (context, provider, child) =>
                          _buildProfileView(provider),
                    ),
                  ),
                  const TimeLinePage(),
                ],
              ),
            ),

            // ─── STATUS BAR PERMANENTE (NUNCA SOBE OU DESAPARECE NO SCROLL) ────
            if (statusBarHeight > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: statusBarHeight,
                child: IgnorePointer(child: Container(color: activeBg)),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP — Header topo + layout de 2 colunas (feed + painel lateral)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(BuildContext context, DarkMode thmode) {
    final bgColor = thmode.darkMode
        ? AppColors.bodygray
        : const Color(0xffF5F5F5);
    final headerBg = thmode.darkMode
        ? const Color(0xff1a1a1a)
        : const Color(0xffFAFAFA);
    final borderColor = thmode.darkMode ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: _buildFloatingButtons(isMobile: false),
      body: Column(
        children: [
          // ── Header horizontal ───────────────────────────────────────────
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                // Em Desktop, as abas (Perfil/Timeline) foram movidas para a sidebar lateral.
                // O header agora exibe apenas as ações de conta.
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildNotificationIcon(iconColor: AppColors.patasColor),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
          // ── Conteúdo: feed + painel lateral ────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Conteúdo principal (Timeline ou Perfil atrelado ao TabBarView)
                // Conteúdo principal (Timeline ou Perfil) com efeito de Fade no Desktop
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: SizedBox(
                      key: ValueKey<int>(_tabController.index),
                      child: _tabController.index == 0
                          ? Consumer<ActiveAccountProvider>(
                              builder: (context, provider, child) =>
                                  _buildProfileView(provider),
                            )
                          : const TimeLinePage(),
                    ),
                  ),
                ),
                // Painel lateral direito
                const HomeRightPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, thmode),
      desktop: _buildDesktopLayout(context, thmode),
    );
  }
}
