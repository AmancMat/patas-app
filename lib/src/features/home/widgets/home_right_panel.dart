import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/utils/to_publish_page.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import 'package:patas_web_app/app.dart';

/// Painel lateral direito exibido exclusivamente em desktop (≥ 1024 px).
/// Mostra um card de resumo da conta ativa e um botão de publicar.
class HomeRightPanel extends StatelessWidget {
  const HomeRightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Garantia extra: só renderiza em desktop
    if (!context.isDesktop) return const SizedBox.shrink();

    final thmode = Provider.of<DarkMode>(context);
    final panelBg = thmode.darkMode
        ? const Color(0xff1a1a1a)
        : const Color(0xffFAFAFA);
    final borderColor =
        thmode.darkMode ? Colors.white10 : Colors.grey.shade200;
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;
    final subTextColor = thmode.darkMode ? Colors.white54 : Colors.grey;

    return Container(
      width: Breakpoints.rightPanelWidth,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card da conta ativa ───────────────────────────────────
              _ActiveAccountCard(
                thmode: thmode,
                textColor: textColor,
                subTextColor: subTextColor,
                panelBg: panelBg,
              ),
              const SizedBox(height: 16),
              // ── Botão de publicar ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.1),
                      builder: (context) => const Dialog(
                        insetPadding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        child: ToPublishPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.tr('home.new_post_btn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ── Divisor ──────────────────────────────────────────────
              Divider(color: borderColor),
              const SizedBox(height: 12),
              // ── Dica rápida ───────────────────────────────────────────
              _QuickTip(textColor: textColor, subTextColor: subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card de conta ativa
// ─────────────────────────────────────────────
class _ActiveAccountCard extends StatelessWidget {
  final DarkMode thmode;
  final Color textColor;
  final Color subTextColor;
  final Color panelBg;

  const _ActiveAccountCard({
    required this.thmode,
    required this.textColor,
    required this.subTextColor,
    required this.panelBg,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveAccountProvider>(
      builder: (context, provider, child) {
        final account = provider.activeAccount;
        if (account == null) {
          return const SizedBox(
            height: 80,
            child: Center(
                child: CircularProgressIndicator(color: AppColors.patasColor)),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: thmode.darkMode ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: thmode.darkMode
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    AppColors.patasColor.withValues(alpha: 0.15),
                backgroundImage: account.photoUrl != null &&
                        account.photoUrl!.isNotEmpty
                    ? NetworkImage(account.photoUrl!) as ImageProvider
                    : null,
                child: account.photoUrl == null || account.photoUrl!.isEmpty
                    ? Icon(
                        _iconFor(account.type),
                        color: AppColors.patasColor,
                        size: 26,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _labelFor(context, account.type),
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconFor(AccountType type) {
    switch (type) {
      case AccountType.pet:
        return Icons.pets_rounded;
      case AccountType.ong:
      case AccountType.company:
        return Icons.store_rounded;
      case AccountType.user:
        return Icons.person_rounded;
    }
  }

  String _labelFor(BuildContext context, AccountType type) {
    switch (type) {
      case AccountType.user:
        return context.tr('home.account_personal');
      case AccountType.pet:
        return context.tr('home.account_pet');
      case AccountType.ong:
        return context.tr('home.account_ong');
      case AccountType.company:
        return context.tr('home.account_corp');
    }
  }
}

// ─────────────────────────────────────────────
// Dica rápida no painel lateral
// ─────────────────────────────────────────────
class _QuickTip extends StatelessWidget {
  final Color textColor;
  final Color subTextColor;

  const _QuickTip({required this.textColor, required this.subTextColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline,
                size: 16, color: AppColors.patasColor),
            const SizedBox(width: 6),
            Text(
              context.tr('home.patas_tip_title'),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('home.patas_tip_desc'),
          style: TextStyle(
            color: subTextColor,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
