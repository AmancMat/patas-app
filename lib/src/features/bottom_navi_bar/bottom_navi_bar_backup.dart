import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/health/pet_health.dart';
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
  final _pageController = PageController(
    initialPage: bottomNavIndexNotifier.value,
  );

  int _currentIndex = bottomNavIndexNotifier.value;

  /// Widget list
  final List<Widget> _pages = const [
    SearchPage(),
    MarketplacePageV2(),
    HomePage(),
    PetHealthPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    bottomNavIndexNotifier.addListener(_handleNavChange);
  }

  void _handleNavChange() {
    if (mounted) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(bottomNavIndexNotifier.value);
      }
      setState(() => _currentIndex = bottomNavIndexNotifier.value);
    }
  }

  void _onNavigate(int index) {
    if (index == 2) {
      homeTabIndexNotifier.value = 1;
    }
    if (bottomNavIndexNotifier.value != index) {
      bottomNavIndexNotifier.value = index;
    } else if (_currentIndex != index) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
      setState(() => _currentIndex = index);
    }
  }

  @override
  void dispose() {
    bottomNavIndexNotifier.removeListener(_handleNavChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  // ─────────────────────────────────────────────
  // MOBILE / TABLET — AnimatedNotchBottomBar
  // ─────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: AnimatedNotchBottomBar(
          pageController: _pageController,
          showBlurBottomBar: false,
          color: thmode.darkMode ? AppColors.darkBG : Colors.white,
          notchColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
          bottomBarItems: [
            BottomBarItem(
              inActiveItem: SvgPicture.asset('assets/icons/search.svg'),
              activeItem: SvgPicture.asset('assets/icons/search.svg'),
            ),
            BottomBarItem(
              inActiveItem: SvgPicture.asset('assets/icons/essential.svg'),
              activeItem: SvgPicture.asset('assets/icons/essential.svg'),
            ),
            BottomBarItem(
              inActiveItem: SvgPicture.asset('assets/icons/home.svg'),
              activeItem: SvgPicture.asset('assets/icons/home.svg'),
            ),
            BottomBarItem(
              inActiveItem: SvgPicture.asset(
                'assets/icons/patas_saude_out.svg',
              ),
              activeItem: SvgPicture.asset('assets/icons/patas_saude.svg'),
            ),
            BottomBarItem(
              inActiveItem: SvgPicture.asset('assets/icons/settings.svg'),
              activeItem: SvgPicture.asset('assets/icons/settings.svg'),
            ),
          ],
          onTap: _onNavigate,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DESKTOP — NavigationRail lateral + conteúdo
  // ─────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
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
        body: Stack(
          children: [
            // 1. Conteúdo principal no fundo com margem esquerda animada
            ValueListenableBuilder<bool>(
              valueListenable: isSidebarCollapsedNotifier,
              builder: (context, isCollapsed, _) {
                final double leftPadding = isCollapsed ? 80.0 : 220.0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(left: leftPadding),
                  child: Navigator(
                    key: desktopContentNavigatorKey,
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) {
                          return ValueListenableBuilder<int>(
                            valueListenable: bottomNavIndexNotifier,
                            builder: (context, navIndex, _) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeIn,
                                switchOutCurve: Curves.easeOut,
                                transitionBuilder:
                                    (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: SizedBox(
                                  key: ValueKey<int>(navIndex),
                                  child: _pages[navIndex],
                                ),
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
            // 2. WebSidebar por cima (desenhada por último e 100% estática)
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
