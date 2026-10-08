import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/utils/to_publish_page.dart';

import 'package:patas_web_app/src/localization/localizations_ext.dart';

/// ==============================================================================
/// WIDGET QUICK POST DO PATAS (ESTILO FACEBOOK) — POSICIONADO ACIMA DOS STORIES
/// ==============================================================================
class HomeQuickPostCard extends StatelessWidget {
  const HomeQuickPostCard({super.key});

  void _openPublish(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ToPublishPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Consumer<ActiveAccountProvider>(
      builder: (context, activeProvider, _) {
        final activeAccount = activeProvider.activeAccount;
        final photoUrl = activeAccount?.photoUrl;

        final inputBorderColor =
            isDark ? Colors.white24 : const Color(0xFFD0D0D0);
        final hintColor = isDark ? Colors.white54 : const Color(0xFF757575);

        return Container(
          margin: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.transparent,
          child: Row(
            children: [
              // 1. Avatar do Pet Ativo
              GestureDetector(
                onTap: () => _openPublish(context),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor:
                      isDark ? Colors.white24 : Colors.grey.shade300,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(Icons.pets, size: 16, color: AppColors.patasColor)
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              // 2. Campo de Texto Convidativo (Cápsula Input sem background)
              Expanded(
                child: GestureDetector(
                  onTap: () => _openPublish(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: inputBorderColor,
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      context.tr('feed.quick_post_hint'),
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13,
                        color: hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Botão (+ Postar) em Cápsula Laranja
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openPublish(context),
                  child: Ink(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.patasColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.patasColor.withValues(alpha: 0.35),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('feed.quick_post_action'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
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
}
