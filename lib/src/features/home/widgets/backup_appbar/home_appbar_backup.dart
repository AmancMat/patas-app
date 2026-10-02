import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/features/home/notifications/notifications_page.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';
import 'package:patas_web_app/src/utils/to_publish_page.dart';
import 'package:patas_web_app/src/features/home/widgets/profile_switcher_bottom_sheet.dart';
import 'package:patas_web_app/src/features/home/widgets/overlapping_profile_avatars.dart';

/// ==============================================================================
/// BACKUP DE SEGURANÇA — APPBAR DA HOME (Versão Clássica)
/// ==============================================================================
/// Este arquivo armazena a implementação exata da AppBar da Home que era usada
/// antes do redesign das abas em formato de gota e botão em cápsula.
/// 
/// Data do Backup: 02/09/2026
/// Componentes incluídos:
/// - SliverAppBar com título "Patas" e botões (Notificação, Troca de Pet, Publish)
/// - TabBar tradicional com aba do Perfil e aba "Time Line"
/// - Botão de Notificação com badge contador
/// - Botão de trocar perfil / pet ativo (OverlappingProfileAvatars)
/// - Botão quadrado de publicação (+)
/// ==============================================================================

class HomeAppBarBackup {
  /// Construtor da SliverAppBar clássica do MobileLayout
  static Widget buildClassicSliverAppBar({
    required BuildContext context,
    required DarkMode thmode,
    required Color headerBg,
    required bool innerBoxIsScrolled,
    required TabController tabController,
    required Widget profileTab,
  }) {
    return SliverAppBar(
      elevation: 0,
      toolbarHeight: 40,
      backgroundColor: headerBg,
      automaticallyImplyLeading: false,
      floating: true,  // reaparece ao rolar para cima
      pinned: true,    // mantém o bottom (TabBar) sempre visível
      snap: true,      // completa a animação ao soltar o scroll
      forceElevated: innerBoxIsScrolled,
      title: Text(
        'Patas',
        style: TextStyle(
          color: thmode.darkMode ? Colors.white : AppColors.patasColor,
          fontWeight: FontWeight.bold,
          fontFamily: 'Fredoka',
          fontSize: 20,
        ),
      ),
      actions: [
        buildNotificationIcon(context: context),
        buildProfileSwitcherButton(context: context),
        const SizedBox(width: 4),
        buildPublishButton(context: context),
      ],
      bottom: PreferredSize(
        preferredSize: const Size(double.infinity, 50),
        child: SizedBox(
          height: 50,
          child: TabBar(
            indicatorColor: AppColors.patasColor,
            controller: tabController,
            tabs: [
              profileTab,
              Tab(
                icon: Material(
                  elevation: 4.0,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.hardEdge,
                  color: Colors.transparent,
                  child: Ink.image(
                    image: const AssetImage('assets/feed.png'),
                    fit: BoxFit.cover,
                    width: 20,
                    height: 20,
                  ),
                ),
                child: Text(
                  'Time Line',
                  style: TextStyle(
                    color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ícone clássico de notificações com badge
  static Widget buildNotificationIcon({
    required BuildContext context,
    Color iconColor = AppColors.patasColor,
  }) {
    return StreamBuilder<int>(
      stream: SupabaseNotificationService().unreadCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notificações',
              icon: Icon(Icons.notifications_none_outlined, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Botão clássico de trocar perfil / pet ativo
  static Widget buildProfileSwitcherButton({required BuildContext context}) {
    return Consumer<ActiveAccountProvider>(
      builder: (context, provider, child) {
        return IconButton(
          tooltip: 'Trocar perfil',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => const ProfileSwitcherBottomSheet(),
            );
          },
          icon: OverlappingProfileAvatars(
            activeAccount: provider.activeAccount,
            previousAccount: provider.previousAccount,
            size: 34,
          ),
        );
      },
    );
  }

  /// Botão quadrado clássico de publicação (+)
  static Widget buildPublishButton({required BuildContext context}) {
    return Semantics(
      button: true,
      label: 'Criar nova publicação',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ToPublishPage()),
          );
        },
        child: Container(
          height: 27,
          width: 27,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.patasColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
