import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';

class OverlappingProfileAvatars extends StatelessWidget {
  final ActiveAccount? activeAccount;
  final ActiveAccount? previousAccount;
  final double size;

  const OverlappingProfileAvatars({
    super.key,
    required this.activeAccount,
    required this.previousAccount,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    // Se não tiver conta anterior, mostra apenas a ativa centralizada
    if (previousAccount == null || previousAccount?.id == activeAccount?.id) {
      return _buildProfileAvatar(context, activeAccount, size);
    }

    final avatarSize = size * 0.8; // Mais compacto
    final stackWidth = size * 1.15; // Centros mais próximos
    final stackHeight = size * 1.0; // Centros alinhados na altura

    return SizedBox(
      width: stackWidth,
      height: stackHeight,
      child: Stack(
        children: [
          // Avatar Secundário (Atrás) - Canto superior esquerdo
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.patasColor.withValues(alpha: 0.7),
                  width: 1.0,
                ),
              ),
              child: _buildProfileAvatar(context, previousAccount, avatarSize),
            ),
          ),
          // Avatar Ativo (Frente) - Canto inferior direito
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.patasColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(-1, 1),
                  ),
                ],
              ),
              child: _buildProfileAvatar(context, activeAccount, avatarSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
      BuildContext context, ActiveAccount? account, double size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBG : Colors.white;

    if (account == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: bgColor,
        child:
            Icon(Icons.person, size: size * 0.6, color: AppColors.patasColor),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      backgroundImage: account.photoUrl != null && account.photoUrl!.isNotEmpty
          ? NetworkImage(account.photoUrl!)
          : null,
      child: account.photoUrl == null || account.photoUrl!.isEmpty
          ? Icon(
              _getProfileIcon(account.type),
              color: AppColors.patasColor,
              size: size * 0.6,
            )
          : null,
    );
  }

  IconData _getProfileIcon(AccountType type) {
    switch (type) {
      case AccountType.user:
        return Icons.person_rounded;
      case AccountType.pet:
        return Icons.pets_rounded;
      case AccountType.ong:
      case AccountType.company:
        return Icons.store_rounded;
    }
  }
}
