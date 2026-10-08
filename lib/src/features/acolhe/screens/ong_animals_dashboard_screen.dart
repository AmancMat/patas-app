import 'package:flutter/material.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/common_widgets/settings_lines_icon.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import '../models/shelter_animal_model.dart';
import '../services/shelter_service.dart';
import 'ong_create_animal_sheet.dart';
import 'ong_adoption_applications_screen.dart';

class OngAnimalsDashboardScreen extends StatefulWidget {
  final String? ongId;

  const OngAnimalsDashboardScreen({super.key, this.ongId});

  @override
  State<OngAnimalsDashboardScreen> createState() =>
      _OngAnimalsDashboardScreenState();
}

class _OngAnimalsDashboardScreenState extends State<OngAnimalsDashboardScreen> {
  final ShelterService _service = ShelterService();

  List<ShelterAnimal> _animals = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'todos';

  List<Map<String, String>> _getStatusTabs(BuildContext context) => [
    {'id': 'todos', 'label': context.tr('acolhe.status_tab_all')},
    {'id': 'disponivel', 'label': context.tr('acolhe.status_tab_available')},
    {'id': 'em_tratamento', 'label': context.tr('acolhe.status_tab_treatment')},
    {'id': 'lar_temporario', 'label': context.tr('acolhe.status_tab_foster')},
    {'id': 'adotado', 'label': context.tr('acolhe.status_tab_adopted')},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  String _getEffectiveOngId(BuildContext context) {
    if (widget.ongId != null && widget.ongId!.isNotEmpty) {
      return widget.ongId!;
    }
    final activeAcc = Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;
    return activeAcc?.id ?? 'minha-ong';
  }

  Future<void> _loadAnimals() async {
    setState(() => _isLoading = true);
    final ongId = _getEffectiveOngId(context);
    final results = await _service.getShelterAnimals(
      ongId,
      status: _selectedStatusFilter,
    );

    if (mounted) {
      setState(() {
        _animals = results;
        _isLoading = false;
      });
    }
  }

  void _openCreateSheet([ShelterAnimal? animalToEdit]) async {
    final ongId = _getEffectiveOngId(context);
    final result = await OngCreateAnimalSheet.show(
      context,
      ongId: ongId,
      animalToEdit: animalToEdit,
    );

    if (result == true) {
      _loadAnimals();
    }
  }

  void _confirmDelete(ShelterAnimal animal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('acolhe.confirm_delete_title')),
        content: Text(context.tr('acolhe.confirm_delete_content', {'name': animal.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('acolhe.cancel_btn')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteShelterAnimal(animal.id);
              _loadAnimals();
            },
            child: Text(context.tr('acolhe.remove_btn'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📱 LAYOUT MOBILE (Mantido 100% fiel e estável)
  // ─────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final totalAcolhidos = _animals.length;
    final totalDisponiveis = _animals.where((a) => a.status == 'disponivel').length;
    final totalTratamento = _animals.where((a) => a.status == 'em_tratamento').length;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('acolhe.dashboard_title'),
        subtitle: context.tr('acolhe.dashboard_subtitle'),
        showBackButton: false,
        compactPetSelector: true,
        leadingIcon: Icon(
          Icons.volunteer_activism_rounded,
          color: Colors.purpleAccent,
          size: 22,
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: context.isDesktop
              ? 20
              : (MediaQuery.paddingOf(context).bottom + 76),
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          backgroundColor: Colors.purpleAccent.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: () => _openCreateSheet(),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            context.tr('acolhe.new_animal'),
            style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAnimals,
          color: Colors.purpleAccent,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: CustomScrollView(
            slivers: [
              // 1. Resumo de Métricas do Abrigo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        title: context.tr('acolhe.total_sheltered'),
                        value: '$totalAcolhidos',
                        icon: Icons.pets_rounded,
                        color: Colors.purpleAccent,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        title: context.tr('acolhe.for_adoption'),
                        value: '$totalDisponiveis',
                        icon: Icons.favorite_rounded,
                        color: Colors.greenAccent.shade700,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        title: context.tr('acolhe.in_treatment'),
                        value: '$totalTratamento',
                        icon: Icons.medical_services_outlined,
                        color: Colors.orangeAccent,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // 1.5. Card de Ação Rápida: Fichas de Interessados
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OngAdoptionApplicationsScreen(
                              ongId: _getEffectiveOngId(context),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF3B0764).withValues(alpha: 0.5),
                                    const Color(0xFF1E1B4B).withValues(alpha: 0.5),
                                  ]
                                : [
                                    const Color(0xFFFAF5FF),
                                    const Color(0xFFF3E8FF),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.purpleAccent.withValues(alpha: isDark ? 0.4 : 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_ind_rounded,
                                color: Colors.purpleAccent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('acolhe.applications_card_title'),
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF581C87),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.tr('acolhe.applications_card_desc'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.tr('acolhe.access_btn'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 9),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Filtros por Status (Tabs horizontais)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    scrollDirection: Axis.horizontal,
                    itemCount: _getStatusTabs(context).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tab = _getStatusTabs(context)[index];
                      final isSelected = tab['id'] == _selectedStatusFilter;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedStatusFilter = tab['id']!);
                          _loadAnimals();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purpleAccent
                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.purpleAccent
                                  : (isDark ? Colors.white10 : Colors.grey.shade300),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              tab['label']!,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 3. Lista de Animais Acolhidos
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  ),
                )
              else if (_animals.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pets_outlined,
                          size: 64,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('acolhe.no_animals_in_category'),
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                  sliver: context.isTablet
                      ? SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.20,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _ShelterAnimalCard(
                                animal: _animals[index],
                                isDark: isDark,
                                onEdit: () => _openCreateSheet(_animals[index]),
                                onDelete: () => _confirmDelete(_animals[index]),
                              );
                            },
                            childCount: _animals.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ShelterAnimalCard(
                                  animal: _animals[index],
                                  isDark: isDark,
                                  onEdit: () => _openCreateSheet(_animals[index]),
                                  onDelete: () => _confirmDelete(_animals[index]),
                                ),
                              );
                            },
                            childCount: _animals.length,
                          ),
                        ),
                ),

              // Padding inferior dinâmico para compensar a barra de navegação e o botão flutuante
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 74),
                  child: MobileScrollPadding(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  // ─────────────────────────────────────────────────────────────
  // 💻 LAYOUT DESKTOP — Dashboard Proporcional com Régua de 4 KPIs
  // ─────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final totalAcolhidos = _animals.length;
    final totalDisponiveis = _animals.where((a) => a.status == 'disponivel').length;
    final totalTratamento = _animals.where((a) => a.status == 'em_tratamento').length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header do Dashboard Desktop com Ação Primária
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.volunteer_activism_rounded,
                                    color: Colors.purpleAccent,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  context.tr('acolhe.dashboard_title'),
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.darkBG,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('acolhe.dashboard_subtitle'),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        // Botão Primário "+ Novo Acolhido"
                        ElevatedButton.icon(
                          onPressed: () => _openCreateSheet(),
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          label: Text(
                            context.tr('acolhe.new_animal'),
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 2. Régua de 4 Cards de Métricas e Fichas
                    Row(
                      children: [
                        _buildDesktopSummaryCard(
                          title: context.tr('acolhe.total_sheltered'),
                          subtitle: context.tr('acolhe.sub_animals_in_shelter'),
                          value: '$totalAcolhidos',
                          icon: Icons.pets_rounded,
                          color: Colors.purpleAccent,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 14),
                        _buildDesktopSummaryCard(
                          title: context.tr('acolhe.for_adoption'),
                          subtitle: context.tr('acolhe.sub_available_in_app'),
                          value: '$totalDisponiveis',
                          icon: Icons.favorite_rounded,
                          color: Colors.greenAccent.shade700,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 14),
                        _buildDesktopSummaryCard(
                          title: 'Em Tratamento',
                          subtitle: context.tr('acolhe.sub_health_care'),
                          value: '$totalTratamento',
                          icon: Icons.medical_services_outlined,
                          color: Colors.orangeAccent,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 14),
                        _buildDesktopApplicationsCard(context, isDark: isDark),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // 3. Barra de Abas / Filtros de Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: _getStatusTabs(context).map((tab) {
                            final isSelected = tab['id'] == _selectedStatusFilter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedStatusFilter = tab['id']!);
                                  _loadAnimals();
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.purpleAccent
                                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.purpleAccent
                                          : (isDark ? Colors.white10 : Colors.grey.shade300),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: Colors.purpleAccent.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Text(
                                    tab['label']!,
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        Text(
                          (_animals.length == 1 ? context.tr('acolhe.animal_count_singular') : context.tr('acolhe.animal_count_plural', {'count': '${_animals.length}'})),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 4. Grid de Animais Acolhidos
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.purpleAccent),
                        ),
                      )
                    else if (_animals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pets_outlined,
                                size: 64,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('acolhe.no_animals_in_category'),
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 16,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.20,
                        ),
                        itemCount: _animals.length,
                        itemBuilder: (context, index) {
                          return _ShelterAnimalCard(
                            animal: _animals[index],
                            isDark: isDark,
                            onEdit: () => _openCreateSheet(_animals[index]),
                            onDelete: () => _confirmDelete(_animals[index]),
                          );
                        },
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Card de métrica no Desktop (proporcional e harmonioso)
  Widget _buildDesktopSummaryCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4º Card da Régua Desktop: Fichas de Interessados
  Widget _buildDesktopApplicationsCard(BuildContext context, {required bool isDark}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OngAdoptionApplicationsScreen(
                  ongId: _getEffectiveOngId(context),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF3B0764).withValues(alpha: 0.5),
                        const Color(0xFF1E1B4B).withValues(alpha: 0.5),
                      ]
                    : [
                        const Color(0xFFFAF5FF),
                        const Color(0xFFF3E8FF),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.purpleAccent.withValues(alpha: isDark ? 0.4 : 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: isDark ? 0.15 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        color: Colors.purpleAccent,
                        size: 22,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('acolhe.access_btn'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Fredoka',
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 9),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('acolhe.applications_badge'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF581C87),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('acolhe.applications_card_sub_desktop'),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card de métrica no Mobile (mantido)
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelterAnimalCard extends StatelessWidget {
  final ShelterAnimal animal;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShelterAnimalCard({
    required this.animal,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusBadge = _getStatusBadge(context, animal.status);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto com overlay de espécie
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 105,
                    color: Colors.purpleAccent.withValues(alpha: 0.1),
                    child: animal.photoUrl != null && animal.photoUrl!.isNotEmpty
                        ? Image.network(animal.photoUrl!, fit: BoxFit.cover)
                        : Icon(
                            animal.species == 'felino'
                                ? Icons.pets
                                : Icons.pets_rounded,
                            size: 36,
                            color: Colors.purpleAccent,
                          ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        animal.species == 'felino' ? '🐱' : '🐶',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Detalhes do Animal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          animal.name,
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
                      PopupMenuButton<String>(
                        tooltip: context.tr('acolhe.animal_options_tooltip'),
                        icon: SettingsLinesIcon(
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 18,
                        ),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                        ),
                        onSelected: (val) {
                          if (val == 'edit') onEdit();
                          if (val == 'delete') onDelete();
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_rounded, size: 16, color: Colors.purpleAccent),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('acolhe.edit_animal'),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.darkBG,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded,
                                    size: 16, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('acolhe.delete_animal'),
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${animal.breed} • ${animal.gender == "macho" ? "Macho" : "Fêmea"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBadge.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusBadge.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusBadge.color,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Badges de Saúde (Castrado, Vacinado)
                  Row(
                    children: [
                      if (animal.isCastrated)
                        _buildHealthPill(context.tr('acolhe.castrated'), Colors.teal, isDark),
                      if (animal.isVaccinated) ...[
                        const SizedBox(width: 4),
                        _buildHealthPill(context.tr('acolhe.vaccinated'), Colors.blue, isDark),
                      ],
                      const Spacer(),
                      if (animal.isPublicAdoption)
                        const Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: Colors.purpleAccent,
                        )
                      else
                        const Icon(
                          Icons.visibility_off_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthPill(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  _StatusBadgeInfo _getStatusBadge(BuildContext context, String status) {
    switch (status) {
      case 'disponivel':
        return _StatusBadgeInfo(context.tr('acolhe.status_available'), Colors.green);
      case 'em_tratamento':
        return _StatusBadgeInfo(context.tr('acolhe.status_in_treatment'), Colors.orangeAccent);
      case 'lar_temporario':
        return _StatusBadgeInfo(context.tr('acolhe.status_foster_home'), Colors.indigoAccent);
      case 'adotado':
        return _StatusBadgeInfo(context.tr('acolhe.status_adopted_celebrate'), Colors.purpleAccent);
      default:
        return _StatusBadgeInfo(context.tr('acolhe.status_registered'), Colors.grey);
    }
  }
}

class _StatusBadgeInfo {
  final String label;
  final Color color;
  _StatusBadgeInfo(this.label, this.color);
}
