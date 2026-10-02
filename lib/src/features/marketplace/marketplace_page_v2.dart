import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import '../../../app.dart';
import '../../constants/app_colors.dart';
import '../../constants/routes.dart';
import '../../utils/responsive_layout.dart';
import '../encontra/screens/tutor_encontra_dashboard.dart';
import '../encontra/screens/admin_qr_generator_screen.dart';
import '../friendly/screens/friendly_dashboard_screen.dart';
import '../pets/active_pet_provider.dart';
import '../love/screens/patas_love_main_screen.dart';
import '../historica/screens/patas_historica_page.dart';
import '../home/profile/profile_page.dart';
import '../adestradores/screens/adestradores_catalog_screen.dart';
import '../acolhe/screens/public_adoption_catalog_screen.dart';
import '../acolhe/screens/ong_donations_dashboard_screen.dart';
import '../acolhe/screens/public_donation_mural_screen.dart';
import '../acolhe/screens/ong_collective_medical_screen.dart';
import '../acolhe/screens/ong_temporary_homes_screen.dart';
import '../acolhe/screens/volunteer_temporary_home_sheet.dart';
import '../acolhe/screens/ong_events_dashboard_screen.dart';
import '../acolhe/screens/ong_rescue_alerts_screen.dart';
import '../../models/active_account_model.dart';
import '../../providers/active_account_provider.dart';

class MarketplacePageV2 extends StatefulWidget {
  const MarketplacePageV2({super.key});

  @override
  State<MarketplacePageV2> createState() => _MarketplacePageV2State();
}

