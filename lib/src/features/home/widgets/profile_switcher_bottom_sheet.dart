import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/corp_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/providers/profile_view_provider.dart';
import 'package:patas_web_app/app.dart';

class ProfileSwitcherBottomSheet extends StatefulWidget {
  final bool isDialog;
  const ProfileSwitcherBottomSheet({super.key, this.isDialog = false});

  @override
  State<ProfileSwitcherBottomSheet> createState() =>
      _ProfileSwitcherBottomSheetState();
}

class _ProfileSwitcherBottomSheetState
    extends State<ProfileSwitcherBottomSheet> {
  final PetService _petService = PetService();
  final OngService _ongService = OngService();
  final CorpService _corpService = CorpService();

  List<ActiveAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      List<ActiveAccount> allAccounts = [];

      // 1. Perfil Pessoal (Usuário)
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      allAccounts.add(ActiveAccount(
        id: user.id,
        name: userData?['name'] ?? 'Meu Perfil',
        photoUrl: userData?['photo_url'],
        type: AccountType.user,
      ));

      // 2. Meus Pets
      final pets = await _petService.getPetsByUserId(user.id);
      for (var pet in pets) {
        allAccounts.add(ActiveAccount(
          id: pet.id,
          name: pet.name,
          photoUrl: pet.photoUrl,
          type: AccountType.pet,
        ));
      }

      // 3. Minhas ONGs
      final ongs = await _ongService.getUserOngProfiles(user.id);
      for (var ong in ongs) {
        allAccounts.add(ActiveAccount(
          id: ong.id,
          name: ong.name,
          photoUrl: ong.photoUrl,
          type: AccountType.ong,
        ));
      }

      // 4. Minhas Empresas/Corps
      final corps = await _corpService.getUserCorpProfiles(user.id);
      for (var corp in corps) {
        allAccounts.add(ActiveAccount(
          id: corp.id,
          name: corp.name,
          photoUrl: corp.photoUrl,
          type: AccountType.company,
        ));
      }

      if (mounted) {
        setState(() {
          _accounts = allAccounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar contas: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activeAccountProvider = Provider.of<ActiveAccountProvider>(context);
    final activePetProvider =
        Provider.of<ActivePetProvider>(context, listen: false);
    final currentAccount = activeAccountProvider.activeAccount;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        widget.isDialog ? 24 : 20.w,
        widget.isDialog ? 24 : 12.h,
        widget.isDialog ? 24 : 20.w,
        (widget.isDialog ? 24 : 16.h) + bottomInset,
      ),
      decoration: BoxDecoration(
        color: thmode.darkMode ? AppColors.darkBG : Colors.white,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(24)
            : BorderRadius.only(
                topLeft: Radius.circular(25.r),
                topRight: Radius.circular(25.r),
              ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle no topo quando mobile
          if (!widget.isDialog)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: thmode.darkMode ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trocar Perfil',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: widget.isDialog ? 20 : 18.sp,
                  fontWeight: FontWeight.bold,
                  color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.patasColor),
              ),
            )
          else if (_accounts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Nenhuma conta encontrada.'),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _accounts.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: thmode.darkMode ? Colors.white10 : Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  final isSelected = currentAccount?.id == account.id &&
                      currentAccount?.type == account.type;
                  final accountColor = _getTypeColor(account.type);

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: widget.isDialog ? 8 : 4.h,
                    ),
                    leading: CircleAvatar(
                      radius: widget.isDialog ? 24 : 22.r,
                      backgroundColor: accountColor.withValues(alpha: 0.15),
                      backgroundImage: account.photoUrl != null &&
                              account.photoUrl!.isNotEmpty
                          ? NetworkImage(account.photoUrl!)
                          : null,
                      child:
                          account.photoUrl == null || account.photoUrl!.isEmpty
                              ? Icon(
                                  _getProfileIcon(account.type),
                                  color: accountColor,
                                  size: widget.isDialog ? 26 : 22.r,
                                )
                              : null,
                    ),
                    title: Text(
                      account.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                    subtitle: Text(
                      _getTypeLabel(account.type),
                      style: TextStyle(
                        fontSize: widget.isDialog ? 13 : 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: accountColor)
                        : null,
                    onTap: () async {
                      await activeAccountProvider.setActiveAccount(account,
                          petProvider: activePetProvider);
                      if (context.mounted) {
                        Provider.of<ProfileViewProvider>(context,
                                listen: false)
                            .clear();
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          if (widget.isDialog) const SizedBox(height: 12) else SizedBox(height: 12.h),
        ],
      ),
    );
  }

  String _getTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.user:
        return 'Perfil Pessoal';
      case AccountType.pet:
        return 'Pet';
      case AccountType.ong:
        return 'ONG / Instituição';
      case AccountType.company:
        return 'Empresa';
    }
  }

  IconData _getProfileIcon(AccountType type) {
    switch (type) {
      case AccountType.user:
        return Icons.person_rounded;
      case AccountType.pet:
        return Icons.pets_rounded;
      case AccountType.ong:
        return Icons.volunteer_activism_rounded;
      case AccountType.company:
        return Icons.store_rounded;
    }
  }

  Color _getTypeColor(AccountType type) {
    switch (type) {
      case AccountType.user:
      case AccountType.pet:
        return AppColors.patasColor;
      case AccountType.ong:
        return Colors.purpleAccent;
      case AccountType.company:
        return Colors.teal;
    }
  }
}
