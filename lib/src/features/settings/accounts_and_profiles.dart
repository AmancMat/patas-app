import 'package:flutter/material.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/pets_create/add_kind_page.dart';
import 'package:patas_web_app/src/features/pets/pets_edit/edit_pet_page.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/corp_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/create_ong_profile.dart';
import 'package:patas_web_app/src/features/ongs_corp/create_corp_profile.dart';
import 'package:patas_web_app/src/features/ongs_corp/edit_ong_profile.dart';
import 'package:patas_web_app/src/features/ongs_corp/edit_corp_profile.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../main.dart';

class AccountsAndProfile extends StatefulWidget {
  final bool isDialog;
  const AccountsAndProfile({super.key, this.isDialog = false});

  @override
  State<AccountsAndProfile> createState() => _AccountsAndProfileState();
}

class _AccountsAndProfileState extends State<AccountsAndProfile> {
  final PetService _petService = PetService();
  final OngService _ongService = OngService();
  final CorpService _corpService = CorpService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<Pet> _userPets = [];
  List<OngProfile> _userOngs = [];
  List<CorpProfile> _userCorps = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // 1. Fetch User Profile
        final userResponse =
            await supabase.from('users').select().eq('id', user.id).single();

        // 2. Fetch User Pets
        final pets = await _petService.getPetsByUserId(user.id);

        // 3. Fetch User ONGs
        final ongs = await _ongService.getUserOngProfiles(user.id);

        // 4. Fetch User Companies
        final corps = await _corpService.getUserCorpProfiles(user.id);

        if (mounted) {
          setState(() {
            _userData = userResponse;
            _userPets = pets;
            _userOngs = ongs;
            _userCorps = corps;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading account data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProfile(String id, String type, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir $type'),
        content: Text(
            'Tem certeza que deseja excluir o perfil de "$name"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        if (type == 'Pet') {
          await _petService.deletePet(id);
        } else if (type == 'ONG') {
          await _ongService.deleteOngProfile(id);
        } else if (type == 'Empresa') {
          await _corpService.deleteCorpProfile(id);
        }

        if (!mounted) return;

        // Se o perfil excluído era o ativo, resetar para o pessoal
        final accountProvider =
            Provider.of<ActiveAccountProvider>(context, listen: false);
        if (accountProvider.activeAccount?.id == id) {
          final user = supabase.auth.currentUser;
          if (user != null) {
            await accountProvider.setActiveAccount(ActiveAccount(
              id: user.id,
              name: _userData?['name'] ?? 'Meu Perfil',
              photoUrl: _userData?['photo_url'],
              type: AccountType.user,
            ));
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type excluído com sucesso!')),
        );
        _loadData();
      } catch (e) {
        debugPrint('Erro ao excluir perfil: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao excluir perfil. Tente novamente.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final bgColor = thmode.darkMode ? AppColors.bodygray : Colors.grey.shade100;
    final cardColor = thmode.darkMode ? AppColors.darkBG : Colors.white;
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;

    return Scaffold(
      backgroundColor: widget.isDialog ? Colors.transparent : bgColor,
      appBar: widget.isDialog
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: const Text(
                'Contas e Perfis',
                style: TextStyle(
                    color: AppColors.patasColor,
                    fontSize: 22,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor),
                ),
                const SizedBox(width: 8),
              ],
            )
          : AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.patasColor,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Contas e Perfis',
                style: TextStyle(
                    color: AppColors.patasColor,
                    fontSize: 22,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold),
              ),
            ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.patasColor,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              Text(
                'Gerencie as contas e perfis associados ao seu usuário.',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 25),

              // Seção do Usuário Principal
              _buildSectionTitle('Sua Conta', textColor),
              _buildUserCard(cardColor, textColor),

              const SizedBox(height: 30),

              // Seção de Pets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Meus Pets', textColor),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddKindPage()),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.add_circle_outline,
                        size: 20, color: AppColors.patasColor),
                    label: const Text('Adicionar',
                        style: TextStyle(color: AppColors.patasColor)),
                  ),
                ],
              ),
              if (!_isLoading && _userPets.isEmpty)
                _buildEmptyState('Nenhum pet cadastrado', Icons.pets, textColor)
              else
                ..._userPets
                    .map((pet) => _buildPetCard(pet, cardColor, textColor)),

