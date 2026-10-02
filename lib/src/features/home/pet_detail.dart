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

class PetDetail extends StatelessWidget {
  const PetDetail({super.key});

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return '$age anos';
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePetProvider = Provider.of<ActivePetProvider>(context);
    final Pet? activePet = activePetProvider.activePet;

    if (activePet == null) {
      return Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSkeletonRow(thmode, 'Idade: '),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, 'Raça: '),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, 'Gênero: '),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, 'Porte: '),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, 'Peso: '),
            const SizedBox(height: 5),
            _buildSkeletonRow(thmode, 'Sangue: '),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildDetailRow(
          thmode,
          'Idade: ',
          activePet.birthDate != null
              ? _calculateAge(activePet.birthDate!)
              : 'N/I',
        ),
        _buildDetailRow(thmode, 'Raça: ', activePet.breed ?? 'N/I'),
        _buildDetailRow(thmode, 'Gênero: ', activePet.gender ?? 'N/I'),
        _buildDetailRow(thmode, 'Porte: ', activePet.size ?? 'N/I'),
        _buildDetailRow(
          thmode,
          'Peso: ',
          activePet.weight != null ? '${activePet.weight}kg' : 'N/I',
        ),
        _buildDetailRow(thmode, 'Sangue: ', activePet.bloodType ?? 'N/I'),
        const SizedBox(height: 4),
        FutureBuilder<PetPassport?>(
          future: PetPassportService.getExistingPassport(activePet.id),
          builder: (context, snapshot) {
            final passport = snapshot.data;
            final isMinted = passport != null;

            return InkWell(
              onTap: () async {
                if (isMinted) {
                  PetPassportDetailSheet.show(context, passport: passport);
                } else {
                  PetPassportOnboardingDialog.show(context, pet: activePet);
                }
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
                      isMinted ? 'cNFT Verificado' : 'Emitir cNFT',
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
