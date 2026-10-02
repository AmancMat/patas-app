import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/story_publish_provider.dart';

/// Banner global flutuante no topo da tela para indicar o progresso
/// de otimização e publicação de Stories em segundo plano.
class StoryPublishBannerWrapper extends StatelessWidget {
  final Widget child;

  const StoryPublishBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryPublishProvider>(
      builder: (context, provider, _) {
        final showBanner = provider.state != StoryPublishState.idle;

        Color bannerBg;
        Color borderColor;
        IconData bannerIcon;
        Color iconColor;

        switch (provider.state) {
          case StoryPublishState.success:
            bannerBg = const Color(0xFF1B5E20).withValues(alpha: 0.95);
            borderColor = const Color(0xFF4CAF50);
            bannerIcon = Icons.check_circle_rounded;
            iconColor = const Color(0xFF81C784);
            break;
          case StoryPublishState.error:
            bannerBg = const Color(0xFFB71C1C).withValues(alpha: 0.95);
            borderColor = const Color(0xFFEF5350);
            bannerIcon = Icons.error_outline_rounded;
            iconColor = const Color(0xFFFF8A80);
            break;
          case StoryPublishState.optimizing:
          case StoryPublishState.uploading:
          default:
            bannerBg = const Color(0xFF1E1E24).withValues(alpha: 0.95);
            borderColor = AppColors.patasColor.withValues(alpha: 0.6);
            bannerIcon = Icons.cloud_upload_rounded;
            iconColor = AppColors.patasColor;
            break;
        }

        return Stack(
          children: [
            child,
            // Banner flutuante no topo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  offset: showBanner ? Offset.zero : const Offset(0, -1.2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: showBanner ? 1.0 : 0.0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: bannerBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Ícone ou Spinner
                            if (provider.isPublishing)
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  value: provider.progress > 0
                                      ? provider.progress
                                      : null,
                                  strokeWidth: 2.5,
                                  color: AppColors.patasColor,
                                  backgroundColor: Colors.white24,
                                ),
                              )
                            else
                              Icon(bannerIcon, color: iconColor, size: 22),

                            const SizedBox(width: 12),

                            // Texto e Subtítulo
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.isError
                                        ? (provider.errorMessage ??
                                            'Erro ao publicar story')
                                        : provider.statusMessage,
                                    style: const TextStyle(
                                      fontFamily: 'Fredoka',
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (provider.isPublishing) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Você pode continuar usando o app normalmente',
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 11,
                                        fontWeight: FontWeight.normal,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Botão de fechar se for erro
                            if (provider.isError) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => provider.dismiss(),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                            ],
                          ],
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
