import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../models/trainer_profile_model.dart';
import '../services/adestradores_service.dart';
import 'trainer_detail_screen.dart';
import 'create_trainer_profile_screen.dart';

class AdestradoresCatalogScreen extends StatefulWidget {
  const AdestradoresCatalogScreen({super.key});

  @override
  State<AdestradoresCatalogScreen> createState() =>
      _AdestradoresCatalogScreenState();
}

class _AdestradoresCatalogScreenState extends State<AdestradoresCatalogScreen> {
  final AdestradoresService _service = AdestradoresService();
  final TextEditingController _searchController = TextEditingController();

  List<TrainerProfile> _trainers = [];
  bool _isLoading = true;
  String _selectedSpecialty = 'Todos';

  final List<String> _specialtyFilters = [
    'Todos',
    'Obediência Básica',
    'Reatividade',
    'Filhotes',
    'Ansiedade',
    'Passeio',
    'Gatos',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await _service.getTrainers(
        query: _searchController.text,
        specialty: _selectedSpecialty,
      );
      if (mounted) {
        setState(() {
          _trainers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AdestradoresCatalog] Erro ao carregar: $e');
      if (mounted) {
        setState(() {
          _trainers = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateTrainerScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTrainerProfileScreen(),
      ),
    );
    if (result == true && mounted) {
      _loadTrainers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: 'Adestradores & Treino',
        subtitle: 'Especialistas em comportamento canino e felino',
        leadingIcon: const Icon(
          Icons.sports_score_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.badge_outlined,
              color: AppColors.patasColor,
              size: 22,
            ),
            tooltip: 'Cadastrar como Especialista',
            onPressed: _openCreateTrainerScreen,
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
              onRefresh: _loadTrainers,
              color: AppColors.patasColor,
              child: CustomScrollView(
                slivers: [
                  // 1. Campo de Busca & Filtros
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.isDesktop ? 24 : 16,
                        16,
                        context.isDesktop ? 24 : 16,
                        8,
                      ),
                      child: Column(
                        children: [
                          // Barra de Pesquisa
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => _loadTrainers(),
                              decoration: InputDecoration(
                                hintText: 'Buscar adestrador por nome ou especialidade...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.patasColor,
                                  size: 22,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _loadTrainers();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Chips de Filtro por Especialidade
                          SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _specialtyFilters.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final spec = _specialtyFilters[index];
                                final isSelected = spec == _selectedSpecialty;

                                return InkWell(
                                  onTap: () {
                                    setState(() => _selectedSpecialty = spec);
                                    _loadTrainers();
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.patasColor
                                          : (isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.patasColor
                                            : (isDark
                                                ? Colors.white10
                                                : Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Text(
                                      spec,
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Lista de Cards de Adestradores
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.patasColor,
                        ),
                      ),
                    )
                  else if (_trainers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(isDark),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        context.isDesktop ? 24 : 16,
                        12,
                        context.isDesktop ? 24 : 16,
                        24,
                      ),
                      sliver: context.isDesktop
                          ? SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 450,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.25,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _TrainerCard(
                                    trainer: _trainers[index],
                                    isDark: isDark,
                                  );
                                },
                                childCount: _trainers.length,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _TrainerCard(
                                      trainer: _trainers[index],
                                      isDark: isDark,
                                    ),
                                  );
                                },
                                childCount: _trainers.length,
                              ),
                            ),
                    ),

                  // Padding dinâmico inferior
                  if (!context.isDesktop)
                    const SliverToBoxAdapter(child: MobileScrollPadding()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final hasActiveFilter =
        _searchController.text.trim().isNotEmpty || _selectedSpecialty != 'Todos';

    if (hasActiveFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.patasColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: AppColors.patasColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Nenhum adestrador encontrado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Não encontramos especialistas com os filtros selecionados. Tente buscar por outro termo ou limpe os filtros.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedSpecialty = 'Todos');
                  _loadTrainers();
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text(
                  'Limpar Filtros',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.patasColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Lista vazia real (início do app / região sem adestradores cadastrados)
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ilustração / Ícone acolhedor
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.patasColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    Colors.amber.withValues(alpha: isDark ? 0.15 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.patasColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.sports_score_rounded,
                size: 58,
                color: AppColors.patasColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ainda não há adestradores cadastrados por aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Estamos expandindo nossa rede de adestradores e especialistas em comportamento pet. Assim que novos profissionais se credenciarem na sua região, eles estarão disponíveis aqui!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card Convite para o profissional se cadastrar (CTA)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.patasColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 24,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Você é adestrador ou comportamentalista?',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.darkBG,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cadastre seu perfil profissional e comece a receber alunos da sua região!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _openCreateTrainerScreen,
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text(
                          'Cadastrar meu Perfil Profissional',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patasColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final TrainerProfile trainer;
  final bool isDark;

  const _TrainerCard({
    required this.trainer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrainerDetailScreen(trainer: trainer),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo: Avatar + Nome + Selo + Avaliação
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.patasColor.withValues(alpha: 0.15),
                          backgroundImage: trainer.profilePhoto != null &&
                                  trainer.profilePhoto!.isNotEmpty
                              ? NetworkImage(trainer.profilePhoto!)
                              : null,
                          child: trainer.profilePhoto == null
                              ? const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: AppColors.patasColor,
                                )
                              : null,
                        ),
                        if (trainer.isVerified)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  trainer.fullName,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.darkBG,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      trainer.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '${trainer.city ?? "São Paulo"}, ${trainer.state ?? "SP"} • Até ${trainer.serviceRadiusKm}km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bio Curta
                if (trainer.bio != null)
                  Text(
                    trainer.bio!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 10),

                // Especialidades em Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: trainer.specialties.take(3).map((spec) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.patasColor.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        spec,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.patasColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),
                const Divider(height: 18),

                // Rodapé: Modalidades de atendimento e Botão
                Row(
                  children: [
                    if (trainer.attendsHome) ...[
                      Icon(
                        Icons.home_outlined,
                        size: 16,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'A domicílio',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (trainer.attendsOnline) ...[
                      Icon(
                        Icons.videocam_outlined,
                        size: 16,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.patasColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Ver Perfil',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
