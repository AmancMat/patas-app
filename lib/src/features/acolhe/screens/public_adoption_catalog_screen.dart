import 'package:flutter/material.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../models/shelter_animal_model.dart';
import '../services/shelter_service.dart';
import 'adoption_pet_detail_screen.dart';

class PublicAdoptionCatalogScreen extends StatefulWidget {
  const PublicAdoptionCatalogScreen({super.key});

  @override
  State<PublicAdoptionCatalogScreen> createState() =>
      _PublicAdoptionCatalogScreenState();
}

class _PublicAdoptionCatalogScreenState
    extends State<PublicAdoptionCatalogScreen> {
  final ShelterService _service = ShelterService();
  final TextEditingController _searchController = TextEditingController();

  List<ShelterAnimal> _animals = [];
  bool _isLoading = true;

  String _selectedSpecies = 'todos';
  String _selectedSize = 'todos';

  List<Map<String, String>> _getSpeciesFilters(BuildContext context) => [
    {'id': 'todos', 'label': context.tr('acolhe.status_tab_all')},
    {'id': 'canino', 'label': context.tr('acolhe.filter_dogs')},
    {'id': 'felino', 'label': context.tr('acolhe.filter_cats')},
  ];

  List<Map<String, String>> _getSizeFilters(BuildContext context) => [
    {'id': 'todos', 'label': context.tr('acolhe.filter_any_size')},
    {'id': 'pequeno', 'label': context.tr('acolhe.filter_size_small')},
    {'id': 'medio', 'label': context.tr('acolhe.filter_size_medium')},
    {'id': 'grande', 'label': context.tr('acolhe.filter_size_large')},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    setState(() => _isLoading = true);
    final results = await _service.getPublicAdoptionAnimals(
      species: _selectedSpecies,
      size: _selectedSize,
      query: _searchController.text,
    );

    if (mounted) {
      setState(() {
        _animals = results;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('acolhe.catalog_title'),
        subtitle: context.tr('acolhe.catalog_subtitle'),
        leadingIcon: Icon(
          Icons.favorite_rounded,
          color: Colors.purpleAccent,
          size: 22,
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
              onRefresh: _loadAnimals,
              color: Colors.purpleAccent,
              child: CustomScrollView(
                slivers: [
                  // 1. Barra de Busca & Filtros
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
                          // Barra de busca
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
                              onChanged: (_) => _loadAnimals(),
                              decoration: InputDecoration(
                                hintText: context.tr('acolhe.search_animal_hint'),
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.purpleAccent,
                                  size: 22,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _loadAnimals();
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

                          // Filtros por Espécie
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _getSpeciesFilters(context).length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final s = _getSpeciesFilters(context)[index];
                                      final isSelected =
                                          s['id'] == _selectedSpecies;

                                      return InkWell(
                                        onTap: () {
                                          setState(() =>
                                              _selectedSpecies = s['id']!);
                                          _loadAnimals();
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.purpleAccent
                                                : (isDark
                                                    ? const Color(0xFF1E293B)
                                                    : Colors.white),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.purpleAccent
                                                  : (isDark
                                                      ? Colors.white10
                                                      : Colors.grey.shade300),
                                            ),
                                          ),
                                          child: Text(
                                            s['label']!,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Filtros por Porte
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 34,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _getSizeFilters(context).length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final sz = _getSizeFilters(context)[index];
                                      final isSelected =
                                          sz['id'] == _selectedSize;

                                      return InkWell(
                                        onTap: () {
                                          setState(() =>
                                              _selectedSize = sz['id']!);
                                          _loadAnimals();
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.purpleAccent.withValues(alpha: 0.2)
                                                : (isDark
                                                    ? const Color(0xFF1E293B)
                                                    : Colors.white),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.purpleAccent
                                                  : (isDark
                                                      ? Colors.white10
                                                      : Colors.grey.shade300),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              sz['label']!,
                                              style: TextStyle(
                                                fontFamily: 'Fredoka',
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                                color: isSelected
                                                    ? Colors.purpleAccent
                                                    : (isDark
                                                        ? Colors.white70
                                                        : Colors.black87),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Lista de Animais
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
                              Icons.search_off_rounded,
                              size: 64,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('acolhe.no_adoption_pets_found'),
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
                      padding: EdgeInsets.fromLTRB(
                        context.isDesktop ? 24 : 16,
                        8,
                        context.isDesktop ? 24 : 16,
                        24,
                      ),
                      sliver: context.isDesktop
                          ? SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 440,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.25,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _AdoptionPetCard(
                                    animal: _animals[index],
                                    isDark: isDark,
                                  );
                                },
                                childCount: _animals.length,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _AdoptionPetCard(
                                      animal: _animals[index],
                                      isDark: isDark,
                                    ),
                                  );
                                },
                                childCount: _animals.length,
                              ),
                            ),
                    ),

                  // Padding dinâmico inferior (mobile e tablet com bottom fluid bar)
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
}

class _AdoptionPetCard extends StatelessWidget {
  final ShelterAnimal animal;
  final bool isDark;

  const _AdoptionPetCard({
    required this.animal,
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
                builder: (context) => AdoptionPetDetailScreen(animal: animal),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto do animal
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 100,
                    height: 120,
                    color: Colors.purpleAccent.withValues(alpha: 0.1),
                    child: animal.photoUrl != null && animal.photoUrl!.isNotEmpty
                        ? Image.network(animal.photoUrl!, fit: BoxFit.cover)
                        : Icon(
                            animal.species == 'felino'
                                ? Icons.pets
                                : Icons.pets_rounded,
                            size: 40,
                            color: Colors.purpleAccent,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Informações do animal
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
                                fontSize: 18,
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
                              color: Colors.purpleAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              animal.species == 'felino' ? context.tr('acolhe.cat_label') : context.tr('acolhe.dog_label'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.purpleAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${animal.breed} • ${animal.gender == "macho" ? "Macho" : "Fêmea"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (animal.ageEstimate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          animal.ageEstimate!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Badges de saúde
                      Wrap(
                        spacing: 4,
                        children: [
                          if (animal.isCastrated)
                            _buildMiniBadge(context.tr('acolhe.castrated'), Colors.teal, isDark),
                          if (animal.isVaccinated)
                            _buildMiniBadge(context.tr('acolhe.vaccinated'), Colors.blue, isDark),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Rodapé: ONG + Botão Conhecer
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              animal.ongName ?? context.tr('acolhe.partner_shelter'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Conhecer',
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 9,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
