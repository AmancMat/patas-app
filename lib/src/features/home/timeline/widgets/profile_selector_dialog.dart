import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/corp_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/main.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';

class PublishProfile {
  final String id;
  final String name;
  final String? photoUrl;
  final String type; // 'pet', 'ong', 'company'

  PublishProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.type,
  });
}

class ProfileSelectorDialog extends StatefulWidget {
  const ProfileSelectorDialog({super.key});

  @override
  State<ProfileSelectorDialog> createState() => _ProfileSelectorDialogState();
}

class _ProfileSelectorDialogState extends State<ProfileSelectorDialog> {
  final OngService _ongService = OngService();
  final CorpService _corpService = CorpService();
  List<PublishProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final activePet =
          Provider.of<ActivePetProvider>(context, listen: false).activePet;

      List<PublishProfile> allProfiles = [];

      // 1. Adicionar Pet Ativo
      if (activePet != null) {
        allProfiles.add(PublishProfile(
          id: activePet.id,
          name: activePet.name,
          photoUrl: activePet.photoUrl,
          type: 'pet',
        ));
      }

      // 2. Adicionar ONGs
      final ongs = await _ongService.getUserOngProfiles(user.id);
      for (var ong in ongs) {
        allProfiles.add(PublishProfile(
          id: ong.id,
          name: ong.name,
          photoUrl: ong.photoUrl,
          type: 'ong',
        ));
      }

      // 3. Adicionar Empresas
      final corps = await _corpService.getUserCorpProfiles(user.id);
      for (var corp in corps) {
        allProfiles.add(PublishProfile(
          id: corp.id,
          name: corp.name,
          photoUrl: corp.photoUrl,
          type: 'company',
        ));
      }

      if (mounted) {
        setState(() {
          _profiles = allProfiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfis para publicação: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.isWide ? 500 : double.infinity,
        ),
        child: Container(
          padding: context.isWide
              ? const EdgeInsets.all(24)
              : EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: thmode.darkMode ? AppColors.darkBG : Colors.white,
            borderRadius: context.isWide
                ? BorderRadius.circular(16)
                : BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publicar como...',
            style: TextStyle(
              fontSize: context.isWide ? 18 : 20.sp,
              fontWeight: FontWeight.bold,
              color: thmode.darkMode ? Colors.white : AppColors.darkBG,
            ),
          ),
          SizedBox(height: context.isWide ? 16 : 20.h),
          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: AppColors.patasColor))
          else if (_profiles.isEmpty)
            const Center(child: Text('Nenhum perfil encontrado.'))
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _profiles.length,
                separatorBuilder: (context, index) => Divider(
                  color: thmode.darkMode ? Colors.white24 : Colors.grey[300],
                ),
                itemBuilder: (context, index) {
                  final profile = _profiles[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: context.isWide ? 22 : 25.r,
                      backgroundImage: profile.photoUrl != null &&
                              profile.photoUrl!.isNotEmpty
                          ? NetworkImage(profile.photoUrl!)
                          : const AssetImage('assets/image_placeholder.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      profile.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    subtitle: Text(
                      profile.type == 'pet'
                          ? 'Pet'
                          : (profile.type == 'ong'
                              ? 'ONG / Abrigo'
                              : 'Empresa'),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: context.isWide ? 11 : 12.sp,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, profile),
                  );
                },
              ),
            ),
            SizedBox(height: context.isWide ? 10 : 20.h),
        ],
      ),
    ),
  ),
);
  }
}
