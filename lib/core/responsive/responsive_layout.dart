import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

/// Constrói layouts diferentes com base nos breakpoints
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

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1100) return DeviceType.desktop;
    if (width >= 650) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktop;
        } else if (constraints.maxWidth >= 650) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Um wrapper global para App Web que expande fluidamente e
/// evita overflow em telas minúsculas escalonando para baixo.
class ResponsiveAppWrapper extends StatelessWidget {
  final Widget child;
  final double minWidth;

  const ResponsiveAppWrapper({
    super.key,
    required this.child,
    this.minWidth = 360, // Celular pequeno - limite para iniciar escala, evitando overflow
  });

  @override
  Widget build(BuildContext context) {
    // Desativado temporariamente o FittedBox para evitar o desalinhamento geométrico
    // de coordenadas lógicas e físicas que inutiliza cliques sob leitores de tela na Web.
    return child;
  }
}
