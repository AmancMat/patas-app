import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/providers/connectivity_provider.dart';

/// Banner global não-intrusivo de conectividade.
/// 
/// Fica fixo no topo do app e desliza suavemente para baixo quando
/// a conexão cai de verdade (após debounce), sem bloquear o uso da tela.
class ConnectivityBannerWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        final isOffline = connectivity.isOffline;
        final wasReconnected = connectivity.wasReconnected;
        final isChecking = connectivity.isChecking;
        final showBanner = isOffline || wasReconnected;

        final Color bannerBg = isOffline
            ? const Color(0xFFC0392B)
            : const Color(0xFF27AE60);

        final IconData bannerIcon = isOffline
            ? (isChecking ? Icons.sync_rounded : Icons.wifi_off_rounded)
            : Icons.wifi_rounded;

        final String bannerText = isOffline
            ? (isChecking ? 'Verificando conexão...' : 'Sem conexão • Toque para reconectar')
            : 'Conexão restabelecida';

        return Stack(
          children: [
            child,
            // Banner animado superior
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: IgnorePointer(
                  ignoring: !showBanner,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    offset: showBanner ? Offset.zero : const Offset(0, -1.2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: showBanner ? 1.0 : 0.0,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: (isOffline && !isChecking)
                              ? () => connectivity.checkConnectionNow(isTransition: true)
                              : null,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: bannerBg,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(bannerIcon, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    bannerText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
