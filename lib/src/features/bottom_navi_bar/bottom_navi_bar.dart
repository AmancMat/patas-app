import 'package:patas_web_app/src/features/bottom_navi_bar/widgets/bottom_fluid_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/health/pet_health.dart';
import 'package:patas_web_app/src/features/acolhe/screens/ong_animals_dashboard_screen.dart';
import 'package:patas_web_app/src/features/health/screens/vet/vet_dashboard_screen.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/features/home/home_page.dart';
import 'package:patas_web_app/src/features/marketplace/marketplace_page_v2.dart';
import 'package:patas_web_app/src/features/search/search_page.dart';
import 'package:patas_web_app/src/features/settings/settings_page.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import 'package:patas_web_app/src/features/bottom_navi_bar/web_sidebar.dart';

class BottomNaviBar extends StatefulWidget {
  const BottomNaviBar({super.key});

  @override
  State<BottomNaviBar> createState() => _BottomNaviBarState();
}

class _BottomNaviBarState extends State<BottomNaviBar> {
  /// Retorna as páginas dinamicamente de acordo com o perfil ativo
  List<Widget> _getPages(AccountType? accountType) {
    final Widget fourthPage;
    if (accountType == AccountType.ong) {
      fourthPage = const OngAnimalsDashboardScreen(
        key: ValueKey('ong_animals_dashboard'),
      );
    } else if (accountType == AccountType.company) {
      fourthPage = const VetDashboardScreen(
        key: ValueKey('vet_dashboard'),
      );
    } else {
      fourthPage = const PetHealthPage(
        key: ValueKey('pet_health'),
      );
    }

    return [
      const SearchPage(),
      const MarketplacePageV2(),
      const HomePage(),
      fourthPage,
      const SettingsPage(),
    ];
  }

  @override
  void initState() {
    super.initState();
  }

  void _onNavigate(int index) {
    if (desktopContentNavigatorKey.currentState?.canPop() == true) {
      desktopContentNavigatorKey.currentState!.popUntil((route) => route.isFirst);
    }
    if (index == 2) {
      homeTabIndexNotifier.value = 1;
    }
    bottomNavIndexNotifier.value = index;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final thmode = Provider.of<DarkMode>(context);
    final bgColor = thmode.darkMode
        ? AppColors.bodygray
        : const Color(0xffF5F5F5);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (desktopContentNavigatorKey.currentState?.canPop() ?? false) {
          desktopContentNavigatorKey.currentState?.pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: !isDesktop,
        bottomNavigationBar: isDesktop
            ? null
            : ValueListenableBuilder<int>(
                valueListenable: bottomNavIndexNotifier,
                builder: (context, navIndex, _) {
                  return BottomFluidTabBar(
                    currentIndex: navIndex,
                    onTap: _onNavigate,
                    isDark: thmode.darkMode,
                  );
                },
              ),
        body: Stack(
          children: [
            // 1. Conteúdo principal persistente (compartilhado entre desktop e mobile)
            ValueListenableBuilder<bool>(
              valueListenable: isSidebarCollapsedNotifier,
              builder: (context, isCollapsed, _) {
                final double leftPadding = isDesktop
                    ? (isCollapsed ? 80.0 : 220.0)
                    : 0.0;
                return Padding(
                  padding: EdgeInsets.only(left: leftPadding),
                  child: Navigator(
                    key: desktopContentNavigatorKey,
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) {
                          return Consumer<ActiveAccountProvider>(
                            builder: (context, accProvider, _) {
                              final activeAcc = accProvider.activeAccount;
                              final pages = _getPages(activeAcc?.type);

                              return ValueListenableBuilder<int>(
                                valueListenable: bottomNavIndexNotifier,
                                builder: (context, navIndex, _) {
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    switchInCurve: Curves.easeIn,
                                    switchOutCurve: Curves.easeOut,
                                    transitionBuilder:
                                        (Widget child, Animation<double> animation) {
                                      return FadeTransition(
                                          opacity: animation, child: child);
                                    },
                                    child: SizedBox(
                                      key: ValueKey<String>(
                                          '${navIndex}_${navIndex == 3 ? activeAcc?.type.name : ''}'),
                                      child: pages[navIndex],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),

            // 2. WebSidebar por cima (desenhada apenas no modo Desktop)
            if (isDesktop)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ValueListenableBuilder<int>(
                  valueListenable: homeTabIndexNotifier,
                  builder: (context, homeTabIndex, _) {
                    return ValueListenableBuilder<int>(
                      valueListenable: bottomNavIndexNotifier,
                      builder: (context, navIndex, _) {
                        return WebSidebar(
                          currentNavIndex: navIndex,
                          currentHomeTabIndex: homeTabIndex,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
