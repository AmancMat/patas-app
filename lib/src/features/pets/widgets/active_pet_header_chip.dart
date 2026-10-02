import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/features/home/widgets/profile_switcher_bottom_sheet.dart';

class ActivePetHeaderChip extends StatelessWidget {
  final bool compact;
  const ActivePetHeaderChip({super.key, this.compact = false});

  void _openProfileSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileSwitcherBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final accProvider = Provider.of<ActiveAccountProvider>(context);
    final activeAccount = accProvider.activeAccount;
    final activePetProvider = Provider.of<ActivePetProvider>(context);
    final activePet = activePetProvider.activePet;

    // Configurações visuais dinâmicas pelo tipo de conta ativa
    final Color badgeColor;
    final IconData defaultIcon;
    final String displayName;
    final String? photoUrl;

    if (activeAccount?.type == AccountType.ong) {
      badgeColor = Colors.purpleAccent;
      defaultIcon = Icons.volunteer_activism_rounded;
      displayName = activeAccount!.name;
      photoUrl = activeAccount.photoUrl;
    } else if (activeAccount?.type == AccountType.company) {
      badgeColor = Colors.teal;
      defaultIcon = Icons.store_rounded;
      displayName = activeAccount!.name;
      photoUrl = activeAccount.photoUrl;
    } else if (activeAccount?.type == AccountType.user) {
      badgeColor = AppColors.patasColor;
      defaultIcon = Icons.person_rounded;
      displayName = activeAccount?.name ?? 'Perfil Pessoal';
      photoUrl = activeAccount?.photoUrl;
    } else {
      // Caso padrão: Pet ativo (AccountType.pet ou fallback)
      badgeColor = AppColors.patasColor;
      defaultIcon = Icons.pets_rounded;
      displayName = activePet?.name ?? activeAccount?.name ?? 'Meu Pet';
      photoUrl = activePet?.photoUrl ?? activeAccount?.photoUrl;
    }

    return InkWell(
      onTap: () => _openProfileSwitcher(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: badgeColor,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Icon(defaultIcon, color: Colors.white, size: 12)
                  : null,
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: badgeColor,
            ),
          ],
        ),
      ),
    );
  }
}

