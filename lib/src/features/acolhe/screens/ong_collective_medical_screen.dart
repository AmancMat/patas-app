import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../models/shelter_animal_model.dart';
import '../services/shelter_service.dart';
import 'animal_medical_history_sheet.dart';
import 'batch_health_action_sheet.dart';

class OngCollectiveMedicalScreen extends StatefulWidget {
  final String? ongId;

  const OngCollectiveMedicalScreen({super.key, this.ongId});

  @override
  State<OngCollectiveMedicalScreen> createState() =>
      _OngCollectiveMedicalScreenState();
}

class _OngCollectiveMedicalScreenState
    extends State<OngCollectiveMedicalScreen> {
  final ShelterService _service = ShelterService();
  List<ShelterAnimal> _animals = [];
  bool _isLoading = true;
  String _activeFilter = 'todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  String _getEffectiveOngId(BuildContext context) {
    if (widget.ongId != null && widget.ongId!.isNotEmpty) {
      return widget.ongId!;
    }
    final activeAcc =
        Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;
    return activeAcc?.id ?? 'minha-ong';
  }

  Future<void> _loadAnimals() async {
    setState(() => _isLoading = true);
    final ongId = _getEffectiveOngId(context);
    if (ongId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final list = await _service.getShelterAnimals(ongId);
    if (mounted) {
      setState(() {
        _animals = list;
        _isLoading = false;
      });
    }
  }

  List<ShelterAnimal> get _filteredAnimals {
    return _animals.where((animal) {
      // 1. Filtro por busca de texto
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = animal.name.toLowerCase().contains(q) ||
            animal.breed.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // 2. Filtro de saúde
      switch (_activeFilter) {
        case 'pendente_vacina':
          return !animal.isVaccinated;
        case 'pendente_vermifugo':
          return !animal.isDewormed;
        case 'pendente_castracao':
          return !animal.isCastrated;
        case 'em_tratamento':
          return animal.status == 'em_tratamento';
        case 'todos':
        default:
          return true;
      }
    }).toList();
  }

  void _openBatchAction() {
    final ongId = _getEffectiveOngId(context);
    BatchHealthActionSheet.show(
      context,
      ongId: ongId,
      allAnimals: _animals,
      onCompleted: _loadAnimals,
    );
  }

  void _openAnimalHistory(ShelterAnimal animal) {
    final ongId = _getEffectiveOngId(context);
    AnimalMedicalHistorySheet.show(
      context,
      animal: animal,
      ongId: ongId,
      onUpdated: _loadAnimals,
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: 'Prontuário Coletivo',
        subtitle: 'Controle sanitário dos acolhidos',
        showBackButton: true,
        leadingIcon: const Icon(
          Icons.assignment_turned_in_rounded,
          color: Colors.teal,
          size: 22,
        ),
        actions: [
          if (context.isDesktop)
            ElevatedButton.icon(
              onPressed: _animals.isEmpty ? null : _openBatchAction,
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: const Text(
                'Ação em Lote Sanitária',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 24),
              tooltip: 'Ação em Lote',
              onPressed: _animals.isEmpty ? null : _openBatchAction,
            ),
        ],
      ),
      floatingActionButton: context.isDesktop
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 76,
              ),
              child: FloatingActionButton.extended(
                heroTag: null,
                onPressed: _animals.isEmpty ? null : _openBatchAction,
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text(
                  'Ação em Lote',
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                ),
              ),
            ),
      body: ResponsiveLayout(
        mobile: _buildMobileBody(context, isDark),
        desktop: _buildDesktopBody(context, isDark),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 📱 CORPO MOBILE
  // ─────────────────────────────────────────────

  Widget _buildMobileBody(BuildContext context, bool isDark) {
    final filtered = _filteredAnimals;

    return SafeArea(
      child: RefreshIndicator(
          onRefresh: _loadAnimals,
          color: Colors.teal,
          child: CustomScrollView(
            slivers: [
              // 1. Régua de Saúde Sanitária
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: _buildHealthKpiRow(isDark, isMobile: true),
                ),
              ),

              // 2. Barra de Busca
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar acolhido por nome ou raça...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Pílulas de Filtros de Saúde
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _buildFilterPills(isDark),
                ),
              ),

              // 4. Lista de Acolhidos
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(isDark),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAnimalHealthCard(
                            filtered[index],
                            isDark,
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

              // Padding dinâmico inferior
              const SliverToBoxAdapter(child: MobileScrollPadding()),
            ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 💻 CORPO DESKTOP SAAS
  // ─────────────────────────────────────────────

  Widget _buildDesktopBody(BuildContext context, bool isDark) {
    final filtered = _filteredAnimals;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: RefreshIndicator(
            onRefresh: _loadAnimals,
            color: Colors.teal,
            child: CustomScrollView(
              slivers: [
                // 1. Régua de 4 KPIs de Saúde do Abrigo
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: _buildHealthKpiRow(isDark),
                  ),
                ),

                  // 3. Barra de Ferramentas (Busca e Filtros em Pílulas)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Buscar acolhido por nome ou raça...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                fillColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: _buildFilterPills(isDark),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Grid de Animais no Desktop
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(isDark),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.25,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildAnimalHealthCard(
                              filtered[index],
                              isDark,
                              isDesktop: true,
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  // ─────────────────────────────────────────────
  // 📊 RÉGUA DE KPIS DE SAÚDE
  // ─────────────────────────────────────────────

  Widget _buildHealthKpiRow(bool isDark, {bool isMobile = false}) {
    final total = _animals.length;
    final castratedCount = _animals.where((a) => a.isCastrated).length;
    final vaccinatedCount = _animals.where((a) => a.isVaccinated).length;
    final dewormedCount = _animals.where((a) => a.isDewormed).length;
    final inTreatmentCount =
        _animals.where((a) => a.status == 'em_tratamento').length;

    final castratedPct =
        total > 0 ? ((castratedCount / total) * 100).toStringAsFixed(0) : '0';
    final vaccinatedPct =
        total > 0 ? ((vaccinatedCount / total) * 100).toStringAsFixed(0) : '0';
    final dewormedPct =
        total > 0 ? ((dewormedCount / total) * 100).toStringAsFixed(0) : '0';

    final cardCastrados = _buildKpiCard(
      title: 'Castrados',
      value: '$castratedPct%',
      subtitle: '$castratedCount de $total acolhidos',
      icon: Icons.medical_services_rounded,
      color: Colors.purpleAccent,
      isDark: isDark,
    );

    final cardVacinados = _buildKpiCard(
      title: 'Vacinados',
      value: '$vaccinatedPct%',
      subtitle: '$vaccinatedCount de $total em dia',
      icon: Icons.vaccines_rounded,
      color: Colors.teal,
      isDark: isDark,
    );

    final cardVermifugados = _buildKpiCard(
      title: 'Vermifugados',
      value: '$dewormedPct%',
      subtitle: '$dewormedCount de $total em dia',
      icon: Icons.medication_rounded,
      color: Colors.orangeAccent,
      isDark: isDark,
    );

    final cardTratamento = _buildKpiCard(
      title: 'Tratamento',
      value: '$inTreatmentCount',
      subtitle: 'quarentena / cuidados',
      icon: Icons.healing_rounded,
      color: Colors.redAccent,
      isDark: isDark,
    );

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              cardCastrados,
              const SizedBox(width: 10),
              cardVacinados,
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              cardVermifugados,
              const SizedBox(width: 10),
              cardTratamento,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        cardCastrados,
        const SizedBox(width: 12),
        cardVacinados,
        const SizedBox(width: 12),
        cardVermifugados,
        const SizedBox(width: 12),
        cardTratamento,
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
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

  // ─────────────────────────────────────────────
  // 🏷️ PÍLULAS DE FILTRO
  // ─────────────────────────────────────────────

  Widget _buildFilterPills(bool isDark) {
    final filters = [
      {'key': 'todos', 'label': 'Todos (${_animals.length})'},
      {'key': 'pendente_vacina', 'label': 'Pendente Vacina'},
      {'key': 'pendente_vermifugo', 'label': 'Pendente Vermífugo'},
      {'key': 'pendente_castracao', 'label': 'Não Castrado'},
      {'key': 'em_tratamento', 'label': 'Em Tratamento'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(f['label']!),
              labelStyle: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              selectedColor: Colors.teal,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.teal
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                ),
              ),
              onSelected: (_) => setState(() => _activeFilter = f['key']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🩺 CARD DO ANIMAL NO PRONTUÁRIO
  // ─────────────────────────────────────────────

  Widget _buildAnimalHealthCard(
    ShelterAnimal animal,
    bool isDark, {
    bool isDesktop = false,
  }) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openAnimalHistory(animal),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto do Animal
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 72,
                    height: 78,
                    color: Colors.teal.withValues(alpha: 0.1),
                    child: animal.photoUrl != null && animal.photoUrl!.isNotEmpty
                        ? Image.network(animal.photoUrl!, fit: BoxFit.cover)
                        : Icon(
                            animal.species == 'felino'
                                ? Icons.pets_rounded
                                : Icons.pets,
                            color: Colors.teal,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Dados Clínicos e Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              animal.name,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: animal.status == 'em_tratamento'
                                  ? Colors.redAccent.withValues(alpha: 0.15)
                                  : Colors.teal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              animal.status == 'em_tratamento'
                                  ? 'Em Tratamento'
                                  : 'Acolhido',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: animal.status == 'em_tratamento'
                                    ? Colors.redAccent
                                    : Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${animal.species == 'felino' ? 'Gato' : 'Cão'} · ${animal.breed} · ${animal.ageEstimate ?? "Idade N/I"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Badges de Status Sanitário
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildSanitaryBadge(
                            label: animal.isCastrated ? 'Castrado' : 'Não Castrado',
                            isOk: animal.isCastrated,
                            icon: Icons.medical_services_rounded,
                          ),
                          _buildSanitaryBadge(
                            label: animal.isVaccinated ? 'Vacina OK' : 'Vacina Pendente',
                            isOk: animal.isVaccinated,
                            icon: Icons.vaccines_rounded,
                          ),
                          _buildSanitaryBadge(
                            label: animal.isDewormed ? 'Vermífugo OK' : 'Vermífugo Pend.',
                            isOk: animal.isDewormed,
                            icon: Icons.medication_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSanitaryBadge({
    required String label,
    required bool isOk,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOk
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 10,
            color: isOk ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: isOk ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 56,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhum acolhido neste filtro.',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Alterne os filtros acima ou cadastre acolhidos na Central de Adoção.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
