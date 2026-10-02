import 'package:flutter/material.dart';

/// Breakpoints centralizados para o Patas Web.
///
/// mobile  → largura < 600 px
/// tablet  → 600 px ≤ largura < 1024 px
/// desktop → largura ≥ 1024 px
class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  /// Largura máxima do feed central em desktop.
  static const double feedMaxWidth = 680;

  /// Largura do painel lateral direito em desktop.
  static const double rightPanelWidth = 280;

  /// Largura da NavigationRail em desktop.
  static const double navRailWidth = 80;
}

/// Extensão no [BuildContext] para verificar o breakpoint atual.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  bool get isMobile => screenWidth < Breakpoints.tablet;
  bool get isTablet =>
      screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// Retorna true para qualquer tela mais larga que mobile.
  bool get isWide => screenWidth >= Breakpoints.tablet;
}

/// Widget que exibe um filho diferente dependendo do breakpoint.
///
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileWidget(),
///   tablet: TabletWidget(),  // opcional — usa mobile se omitido
///   desktop: DesktopWidget(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return desktop;
    if (context.isTablet) return tablet ?? mobile;
    return mobile;
  }
}
