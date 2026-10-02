import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/pets/pets_create/create_pet_page.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/ongs_corp/create_corp_profile.dart';
import 'package:patas_web_app/src/features/ongs_corp/create_ong_profile.dart' as ong;
import 'package:patas_web_app/src/features/profile_creation/widgets/profile_type_card.dart';

class ProfileTypeSelectionScreen extends StatefulWidget {
  final bool isFirstProfile;

  const ProfileTypeSelectionScreen({
    super.key,
    this.isFirstProfile = false,
  });

  @override
  State<ProfileTypeSelectionScreen> createState() => _ProfileTypeSelectionScreenState();
}

class _ProfileTypeSelectionScreenState extends State<ProfileTypeSelectionScreen> {
  bool _isPetsExpanded = true;
  bool _isOrgsExpanded = false;

  void _togglePets() {
    setState(() {
      _isPetsExpanded = !_isPetsExpanded;
      if (_isPetsExpanded) {
        _isOrgsExpanded = false;
      }
    });
  }

  void _toggleOrgs() {
    setState(() {
      _isOrgsExpanded = !_isOrgsExpanded;
      if (_isOrgsExpanded) {
        _isPetsExpanded = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBG : AppColors.bodyLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBG : AppColors.bodyLight,
        automaticallyImplyLeading: false,
        leading: widget.isFirstProfile
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.patasColor,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isFirstProfile ? 'Criar Primeiro Perfil' : 'Novo Perfil',
          style: TextStyle(
            color: textColor,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e descrição inicial
                  if (widget.isFirstProfile) ...[
                    const Text(
                      'Bem-vindo ao Patas! 🐾',
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.patasColor,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Crie o perfil do seu pet, instituição ou empresa para começar a compartilhar momentos especiais.',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                  ] else ...[
                    Text(
                      'Que tipo de perfil deseja criar?',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Escolha uma das opções de seções abaixo para ver os detalhes',
                      style: TextStyle(
                        fontSize: 15.0,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],

                  // ACORDEÃO 1: Perfis de Pets
                  _buildAccordionHeader(
                    title: 'Perfis de Pets 🐾',
                    isExpanded: _isPetsExpanded,
                    onTap: _togglePets,
                    isDark: isDark,
                  ),
                  _buildAccordionContent(
                    isExpanded: _isPetsExpanded,
                    child: _buildPetsGrid(context, isDark),
                  ),

                  const SizedBox(height: 16.0),

                  // ACORDEÃO 2: Perfis de Organizações
                  _buildAccordionHeader(
                    title: 'Perfis de Organizações 🏢',
                    isExpanded: _isOrgsExpanded,
                    onTap: _toggleOrgs,
                    isDark: isDark,
                  ),
                  _buildAccordionContent(
                    isExpanded: _isOrgsExpanded,
                    child: _buildOrgsContent(context),
                  ),

                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget para Cabeçalho do Acordeão
  Widget _buildAccordionHeader({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isExpanded
                ? AppColors.patasColor.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: AppColors.patasColor,
                fontFamily: 'Fredoka',
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? Colors.white70 : AppColors.darkBG,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para animar a abertura/fechamento do Acordeão
  Widget _buildAccordionContent({required bool isExpanded, required Widget child}) {
    return AnimatedCrossFade(
      firstChild: Container(),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 16.0, left: 4.0, right: 4.0),
        child: child,
      ),
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
      sizeCurve: Curves.easeInOut,
    );
  }

  // Grade Compacta de Pets (5 espécies)
  Widget _buildPetsGrid(BuildContext context, bool isDark) {
    final List<Map<String, dynamic>> petOptions = [
      {'label': 'Cachorro', 'icon': '🐶', 'species': 'canino'},
      {'label': 'Gato', 'icon': '🐱', 'species': 'felino'},
      {'label': 'Ave / Pássaro', 'icon': '🦜', 'species': 'ave'},
      {'label': 'Roedor', 'icon': '🐹', 'species': 'roedor'},
      {'label': 'Exótico / Réptil', 'icon': '🦎', 'species': 'exotico'},
    ];

    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width > 600 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.2,
      ),
      itemCount: petOptions.length,
      itemBuilder: (context, index) {
        final option = petOptions[index];
        return _buildPetSpeciesCard(
          context: context,
          label: option['label'],
          emoji: option['icon'],
          species: option['species'],
          isDark: isDark,
        );
      },
    );
  }

  // Card individual para cada espécie de Pet
  Widget _buildPetSpeciesCard({
    required BuildContext context,
    required String label,
    required String emoji,
    required String species,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : AppColors.darkBG;

    return InkWell(
      onTap: () => _navigateToPetCreation(context, species),
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40.0),
            ),
            const SizedBox(height: 12.0),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Fredoka',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Conteúdo da aba Organizações
  Widget _buildOrgsContent(BuildContext context) {
    return Column(
      children: [
        ProfileTypeCard(
          title: 'ONGs e Abrigos',
          subtitle: 'Instituições sem fins lucrativos',
          icon: Icons.favorite,
          iconColor: Colors.red[400],
          onTap: () => _navigateToOngCreation(context),
        ),
        const SizedBox(height: 12.0),
        ProfileTypeCard(
          title: 'Empresas e Marcas',
          subtitle: 'Negócios e serviços para pets',
          icon: Icons.business,
          iconColor: Colors.blue[400],
          onTap: () => _navigateToCompanyCreation(context),
        ),
      ],
    );
  }

  void _navigateToPetCreation(BuildContext context, String species) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePetPage(
          species: species,
          isFirstProfile: widget.isFirstProfile,
        ),
      ),
    );
  }

  void _navigateToOngCreation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ong.CreateOngProfilePage(),
      ),
    );
  }

  void _navigateToCompanyCreation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCorpProfilePage(),
      ),
    );
  }
}
