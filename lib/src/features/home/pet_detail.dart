import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../app.dart';
import '../../constants/app_colors.dart';
import '../solana/models/pet_passport_model.dart';
import '../solana/services/pet_passport_service.dart';
import '../solana/widgets/pet_passport_detail_sheet.dart';
import '../solana/widgets/pet_passport_onboarding_dialog.dart';

import 'package:patas_web_app/src/localization/localizations_ext.dart';

class PetDetail extends StatelessWidget {
  final Pet? pet;
  final bool isOwner;

  const PetDetail({
    super.key,
    this.pet,
    this.isOwner = true,
  });

  String _calculateAge(BuildContext context, DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    if (age <= 1) {
      return context.tr('profile.one_year_old');
    }
    return context.tr('profile.years_old', {'count': '$age'});
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePetProvider = Provider.of<ActivePetProvider>(context);
    final Pet? activePet = pet ?? activePetProvider.activePet;

    if (activePet == null) {
      return Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSkeletonRow(thmode, context.tr('profile.age_label')),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, context.tr('profile.breed_label')),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, context.tr('profile.gender_label')),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, context.tr('profile.size_label')),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, context.tr('profile.weight_label')),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, context.tr('profile.blood_label')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildDetailRow(
          thmode,
          context.tr('profile.age_label'),
          activePet.birthDate != null
              ? _calculateAge(context, activePet.birthDate!)
              : 'N/I',
        ),
        _buildDetailRow(thmode, context.tr('profile.breed_label'), activePet.breed ?? 'N/I'),
        _buildDetailRow(thmode, context.tr('profile.gender_label'), activePet.gender ?? 'N/I'),
        _buildDetailRow(thmode, context.tr('profile.size_label'), activePet.size ?? 'N/I'),
        _buildDetailRow(
          thmode,
          context.tr('profile.weight_label'),
          activePet.weight != null ? '${activePet.weight}kg' : 'N/I',
        ),
        _buildDetailRow(thmode, context.tr('profile.blood_label'), activePet.bloodType ?? 'N/I'),
        const SizedBox(height: 4),
        ValueListenableBuilder<int>(
          valueListenable: PetPassportService.passportChangeNotifier,
          builder: (context, _, __) {
            return FutureBuilder<PetPassport?>(
              future: PetPassportService.getExistingPassport(activePet.id),
              builder: (context, snapshot) {
                final passport = snapshot.data;
                final isMinted = passport != null;

                // Se o usuário logado é o DONO do pet:
                if (isOwner) {
                  return InkWell(
                    onTap: () async {
                      if (isMinted) {
                        await PetPassportDetailSheet.show(context, passport: passport, isOwner: isOwner);
                      } else {
                        await PetPassportOnboardingDialog.show(context, pet: activePet);
                      }
                      PetPassportService.notifyPassportChanged();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMinted
                              ? const [Color(0xFF9945FF), Color(0xFF14F195)]
                              : const [Color(0xFF6B21A8), Color(0xFF9945FF)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMinted ? Icons.verified_rounded : Icons.auto_awesome_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMinted ? context.tr('profile.cnft_verified') : context.tr('profile.cnft_issue'),
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Se o usuário NÃO É O DONO do pet (visitante vendo perfil de outro pet):
                // Não permite ação (somente leitura informativa).
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMinted
                        ? const Color(0xFF9945FF).withValues(alpha: 0.15)
                        : (thmode.darkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    border: Border.all(
                      color: isMinted
                          ? const Color(0xFF9945FF).withValues(alpha: 0.4)
                          : (thmode.darkMode ? Colors.white24 : Colors.black12),
                      width: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMinted ? Icons.verified_rounded : Icons.info_outline_rounded,
                        size: 11,
                        color: isMinted
                            ? const Color(0xFF9945FF)
                            : (thmode.darkMode ? Colors.white54 : Colors.black45),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMinted ? context.tr('profile.cnft_registered') : context.tr('profile.cnft_none'),
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isMinted
                              ? (thmode.darkMode ? Colors.white : const Color(0xFF9945FF))
                              : (thmode.darkMode ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSkeletonRow(DarkMode thmode, String label) {
    return Skeleton.replace(
      child: Text(
        '$label     ',
        style: TextStyle(
          color: thmode.darkMode ? Colors.white : AppColors.darkBG,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto_flex',
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDetailRow(DarkMode thmode, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.patasColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto_flex',
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: thmode.darkMode ? Colors.white70 : AppColors.darkBG,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto_flex',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