              const SizedBox(height: 30),

              // Seção de ONGs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Minhas ONGs e Abrigos', textColor),
                  if (_userOngs.isEmpty)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CreateOngProfilePage()),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.add_circle_outline,
                          size: 20, color: AppColors.patasColor),
                      label: const Text('Criar',
                          style: TextStyle(color: AppColors.patasColor)),
                    ),
                ],
              ),
              if (!_isLoading && _userOngs.isEmpty)
                _buildEmptyState(
                    'Nenhuma ONG cadastrada', Icons.home_work, textColor)
              else
                ..._userOngs
                    .map((ong) => _buildOngCard(ong, cardColor, textColor)),

              const SizedBox(height: 30),

              // Seção de Empresas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Minhas Empresas e Marcas', textColor),
                  if (_userCorps.isEmpty)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CreateCorpProfilePage()),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.add_circle_outline,
                          size: 20, color: AppColors.patasColor),
                      label: const Text('Criar',
                          style: TextStyle(color: AppColors.patasColor)),
                    ),
                ],
              ),
              if (!_isLoading && _userCorps.isEmpty)
                _buildEmptyState(
                    'Nenhuma empresa cadastrada', Icons.store, textColor)
              else
                ..._userCorps
                    .map((corp) => _buildCorpCard(corp, cardColor, textColor)),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserCard(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
            backgroundImage: _userData?['photo_url'] != null
                ? NetworkImage(_userData?['photo_url'])
                : null,
            child: _userData?['photo_url'] == null
                ? const Icon(Icons.person,
                    size: 35, color: AppColors.patasColor)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData?['name'] ?? 'Carregando...',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userData?['email'] ?? '',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.patasColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Principal',
              style: TextStyle(
                color: AppColors.patasColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: textColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.patasColor,
            child: CircleAvatar(
              radius: 26,
              backgroundImage:
                  pet.photoUrl != null ? NetworkImage(pet.photoUrl!) : null,
              child: pet.photoUrl == null
                  ? const Icon(Icons.pets, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  pet.breed ?? 'Raça não definida',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditPetPage(pet: pet)),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.patasColor),
          ),
        ],
      ),
    );
  }

  Widget _buildOngCard(OngProfile ong, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: textColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.patasColor,
            child: CircleAvatar(
              radius: 26,
              backgroundImage:
                  ong.photoUrl != null ? NetworkImage(ong.photoUrl!) : null,
              child: ong.photoUrl == null
                  ? const Icon(Icons.home_work, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ong.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ong.cnpj ?? 'CNPJ não informado',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EditOngProfilePage(ong: ong)),
              ).then((result) {
                if (result == true) _loadData();
              });
            },
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.patasColor),
          ),
          IconButton(
            onPressed: () => _deleteProfile(ong.id, 'ONG', ong.name),
            icon: Icon(Icons.delete_outline,
                size: 20, color: Colors.red.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildCorpCard(CorpProfile corp, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: textColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.patasColor,
            child: CircleAvatar(
              radius: 26,
              backgroundImage:
                  corp.photoUrl != null ? NetworkImage(corp.photoUrl!) : null,
              child: corp.photoUrl == null
                  ? const Icon(Icons.store, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  corp.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  corp.category,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EditCorpProfilePage(corp: corp)),
              ).then((result) {
                if (result == true) _loadData();
              });
            },
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.patasColor),
          ),
          IconButton(
            onPressed: () => _deleteProfile(corp.id, 'Empresa', corp.name),
            icon: Icon(Icons.delete_outline,
                size: 20, color: Colors.red.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      child: Column(
        children: [
          Icon(icon, size: 40, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: textColor.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