class _MarketplacePageV2State extends State<MarketplacePageV2> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _canPopLocal = true;

  void _updatePopState() {
    if (!mounted) return;
    final canPop = _navigatorKey.currentState?.canPop() ?? false;
    if (_canPopLocal != !canPop) {
      setState(() {
        _canPopLocal = !canPop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPopLocal,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigatorKey.currentState?.pop();
      },
      child: Navigator(
        key: _navigatorKey,
        observers: [
          _LocalNavigatorObserver(
            onNavigationChanged: () {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _updatePopState(),
              );
            },
          ),
        ],
        onGenerateRoute: (settings) {
          Widget builder(BuildContext context) {
            switch (settings.name) {
              case '/':
                return const MarketplaceHomeScreen();
              case NamedRoute.encontraDashboard:
                return const TutorEncontraDashboard();
              case NamedRoute.friendlyDashboard:
                return const FriendlyDashboardScreen();
              case NamedRoute.adminQrGenerator:
                return const AdminQrGeneratorScreen();
              default:
                return const MarketplaceHomeScreen();
            }
          }

          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
    );
  }
}

class _LocalNavigatorObserver extends NavigatorObserver {
  final VoidCallback onNavigationChanged;

  _LocalNavigatorObserver({required this.onNavigationChanged});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onNavigationChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onNavigationChanged();
  }
}

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveAccountProvider>(
      builder: (context, accProvider, _) {
        final activeAccount = accProvider.activeAccount;
        final isOng = activeAccount?.type == AccountType.ong;
        final isCompany = activeAccount?.type == AccountType.company;

        return ResponsiveLayout(
          mobile: _buildMobileLayout(
            context,
            isOng: isOng,
            isCompany: isCompany,
            activeAccount: activeAccount,
          ),
          tablet: _buildTabletLayout(
            context,
            isOng: isOng,
            isCompany: isCompany,
            activeAccount: activeAccount,
          ),
          desktop: _buildDesktopLayout(
            context,
            isOng: isOng,
            isCompany: isCompany,
            activeAccount: activeAccount,
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context, {
    required bool isOng,
    required bool isCompany,
    required ActiveAccount? activeAccount,
  }) {
    final thmode = Provider.of<DarkMode>(context);

    final String appBarTitle;
    final String appBarSubtitle;

    if (isOng) {
      appBarTitle = 'Patas Acolhe';
      appBarSubtitle = 'Hub de gestão da ONG e animais acolhidos';
    } else if (isCompany) {
      appBarTitle = 'Patas Negócios';
      appBarSubtitle = 'Painel de serviços, agenda e clientes';
    } else {
      appBarTitle = 'Patas Essencial';
      appBarSubtitle = 'Hub de facilidades e serviços pet';
    }

    return Scaffold(
      backgroundColor: thmode.darkMode
          ? AppColors.bodygray
          : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: appBarTitle,
        subtitle: appBarSubtitle,
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Card contextual por perfil
              if (isOng)
                _buildOngHeroCard(context, isDesktop: false)
              else if (isCompany)
                _buildCompanyHeroCard(context, isDesktop: false)
              else
                _buildTutorHeroCard(context, isDesktop: false),

              const SizedBox(height: 24),

              // Grid de Cards contextual por perfil com aspect ratio elástico
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final double mobileAspectRatio =
                      (screenWidth < 370 || textScale > 1.05) ? 0.78 : 0.82;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: mobileAspectRatio,
                    children: isOng
                        ? _buildOngGridCards(isDesktop: false)
                        : (isCompany
                            ? _buildCompanyGridCards(isDesktop: false)
                            : _buildTutorGridCards(isDesktop: false)),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context, {
    required bool isOng,
    required bool isCompany,
    required ActiveAccount? activeAccount,
  }) {
    final thmode = Provider.of<DarkMode>(context);

    final String appBarTitle;
    final String appBarSubtitle;

    if (isOng) {
      appBarTitle = 'Patas Acolhe';
      appBarSubtitle = 'Hub de gestão da ONG e animais acolhidos';
    } else if (isCompany) {
      appBarTitle = 'Patas Negócios';
      appBarSubtitle = 'Painel de serviços, agenda e clientes';
    } else {
      appBarTitle = 'Patas Essencial';
      appBarSubtitle = 'Hub de facilidades e serviços pet';
    }

    return Scaffold(
      backgroundColor: thmode.darkMode
          ? AppColors.bodygray
          : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: appBarTitle,
        subtitle: appBarSubtitle,
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Card contextual elegante e proporcional
                  if (isOng)
                    _buildOngHeroCard(context, isDesktop: false)
                  else if (isCompany)
                    _buildCompanyHeroCard(context, isDesktop: false)
                  else
                    _buildTutorHeroCard(context, isDesktop: false),

                  const SizedBox(height: 24),

                  // Título da seção
                  Text(
                    isOng
                        ? 'Ferramentas de Gestão do Abrigo'
                        : (isCompany ? 'Ferramentas do Profissional' : 'Serviços e Microapps'),
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid de Microapps no Tablet com 3 ou 4 colunas equilibradas e altura confortável
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final int crossAxisCount =
                          constraints.maxWidth >= 820 ? 4 : 3;
                      final double ratio =
                          constraints.maxWidth >= 820 ? 1.05 : 0.98;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: ratio,
                        children: isOng
                            ? _buildOngGridCards(isDesktop: true)
                            : (isCompany
                                ? _buildCompanyGridCards(isDesktop: true)
                                : _buildTutorGridCards(isDesktop: true)),
                      );
                    },
                  ),

                  // Padding dinâmico para compensar a BottomFluidTabBar
                  const MobileScrollPadding(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context, {
    required bool isOng,
    required bool isCompany,
    required ActiveAccount? activeAccount,
  }) {
    final thmode = Provider.of<DarkMode>(context);
    final bgColor = thmode.darkMode
        ? AppColors.bodygray
        : const Color(0xFFF0F2F5);

    final String headerTitle;
    final String headerSubtitle;
    final Color headerColor;

    if (isOng) {
      headerTitle = 'Patas Acolhe 🐾';
      headerSubtitle =
          'Painel de impacto social, animais acolhidos, doações e adoções responsáveis.';
      headerColor = const Color(0xFF7C3AED);
    } else if (isCompany) {
      headerTitle = 'Patas Negócios 💼';
      headerSubtitle =
          'Gerenciamento profissional de serviços, agendamentos, clientes e faturamento.';
      headerColor = const Color(0xFF0D9488);
    } else {
      headerTitle = 'Patas Essencial';
      headerSubtitle =
          'Explore os microapps e serviços exclusivos para o seu pet.';
      headerColor = AppColors.patasColor;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerTitle,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: headerColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  headerSubtitle,
                  style: TextStyle(
                    color: thmode.darkMode ? Colors.white60 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Seção de Destaque (Desktop Hero)
                const _SectionTitle(title: 'Destaques'),
                const SizedBox(height: 16),
                if (isOng)
                  _buildOngHeroCard(context, isDesktop: true)
                else if (isCompany)
                  _buildCompanyHeroCard(context, isDesktop: true)
                else
                  _buildTutorHeroCard(context, isDesktop: true),

                const SizedBox(height: 48),

                // Seção de Microapps
                _SectionTitle(
                  title: isOng
                      ? 'Ferramentas de Gestão do Abrigo'
                      : (isCompany ? 'Ferramentas do Profissional' : 'Serviços e Microapps'),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 4 : 3;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 1.1,
                      children: isOng
                          ? _buildOngGridCards(isDesktop: true)
                          : (isCompany
                              ? _buildCompanyGridCards(isDesktop: true)
                              : _buildTutorGridCards(isDesktop: true)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🐶 VISÃO DO TUTOR (PERFIL PET / PESSOAL)
  // ─────────────────────────────────────────────

  Widget _buildTutorHeroCard(BuildContext context, {required bool isDesktop}) {
    return _HeroCard(
      title: 'Patas Saúde',
      description: isDesktop
          ? 'A rede de saúde completa para seu animal de estimação. Consultas, exames em domicílio e telemedicina 24h.'
          : 'Consultas, exames de laboratório e muito mais',
      icon: Icons.monitor_heart_outlined,
      iconColor: Colors.white,
      backgroundColor: AppColors.patasColor,
      isDesktop: isDesktop,
      onTap: () {
        bottomNavIndexNotifier.value = 3;
      },
    );
  }

  List<Widget> _buildTutorGridCards({bool isDesktop = false}) {
    return [
      // 1. NOVO: Adestradores e Especialistas em Comportamento Pet
      _GridCard(
        title: 'Adestradores',
        description: 'Treinadores & Comportamento Pet',
        icon: Icons.sports_score_rounded,
        customBadgeText: 'NOVO',
        customBadgeColor: Colors.orangeAccent,
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const AdestradoresCatalogScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdestradoresCatalogScreen(),
              ),
            );
          }
        },
      ),

      // 2. NOVO: Adoção Responsável de Pets de ONGs
      _GridCard(
        title: 'Adote um Pet',
        description: 'Amigos acolhidos por ONGs parceiras',
        icon: Icons.favorite_rounded,
        customBadgeText: 'SOCIAL',
        customBadgeColor: Colors.purpleAccent,
        iconColor: Colors.purpleAccent,
        iconBgColor: Colors.purpleAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const PublicAdoptionCatalogScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PublicAdoptionCatalogScreen(),
              ),
            );
          }
        },
      ),

      // 3. NOVO: Mural de Doações & Campanhas de ONGs
      _GridCard(
        title: 'Mural de Doações',
        description: 'Apoie ONGs com PIX direto e ração',
        icon: Icons.volunteer_activism_rounded,
        customBadgeText: 'SOLIDÁRIO',
        customBadgeColor: Colors.pinkAccent,
        iconColor: Colors.pinkAccent,
        iconBgColor: Colors.pinkAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const PublicDonationMuralScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PublicDonationMuralScreen(),
              ),
            );
          }
        },
      ),

      // 4. Lar Temporário (Voluntariado da Comunidade para ONGs)
      _GridCard(
        title: 'Lar Temporário',
        description: 'Acolha pets de ONGs até a adoção',
        icon: Icons.home_work_rounded,
        customBadgeText: 'VOLUNTÁRIO',
        customBadgeColor: Colors.blueAccent,
        iconColor: Colors.blueAccent,
        iconBgColor: Colors.blueAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          VolunteerTemporaryHomeSheet.show(context);
        },
      ),

      // 5. Feiras & Eventos (Encontros e Adoções Presenciais)
      _GridCard(
        title: 'Feiras & Eventos',
        description: 'Feiras de adoção e encontros pet',
        icon: Icons.campaign_rounded,
        customBadgeText: 'PRESENCIAL',
        customBadgeColor: Colors.deepPurpleAccent,
        iconColor: Colors.deepPurpleAccent,
        iconBgColor: Colors.deepPurpleAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const OngEventsDashboardScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OngEventsDashboardScreen(),
              ),
            );
          }
        },
      ),

      // 6. Resgates & Alertas (Rede Solidária de Socorro a Animais em Risco)
      _GridCard(
        title: 'Resgates & Alertas',
        description: 'Reporte e acompanhe animais em risco',
        icon: Icons.emergency_rounded,
        customBadgeText: 'SOS REGIONAL',
        customBadgeColor: Colors.redAccent,
        iconColor: Colors.redAccent,
        iconBgColor: Colors.redAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const OngRescueAlertsScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OngRescueAlertsScreen(),
              ),
            );
          }
        },
      ),

      // 5. Patas Love
      _LoveGridCard(
        isDesktop: isDesktop,
        onTap: () => _handleLoveAccess(context),
      ),

      // 4. Patas História
      _GridCard(
        title: 'História',
        description: 'Linha do tempo e memórias do seu pet',
        icon: Icons.auto_stories_outlined,
        showSoonBadge: false,
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop && desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const PatasHistoricaPage(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PatasHistoricaPage(),
              ),
            );
          }
        },
      ),

      // 5. Patas Friendly
      _FriendlyGridCard(isDesktop: isDesktop),

      // 6. Patas Encontra
      _EncontraGridCard(isDesktop: isDesktop),

      // 7. Patas Shop
      _GridCard(
        title: 'Shop',
        description: 'Mimos, Ração & Acessórios',
        icon: Icons.storefront_outlined,
        showSoonBadge: true,
        isDesktop: isDesktop,
        onTap: () {},
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // 🏠 VISÃO DA ONG & ABRIGO (PATAS ACOLHE)
  // ─────────────────────────────────────────────

  Widget _buildOngHeroCard(BuildContext context, {required bool isDesktop}) {
    return _HeroCard(
      title: 'Central de Adoção',
      description: isDesktop
          ? 'Gerencie os animais acolhidos, fichas de resgate, histórico de castração e formulários de adotantes interessados em tempo real.'
          : 'Animais acolhidos, resgates e adotantes',
      icon: Icons.volunteer_activism_rounded,
      iconColor: Colors.white,
      backgroundColor: const Color(0xFF7C3AED), // Roxo moderno e empático
      isDesktop: isDesktop,
      onTap: () {
        bottomNavIndexNotifier.value = 3;
      },
    );
  }

  List<Widget> _buildOngGridCards({bool isDesktop = false}) {
    return [
      _GridCard(
        title: 'Mural de Doações',
        description: 'PIX direto e campanhas de ração',
        icon: Icons.handshake_rounded,
        customBadgeText: 'PIX DIRETO',
        customBadgeColor: Colors.pinkAccent,
        iconColor: Colors.pinkAccent,
        iconBgColor: Colors.pinkAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const OngDonationsDashboardScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OngDonationsDashboardScreen(),
              ),
            );
          }
        },
      ),
      _GridCard(
        title: 'Prontuário Coletivo',
        description: 'Lotes de vacinas e castrações',
        icon: Icons.assignment_turned_in_rounded,
        customBadgeText: 'SAÚDE',
        customBadgeColor: Colors.tealAccent,
        iconColor: Colors.teal,
        iconBgColor: Colors.teal.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const OngCollectiveMedicalScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OngCollectiveMedicalScreen(),
              ),
            );
          }
        },
      ),
      _GridCard(
        title: 'Alertas da Região',
        description: 'Animais em risco e resgates',
        icon: Icons.warning_amber_rounded,
        customBadgeText: 'REGIONAL',
        customBadgeColor: Colors.redAccent,
        iconColor: Colors.redAccent,
        iconBgColor: Colors.redAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const OngRescueAlertsScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OngRescueAlertsScreen(),
              ),
            );
          }
        },
      ),
      _GridCard(
        title: 'Lares Temporários',
        description: 'Banco de voluntários da rede',
        icon: Icons.home_work_rounded,
        customBadgeText: 'VOLUNTÁRIOS',
        customBadgeColor: Colors.blueAccent,
        iconColor: Colors.blueAccent,
        iconBgColor: Colors.blueAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const OngTemporaryHomesScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OngTemporaryHomesScreen(),
              ),
            );
          }
        },
      ),
      _GridCard(
        title: 'Eventos & Feiras',
        description: 'Divulgue feirinhas no feed',
        icon: Icons.campaign_rounded,
        customBadgeText: 'DIVULGAÇÃO',
        customBadgeColor: Colors.deepPurpleAccent,
        iconColor: Colors.deepPurpleAccent,
        iconBgColor: Colors.deepPurpleAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop &&
              desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => const OngEventsDashboardScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OngEventsDashboardScreen(),
              ),
            );
          }
        },
      ),
      _GridCard(
        title: 'Espaços Parceiros',
        description: 'Locais pet friendly parceiros',
        icon: Icons.place_rounded,
        iconColor: Colors.teal,
        iconBgColor: Colors.teal.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () {
          if (context.isDesktop && desktopContentNavigatorKey.currentState != null) {
            desktopContentNavigatorKey.currentState!.push(
              MaterialPageRoute(builder: (context) => const FriendlyDashboardScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FriendlyDashboardScreen()),
            );
          }
        },
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // 💼 VISÃO DA EMPRESA / PROFISSIONAL (PATAS NEGÓCIOS)
  // ─────────────────────────────────────────────

  Widget _buildCompanyHeroCard(BuildContext context, {required bool isDesktop}) {
    return _HeroCard(
      title: 'Agenda & Atendimentos',
      description: isDesktop
          ? 'Visualize e gerencie os atendimentos do dia, sessões de adestramento agendadas, horários disponíveis e solicitações de tutores.'
          : 'Sessões, consultas e horários marcados',
      icon: Icons.calendar_month_rounded,
      iconColor: Colors.white,
      backgroundColor: const Color(0xFF0D9488), // Teal profissional
      isDesktop: isDesktop,
      onTap: () => _showModulePreviewDialog(
        context,
        title: 'Agenda Profissional & Atendimentos 📅',
        subtitle: 'Gestão de horários de treino e serviços',
        description:
            'Acompanhe as sessões agendadas com os tutores, defina seus dias e horários de atendimento disponíveis e receba confirmações de presença com lembretes automáticos.',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF0D9488),
        features: const [
          'Calendário interativo com status por cliente',
          'Notificações push antes da sessão para tutor e profissional',
          'Reprogramação e cancelamento simplificado',
          'Histórico de sessões realizadas',
        ],
      ),
    );
  }

  List<Widget> _buildCompanyGridCards({bool isDesktop = false}) {
    return [
      _GridCard(
        title: 'Meus Serviços',
        description: 'Modalidades de treino e valores',
        icon: Icons.tune_rounded,
        customBadgeText: 'CATÁLOGO',
        customBadgeColor: Colors.tealAccent,
        iconColor: const Color(0xFF0D9488),
        iconBgColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () => _showModulePreviewDialog(
          context,
          title: 'Catálogo de Serviços & Tarifas 🐕',
          subtitle: 'Configure suas modalidades de atendimento',
          description:
              'Cadastre as modalidades que você oferece como adestrador ou especialista (ex: Obediência, Xixi/Cocô, Reatividade, Consultoria Online), definindo valor, duração e formato.',
          icon: Icons.tune_rounded,
          color: const Color(0xFF0D9488),
          features: const [
            'Modalidades presenciais a domicílio ou online',
            'Definição de preço avulso ou pacotes mensais',
            'Descrição detalhada da metodologia de treino',
            'Ativação/desativação instantânea de vagas',
          ],
        ),
      ),
      _GridCard(
        title: 'Fichas de Alunos',
        description: 'Diário de treino e evolução',
        icon: Icons.folder_shared_rounded,
        customBadgeText: 'RELATÓRIOS',
        customBadgeColor: Colors.blueAccent,
        iconColor: Colors.blueAccent,
        iconBgColor: Colors.blueAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () => _showModulePreviewDialog(
          context,
          title: 'Fichas de Alunos & Pacientes 📁',
          subtitle: 'Diário de evolução comportamental',
          description:
              'Registre notas de evolução após cada aula (*"Rex aprendeu o fica com distrações"*), atribua lições de casa para o tutor praticar e compartilhe relatórios automáticos.',
          icon: Icons.folder_shared_rounded,
          color: Colors.blueAccent,
          features: const [
            'Histórico de comandos e metas alcançadas',
            'Lição de casa enviada diretamente para o app do tutor',
            'Anotações privadas do profissional',
            'Anexos de fotos e vídeos de progresso',
          ],
        ),
      ),
      _GridCard(
        title: 'Faturamento',
        description: 'Cobranças PIX e Cartão Asaas',
        icon: Icons.payments_rounded,
        customBadgeText: 'ASAAS',
        customBadgeColor: Colors.greenAccent,
        iconColor: Colors.green.shade700,
        iconBgColor: Colors.green.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () => _showModulePreviewDialog(
          context,
          title: 'Cobranças & Faturamento Asaas 💳',
          subtitle: 'Receba de forma rápida e segura',
          description:
              'Emita cobranças e links de pagamento integrados ao gateway Asaas. O tutor pode pagar via PIX instantâneo ou cartão parcelado, com liberação automática de saldo.',
          icon: Icons.payments_rounded,
          color: Colors.green.shade700,
          features: const [
            'Geração de PIX com QR Code dinâmico',
            'Parcelamento em cartão com repasse seguro',
            'Controle de pagamentos pendentes e confirmados',
            'Sem necessidade de maquininha física',
          ],
        ),
      ),
      _GridCard(
        title: 'Avaliações',
        description: 'Reputação e reviews verificados',
        icon: Icons.star_rounded,
        customBadgeText: 'REPUTAÇÃO',
        customBadgeColor: Colors.amberAccent,
        iconColor: Colors.amber.shade800,
        iconBgColor: Colors.amber.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () => _showModulePreviewDialog(
          context,
          title: 'Avaliações & Reputação ⭐',
          subtitle: 'Prova social de tutores reais',
          description:
              'Veja as avaliações com nota (1 a 5 estrelas) e depoimentos deixados por tutores que concluíram sessões com você, aumentando a confiança e atraindo novos clientes.',
          icon: Icons.star_rounded,
          color: Colors.amber.shade800,
          features: const [
            'Avaliações apenas de clientes que concluíram serviços',
            'Comentários com fotos de antes e depois',
            'Selo de profissional verificado',
            'Destaque no topo das buscas da região',
          ],
        ),
      ),
      _GridCard(
        title: 'Alcance Local',
        description: 'Raio de atendimento na cidade',
        icon: Icons.radar_rounded,
        customBadgeText: 'GEOLOCALIZAÇÃO',
        customBadgeColor: Colors.purpleAccent,
        iconColor: Colors.purpleAccent,
        iconBgColor: Colors.purpleAccent.withValues(alpha: 0.15),
        isDesktop: isDesktop,
        onTap: () => _showModulePreviewDialog(
          context,
          title: 'Alcance & Raio de Atendimento 📢',
          subtitle: 'Visibilidade para tutores próximos',
          description:
              'Defina os bairros e cidades onde você atende a domicílio ou o endereço do seu centro de treinamento/loja física para ser recomendado automaticamente.',
          icon: Icons.radar_rounded,
          color: Colors.purpleAccent,
          features: const [
            'Raio de atuação configurável em quilômetros',
            'Recomendação no feed de tutores da vizinhança',
            'Estatísticas de visualizações do perfil profissional',
            'Link direto para contato pelo chat ou WhatsApp',
          ],
        ),
      ),
      _GridCard(
        title: 'Produtos & Loja',
        description: 'Rações, petiscos e mimos',
        icon: Icons.storefront_rounded,
        showSoonBadge: true,
        isDesktop: isDesktop,
        onTap: () {},
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // 💡 DIÁLOGO MODERNO DE APRESENTAÇÃO DO MÓDULO
  // ─────────────────────────────────────────────

  void _showModulePreviewDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    final isDark = thmode.darkMode;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header com Ícone Destacado
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Descrição
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Título de Recursos Planejados
                  Text(
                    'RECURSOS DESTE MÓDULO',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: color,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Lista de Features
                  ...features.map((feat) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: color,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feat,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 24),

                  // Botão de Entendido
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Entendido 👍',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLoveAccess(BuildContext context) {
    final activePet = Provider.of<ActivePetProvider>(
      context,
      listen: false,
    ).activePet;

    if (activePet == null) {
      _showLoveDialog(
        context,
        title: 'Nenhum Pet Selecionado',
        content:
            'Por favor, selecione um pet ativo no perfil para acessar o Patas Love.',
        icon: Icons.pets,
        iconColor: Colors.orange,
      );
      return;
    }

    final species = activePet.species.toLowerCase().trim();
    final isDogOrCat =
        species == 'cão' ||
        species == 'cao' ||
        species == 'cachorro' ||
        species == 'gato' ||
        species == 'felino' ||
        species == 'canino';

    if (!isDogOrCat) {
      _showLoveDialog(
        context,
        title: 'Espécie Incompatível',
        content:
            'O Patas Love está disponível no momento apenas para cães e gatos. Em breve traremos novidades para outras espécies!',
        icon: Icons.info_outline,
        iconColor: Colors.amber,
      );
      return;
    }

    if (!activePet.isLoveActive) {
      _showLoveDialog(
        context,
        title: 'Ativação Pendente',
        content:
            'Para utilizar o Patas Love, você precisa ativar a opção "Disponível para Patas Love" no perfil de ${activePet.name}.',
        icon: Icons.favorite_border_rounded,
        iconColor: Colors.pinkAccent,
        buttonText: 'Ir para Perfil',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(pet: activePet),
            ),
          );
        },
      );
      return;
    }

    if (context.isDesktop && desktopContentNavigatorKey.currentState != null) {
      desktopContentNavigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const PatasLoveMainScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PatasLoveMainScreen()),
      );
    }
  }

  void _showLoveDialog(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    String buttonText = 'Entendi',
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  color: AppColors.patasColor,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onPressed != null) {
                onPressed();
              }
            },
            child: Text(
              buttonText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: thmode.darkMode ? Colors.white : AppColors.darkBG,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool isDesktop;

  const _HeroCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 28 : 24),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isDesktop ? 28 : 24),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20,
              vertical: isDesktop ? 34 : 24,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: isDesktop ? 48 : 36,
                    color: iconColor,
                  ),
                ),
                SizedBox(width: isDesktop ? 32 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: isDesktop ? 32 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 13,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'CONHECER',
                      style: TextStyle(
                        color: AppColors.patasColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool showSoonBadge;
  final VoidCallback onTap;
  final bool isDesktop;
  final Color? iconColor;
  final Color? iconBgColor;
  final String? customBadgeText;
  final Color? customBadgeColor;

  const _GridCard({
    required this.title,
    required this.description,
    required this.icon,
    this.showSoonBadge = false,
    required this.onTap,
    this.isDesktop = false,
    this.iconColor,
    this.iconBgColor,
    this.customBadgeText,
    this.customBadgeColor,
  });

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);

    // Cores baseadas no tema e no estado de hover
    final baseColor = thmode.darkMode ? AppColors.darkBG : Colors.white;
    final cardColor = widget.isDesktop
        ? (thmode.darkMode
              ? baseColor.withValues(alpha: _isHovered ? 0.8 : 0.6)
              : baseColor.withValues(alpha: _isHovered ? 0.95 : 0.8))
        : (thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight);

    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;
    final subtitleColor = thmode.darkMode ? Colors.white60 : Colors.black54;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: widget.isDesktop
                ? Border.all(
                    color: thmode.darkMode
                        ? Colors.white.withValues(alpha: _isHovered ? 0.2 : 0.1)
                        : Colors.black.withValues(
                            alpha: _isHovered ? 0.1 : 0.05,
                          ),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: thmode.darkMode
                      ? (_isHovered ? 0.3 : 0.15)
                      : (_isHovered ? 0.12 : 0.05),
                ),
                blurRadius: _isHovered ? 25 : 15,
                spreadRadius: _isHovered ? 0 : -2,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onTap,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isDesktop ? 16 : 12,
                      vertical: widget.isDesktop ? 16 : 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(widget.isDesktop ? 8 : 6),
                          decoration: BoxDecoration(
                            color: widget.iconBgColor ??
                                (widget.iconColor ?? AppColors.patasColor)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            size: widget.isDesktop ? 28 : 24,
                            color: widget.iconColor ?? AppColors.patasColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: widget.isDesktop ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.description,
                                  style: TextStyle(
                                    fontSize: widget.isDesktop ? 11 : 10,
                                    color: subtitleColor,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.customBadgeText != null)
                    Positioned(
                      top: widget.isDesktop ? 14 : 10,
                      right: widget.isDesktop ? 14 : 10,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: widget.isDesktop ? 120 : 78,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isDesktop ? 10 : 6,
                            vertical: widget.isDesktop ? 5 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: (widget.customBadgeColor ?? AppColors.patasColor)
                                .withValues(alpha: _isHovered ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (widget.customBadgeColor ?? AppColors.patasColor)
                                  .withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.customBadgeText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.customBadgeColor ?? AppColors.patasColor,
                              fontSize: widget.isDesktop ? 10 : 8.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (widget.showSoonBadge)
                    Positioned(
                      top: widget.isDesktop ? 14 : 10,
                      right: widget.isDesktop ? 14 : 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isDesktop ? 10 : 8,
                          vertical: widget.isDesktop ? 5 : 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.patasColor.withValues(
                            alpha: _isHovered ? 0.25 : 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Em breve',
                          style: TextStyle(
                            color: AppColors.patasColor,
                            fontSize: widget.isDesktop ? 10 : 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                          ),
                        ),
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
}

class _EncontraGridCard extends StatefulWidget {
  final bool isDesktop;
  const _EncontraGridCard({this.isDesktop = false});

  @override
  State<_EncontraGridCard> createState() => _EncontraGridCardState();
}

class _EncontraGridCardState extends State<_EncontraGridCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    final subtitleColor = Colors.white.withValues(alpha: 0.85);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.15),
                blurRadius: _isHovered ? 25 : 15,
                spreadRadius: _isHovered ? 0 : -2,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  if (context.isDesktop && desktopContentNavigatorKey.currentState != null) {
                    desktopContentNavigatorKey.currentState!.push(
                      MaterialPageRoute(builder: (context) => const TutorEncontraDashboard()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TutorEncontraDashboard()),
                    );
                  }
                },
                child: Stack(
                  children: [
                    // Fundo da imagem/GIF
                    Positioned.fill(
                      child: Image.asset(
                        'assets/patas_essencial/patas_encontra.gif',
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradiente de overlay para escurecer e dar legibilidade
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Conteúdo
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isDesktop ? 16 : 12,
                        vertical: widget.isDesktop ? 16 : 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ícone de Radar com efeito pulsante
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                padding: EdgeInsets.all(widget.isDesktop ? 8 : 6),
                                decoration: BoxDecoration(
                                  color: AppColors.patasColor.withValues(
                                    alpha: 0.25,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.patasColor.withValues(
                                      alpha: 0.3 + 0.7 * _pulseController.value,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.patasColor.withValues(
                                        alpha: 0.15 * _pulseController.value,
                                      ),
                                      blurRadius: 8 * _pulseController.value,
                                      spreadRadius: 2 * _pulseController.value,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.radar,
                                  size: widget.isDesktop ? 28 : 24,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Patas Encontra',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: widget.isDesktop ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 6,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tecnologia de busca ativa',
                                    style: TextStyle(
                                      fontSize: widget.isDesktop ? 11 : 10,
                                      color: subtitleColor,
                                      height: 1.2,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de ATIVO com ponto verde pulsante
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: _isHovered ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(
                                      alpha: 0.3 + 0.7 * _pulseController.value,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981)
                                            .withValues(
                                              alpha:
                                                  0.5 * _pulseController.value,
                                            ),
                                        blurRadius: 4 * _pulseController.value,
                                        spreadRadius:
                                            1 * _pulseController.value,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ATIVO',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendlyGridCard extends StatefulWidget {
  final bool isDesktop;
  const _FriendlyGridCard({this.isDesktop = false});

  @override
  State<_FriendlyGridCard> createState() => _FriendlyGridCardState();
}

class _FriendlyGridCardState extends State<_FriendlyGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    final subtitleColor = Colors.white.withValues(alpha: 0.85);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.15),
                blurRadius: _isHovered ? 25 : 15,
                spreadRadius: _isHovered ? 0 : -2,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  if (context.isDesktop && desktopContentNavigatorKey.currentState != null) {
                    desktopContentNavigatorKey.currentState!.push(
                      MaterialPageRoute(builder: (context) => const FriendlyDashboardScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FriendlyDashboardScreen()),
                    );
                  }
                },
                child: Stack(
                  children: [
                    // Fundo da imagem/GIF
                    Positioned.fill(
                      child: Image.asset(
                        'assets/patas_essencial/patas_friendly.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradiente de overlay para escurecer e dar legibilidade
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Conteúdo
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isDesktop ? 16 : 12,
                        vertical: widget.isDesktop ? 16 : 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(widget.isDesktop ? 8 : 6),
                            decoration: BoxDecoration(
                              color: AppColors.patasColor.withValues(
                                alpha: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.patasColor.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.place_outlined,
                              size: widget.isDesktop ? 28 : 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Patas Friendly',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: widget.isDesktop ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 6,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Locais próximos p/ ir junto',
                                    style: TextStyle(
                                      fontSize: widget.isDesktop ? 11 : 10,
                                      color: subtitleColor,
                                      height: 1.2,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de ATIVO
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: _isHovered ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ATIVO',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoveGridCard extends StatefulWidget {
  final bool isDesktop;
  final VoidCallback onTap;

  const _LoveGridCard({required this.onTap, this.isDesktop = false});

  @override
  State<_LoveGridCard> createState() => _LoveGridCardState();
}

class _LoveGridCardState extends State<_LoveGridCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _heartPulseController;

  @override
  void initState() {
    super.initState();
    _heartPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heartPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    final subtitleColor = Colors.white.withValues(alpha: 0.85);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withValues(
                  alpha: _isHovered ? 0.4 : 0.15,
                ),
                blurRadius: _isHovered ? 25 : 15,
                spreadRadius: _isHovered ? 0 : -2,
                offset: Offset(0, _isHovered ? 10 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: widget.onTap,
                child: Stack(
                  children: [
                    // Fundo animado com particulas subindo (coracoes, simbolos masculino e feminino)
                    const Positioned.fill(child: _AnimatedLoveBackground()),
                    // Conteúdo
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isDesktop ? 16 : 12,
                        vertical: widget.isDesktop ? 16 : 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedBuilder(
                            animation: _heartPulseController,
                            builder: (context, child) {
                              return Container(
                                padding: EdgeInsets.all(widget.isDesktop ? 8 : 6),
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent.withValues(
                                    alpha: 0.25,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.pinkAccent.withValues(
                                      alpha:
                                          0.4 +
                                          0.6 * _heartPulseController.value,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pinkAccent.withValues(
                                        alpha:
                                            0.2 * _heartPulseController.value,
                                      ),
                                      blurRadius:
                                          8 * _heartPulseController.value,
                                      spreadRadius:
                                          2 * _heartPulseController.value,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  size: widget.isDesktop ? 28 : 24,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Patas Love',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: widget.isDesktop ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 6,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Encontros & acasalamento',
                                    style: TextStyle(
                                      fontSize: widget.isDesktop ? 11 : 10,
                                      color: subtitleColor,
                                      height: 1.2,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de NOVO com brilho rosa
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(
                            alpha: _isHovered ? 0.3 : 0.2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.pinkAccent.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.favorite_rounded,
                              size: 10,
                              color: Colors.pinkAccent,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'NOVO',
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Fredoka',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLoveBackground extends StatefulWidget {
  const _AnimatedLoveBackground();

  @override
  State<_AnimatedLoveBackground> createState() =>
      _AnimatedLoveBackgroundState();
}

class _AnimatedLoveBackgroundState extends State<_AnimatedLoveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LoveParticlesPainter(_controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _LoveParticleData {
  final double initialX;
  final double initialY;
  final double speed;
  final double size;
  final double opacity;
  final String text;
  final Color color;
  final double swayPhase;

  _LoveParticleData({
    required this.initialX,
    required this.initialY,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.text,
    required this.color,
    required this.swayPhase,
  });
}

class _LoveParticlesPainter extends CustomPainter {
  final double progress;

  static final List<_LoveParticleData> _particles = [
    _LoveParticleData(
      initialX: 0.15,
      initialY: 0.2,
      speed: 1.0,
      size: 16,
      opacity: 0.85,
      text: '♥',
      color: Colors.pinkAccent,
      swayPhase: 0.0,
    ),
    _LoveParticleData(
      initialX: 0.35,
      initialY: 0.6,
      speed: 1.2,
      size: 18,
      opacity: 0.9,
      text: '♂',
      color: Colors.lightBlueAccent,
      swayPhase: 1.5,
    ),
    _LoveParticleData(
      initialX: 0.65,
      initialY: 0.4,
      speed: 0.9,
      size: 18,
      opacity: 0.9,
      text: '♀',
      color: Colors.pinkAccent,
      swayPhase: 0.8,
    ),
    _LoveParticleData(
      initialX: 0.85,
      initialY: 0.8,
      speed: 1.1,
      size: 14,
      opacity: 0.75,
      text: '♥',
      color: Colors.pink,
      swayPhase: 2.1,
    ),
    _LoveParticleData(
      initialX: 0.25,
      initialY: 0.9,
      speed: 0.8,
      size: 16,
      opacity: 0.8,
      text: '♀',
      color: Colors.purpleAccent,
      swayPhase: 1.1,
    ),
    _LoveParticleData(
      initialX: 0.75,
      initialY: 0.1,
      speed: 1.3,
      size: 17,
      opacity: 0.85,
      text: '♂',
      color: Colors.cyanAccent,
      swayPhase: 2.8,
    ),
    _LoveParticleData(
      initialX: 0.50,
      initialY: 0.75,
      speed: 1.0,
      size: 20,
      opacity: 0.95,
      text: '♥',
      color: Colors.pinkAccent,
      swayPhase: 0.5,
    ),
    _LoveParticleData(
      initialX: 0.10,
      initialY: 0.5,
      speed: 1.15,
      size: 13,
      opacity: 0.7,
      text: '✨',
      color: Colors.amberAccent,
      swayPhase: 1.9,
    ),
    _LoveParticleData(
      initialX: 0.90,
      initialY: 0.3,
      speed: 0.95,
      size: 15,
      opacity: 0.8,
      text: '✨',
      color: Colors.pinkAccent,
      swayPhase: 0.3,
    ),
    _LoveParticleData(
      initialX: 0.40,
      initialY: 0.35,
      speed: 1.05,
      size: 16,
      opacity: 0.85,
      text: '♂',
      color: Colors.blueAccent,
      swayPhase: 0.9,
    ),
    _LoveParticleData(
      initialX: 0.60,
      initialY: 0.85,
      speed: 0.95,
      size: 16,
      opacity: 0.85,
      text: '♀',
      color: Colors.pinkAccent,
      swayPhase: 2.4,
    ),
  ];

  _LoveParticlesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fundo Gradiente Romântico Escuro
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF380829), // Magenta profundo
          Color(0xFF1B0418), // Quase preto roxo
          Color(0xFF0F020C),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Glow Radial central
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.pinkAccent.withValues(alpha: 0.25), Colors.transparent],
        radius: 0.85,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), radialPaint);

    // 2. Desenho das partículas flutuantes subindo (corações, masculino ♂ e feminino ♀)
    for (final p in _particles) {
      final currentY = (p.initialY - (progress * p.speed)) % 1.0;
      final actualY = (currentY < 0 ? currentY + 1.0 : currentY) * size.height;
      final sway = math.sin((progress * 2 * math.pi) + p.swayPhase) * 10;
      final actualX = (p.initialX * size.width) + sway;

      // Opacidade suavizada nas bordas superiores/inferiores
      double alpha = p.opacity;
      if (actualY < 25) {
        alpha *= (actualY / 25).clamp(0.0, 1.0);
      } else if (actualY > size.height - 25) {
        alpha *= ((size.height - actualY) / 25).clamp(0.0, 1.0);
      }

      final textSpan = TextSpan(
        text: p.text,
        style: TextStyle(
          fontSize: p.size,
          color: p.color.withValues(alpha: alpha),
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: p.color.withValues(alpha: 0.7 * alpha),
              blurRadius: 10,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          actualX - textPainter.width / 2,
          actualY - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LoveParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
