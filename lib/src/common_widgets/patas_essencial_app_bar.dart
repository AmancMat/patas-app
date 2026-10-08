import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../../app.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import '../constants/app_colors.dart';
import '../features/pets/widgets/active_pet_header_chip.dart';

/// Widget unificado de AppBar para os microapps e seções do Patas Essencial e Patas Acolhe.
/// 
/// Garante:
/// 1. Alinhamento proporcional ao body no Desktop (conteúdo contido em maxWidth,
///    evitando que títulos e botões fiquem colados nas extremidades do monitor).
/// 2. Padrão estrito de botão de voltar oficial (Icons.arrow_back_ios_new_rounded, AppColors.patasColor).
/// 3. Proibição de botões de fechar (X) redundantes em telas de navegação.
/// 4. Suporte consistente a DarkMode, subtítulos e slots inferiores (abas / busca).
class PatasEssencialAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leadingIcon;
  final List<Widget>? actions;
  final Widget? bottomWidget;
  final double bottomHeight;
  final bool showBackButton;
  final bool showPetSelector;
  final bool compactPetSelector;
  final VoidCallback? onBack;
  final double? maxWidth;
  final double? desktopHorizontalPadding;

  const PatasEssencialAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.actions,
    this.bottomWidget,
    this.bottomHeight = 48.0,
    this.showBackButton = true,
    this.showPetSelector = true,
    this.compactPetSelector = false,
    this.onBack,
    this.maxWidth,
    this.desktopHorizontalPadding,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottomWidget != null ? bottomHeight : 0.0) + 1.0,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkMode>(context).darkMode;
    final canPop = Navigator.of(context).canPop();
    final isDesktop = context.isDesktop;
    final effectiveMaxWidth = maxWidth ?? 1200.0;
    final effectiveDesktopPadding = desktopHorizontalPadding ?? 24.0;

    // ─────────────────────────────────────────────────────────────
    // 💻 LAYOUT DESKTOP — Conteúdo alinhado e contido na mesma largura do Body
    // ─────────────────────────────────────────────────────────────
    if (isDesktop) {
      return AppBar(
        backgroundColor: isDark ? AppColors.bodygray : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: effectiveDesktopPadding),
              child: Row(
                children: [
                  if (showBackButton && canPop) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.patasColor,
                        size: 20,
                      ),
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                      tooltip: context.tr('common.back'),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            color: isDark ? Colors.white : AppColors.patasColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight((bottomWidget != null ? bottomHeight : 0.0) + 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (bottomWidget != null)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: effectiveDesktopPadding),
                      child: bottomWidget!,
                    ),
                  ),
                ),
              Container(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
                height: 1,
              ),
            ],
          ),
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────
    // 📱 LAYOUT MOBILE & TABLET — Largura fluida natural da tela
    // ─────────────────────────────────────────────────────────────
    return AppBar(
      backgroundColor: isDark ? AppColors.bodygray : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: showBackButton && canPop
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.patasColor,
                size: 20,
              ),
              onPressed: onBack ?? () => Navigator.maybePop(context),
              tooltip: context.tr('common.back'),
            )
          : null,
      title: Row(
        children: [
          if (leadingIcon != null) ...[
            leadingIcon!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: isDark ? Colors.white : AppColors.patasColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (showPetSelector && !context.isDesktop) ...[
          Center(
            child: ActivePetHeaderChip(
              compact: compactPetSelector && context.isMobile,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (actions != null) ...actions!,
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight((bottomWidget != null ? bottomHeight : 0.0) + 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bottomWidget != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: bottomWidget!,
              ),
            Container(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
              height: 1,
            ),
          ],
        ),
      ),
    );
  }
}
