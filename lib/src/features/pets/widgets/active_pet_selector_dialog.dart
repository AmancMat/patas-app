import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/pets_create/create_pet_page.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/features/home/widgets/profile_switcher_bottom_sheet.dart';
import 'package:patas_web_app/src/providers/profile_view_provider.dart';

class ActivePetSelectorDialog extends StatefulWidget {
  const ActivePetSelectorDialog({super.key});

  /// Abre a lista completa de perfis (Pets, ONGs, Empresas e Pessoal)
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileSwitcherBottomSheet(),
    );
  }

  /// Abre estritamente o seletor exclusivo de pets (ex: agendamento de treino)
  static void showPetsOnly(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ActivePetSelectorDialog(),
    );
  }

  @override
  State<ActivePetSelectorDialog> createState() => _ActivePetSelectorDialogState();
}

class _ActivePetSelectorDialogState extends State<ActivePetSelectorDialog> {
  final PetService _petService = PetService();
  List<Pet> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPets();
  }

  Future<void> _loadUserPets() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final pets = await _petService.getPetsByUserId(user.id);
      if (mounted) {
        setState(() {
          _pets = pets;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar lista de pets no seletor: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final activePetProvider = Provider.of<ActivePetProvider>(context);
    final activePet = activePetProvider.activePet;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 20 + bottomInset),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle indicador de arrasto
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.patasColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: AppColors.patasColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Selecione o Pet Ativo',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppColors.patasColor)),
            )
          else if (_pets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum pet cadastrado.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _pets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  final isSelected = activePet?.id == pet.id;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.patasColor.withValues(alpha: isDark ? 0.18 : 0.08)
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.patasColor
                            : (isDark ? Colors.white10 : Colors.black12),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
                        backgroundImage: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                            ? NetworkImage(pet.photoUrl!)
                            : null,
                        child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                            ? const Icon(Icons.pets, color: AppColors.patasColor, size: 20)
                            : null,
                      ),
                      title: Text(
                        pet.name,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      subtitle: Text(
                        '${pet.species.toUpperCase()} ${pet.breed != null ? "• ${pet.breed}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.patasColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ativo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () async {
                        activePetProvider.setActivePet(pet);
                        final accProvider = Provider.of<ActiveAccountProvider>(context, listen: false);
                        await accProvider.setActiveAccount(
                          ActiveAccount(
                            id: pet.id,
                            name: pet.name,
                            type: AccountType.pet,
                            photoUrl: pet.photoUrl,
                          ),
                          petProvider: activePetProvider,
                        );
                        if (context.mounted) {
                          Provider.of<ProfileViewProvider>(context, listen: false).clear();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Botão Cadastrar Novo Pet
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute(builder: (context) => const CreatePetPage(species: 'Cão')),
                );
              },
              icon: const Icon(Icons.add_rounded, color: AppColors.patasColor),
              label: const Text(
                'Cadastrar Novo Pet 🐾',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                  color: AppColors.patasColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.patasColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}
}
