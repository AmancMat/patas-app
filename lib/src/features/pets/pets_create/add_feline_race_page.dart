import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';

import '../models/pet_race_model.dart';

final List<PetRace> felineRaces = [
  PetRace(photoPath: 'assets/cats_images/abissinio.png', name: 'Abissínio'),
  PetRace(
      photoPath: 'assets/cats_images/american-bobtail.png',
      name: 'American Bobtail'),
  PetRace(
      photoPath: 'assets/cats_images/american-curl.png', name: 'American Curl'),
  PetRace(
      photoPath: 'assets/cats_images/american-shorthair.png',
      name: 'American Shorthair'),
  PetRace(
      photoPath: 'assets/cats_images/american-wirehair.png',
      name: 'American Wirehair'),
  PetRace(
      photoPath: 'assets/cats_images/angora-turco.png', name: 'Angorá Turco'),
  PetRace(photoPath: 'assets/cats_images/asiatico.png', name: 'Asiático'),
  PetRace(
      photoPath: 'assets/cats_images/australian-mist.png',
      name: 'Australian Mist'),
  PetRace(photoPath: 'assets/cats_images/azul-russo.png', name: 'Azul Russo'),
  PetRace(photoPath: 'assets/cats_images/balines.png', name: 'Balinês'),
  PetRace(photoPath: 'assets/cats_images/bengal.png', name: 'Bengal'),
  PetRace(
      photoPath: 'assets/cats_images/birmanes.png',
      name: 'Birmanês (Sagrado da Birmânia)'),
  PetRace(photoPath: 'assets/cats_images/bombaim.png', name: 'Bombaim'),
  PetRace(
      photoPath: 'assets/cats_images/british-shorthair.png',
      name: 'British Shorthair'),
  PetRace(photoPath: 'assets/cats_images/burmes.png', name: 'Burmês'),
  PetRace(photoPath: 'assets/cats_images/chartreux.png', name: 'Chartreux'),
  PetRace(photoPath: 'assets/cats_images/cornish-rex.png', name: 'Cornish Rex'),
  PetRace(photoPath: 'assets/cats_images/devon-rex.png', name: 'Devon Rex'),
  PetRace(
      photoPath: 'assets/cats_images/egyptian-mau.png', name: 'Egyptian Mau'),
  PetRace(
      photoPath: 'assets/cats_images/exotic-shorthair.png',
      name: 'Exotic Shorthair'),
  PetRace(photoPath: 'assets/cats_images/himalaya.png', name: 'Himalaya'),
  PetRace(photoPath: 'assets/cats_images/javanes.png', name: 'Javanês'),
  PetRace(photoPath: 'assets/cats_images/korat.png', name: 'Korat'),
  PetRace(photoPath: 'assets/cats_images/maine-coon.png', name: 'Maine Coon'),
  PetRace(photoPath: 'assets/cats_images/manx.png', name: 'Manx'),
  PetRace(photoPath: 'assets/cats_images/munchkin.png', name: 'Munchkin'),
  PetRace(photoPath: 'assets/cats_images/nebelung.png', name: 'Nebelung'),
  PetRace(
      photoPath: 'assets/cats_images/noruegues-floresta.png',
      name: 'Norueguês da Floresta'),
  PetRace(photoPath: 'assets/cats_images/ocicat.png', name: 'Ocicat'),
  PetRace(photoPath: 'assets/cats_images/oriental.png', name: 'Oriental'),
  PetRace(photoPath: 'assets/cats_images/persa.png', name: 'Persa'),
  PetRace(photoPath: 'assets/cats_images/ragdoll.png', name: 'Ragdoll'),
  PetRace(photoPath: 'assets/cats_images/savannah.png', name: 'Savannah'),
  PetRace(
      photoPath: 'assets/cats_images/scottish-fold.png', name: 'Scottish Fold'),
  PetRace(photoPath: 'assets/cats_images/selkirk-rex.png', name: 'Selkirk Rex'),
  PetRace(photoPath: 'assets/cats_images/siames.png', name: 'Siamês'),
  PetRace(photoPath: 'assets/cats_images/siberiano.png', name: 'Siberiano'),
  PetRace(photoPath: 'assets/cats_images/singapura.png', name: 'Singapura'),
  PetRace(photoPath: 'assets/cats_images/snowshoe.png', name: 'Snowshoe'),
  PetRace(photoPath: 'assets/cats_images/somali.png', name: 'Somali'),
  PetRace(photoPath: 'assets/cats_images/sphynx.png', name: 'Sphynx'),
  PetRace(photoPath: 'assets/cats_images/tonquines.png', name: 'Tonquinês'),
  PetRace(photoPath: 'assets/cats_images/toyger.png', name: 'Toyger'),
  PetRace(photoPath: 'assets/cats_images/sokoke.png', name: 'Sokoke'),
  PetRace(photoPath: 'assets/cats_images/thai.png', name: 'Thai'),
  PetRace(photoPath: 'assets/cats_images/turkish-van.png', name: 'Turkish Van'),
];

class AddFelineRacePage extends StatefulWidget {
  const AddFelineRacePage({super.key});

  @override
  State<AddFelineRacePage> createState() => _AddFelineRacePageState();
}

class _AddFelineRacePageState extends State<AddFelineRacePage> {
  final TextEditingController _searchController = TextEditingController();
  List<PetRace> _filteredCats = felineRaces;

  // Add SRD at the start of the list
  static final PetRace _srdOption =
      PetRace(photoPath: 'assets/icons/patas.svg', name: 'SRD / Outra');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRaces);
  }

  void _filterRaces() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCats = felineRaces.where((cat) {
        return cat.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
      appBar: PatasEssencialAppBar(
        title: context.tr('pet_create.cat_breeds_title'),
        subtitle: context.tr('pet_create.cat_breeds_subtitle'),
        leadingIcon: const Icon(
          Icons.pets_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        showBackButton: true,
        maxWidth: 800,
        bottomHeight: 56,
        bottomWidget: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
                color: thmode.darkMode ? Colors.white : AppColors.darkBG),
            decoration: InputDecoration(
              hintText: context.tr('pet_create.search_breeds_hint'),
              hintStyle: TextStyle(
                  color: thmode.darkMode ? Colors.white70 : Colors.black54),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.patasColor),
              filled: true,
              fillColor: thmode.darkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
        slivers: [
          // Special case for SRD / Outra at the top if search is empty or matches
          if (_searchController.text.isEmpty ||
              _srdOption.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              context.tr('pet_create.srd_option')
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, context.tr('pet_create.srd_option')),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: thmode.darkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: AppColors.patasColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pets, color: AppColors.patasColor),
                        const SizedBox(width: 16),
                        Text(
                          context.tr('pet_create.srd_option'),
                          style: TextStyle(
                              color: thmode.darkMode
                                  ? Colors.white
                                  : AppColors.darkBG,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 3.2 / 3.4,
                  crossAxisCount: context.isWide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12),
              delegate: SliverChildBuilderDelegate(
                (BuildContext ctx, index) {
                  final cat = _filteredCats[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, cat.name),
                    child: Container(
                      decoration: BoxDecoration(
                        color: thmode.darkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16.0)),
                                child: Image.asset(
                                  cat.photoPath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: thmode.darkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.pets,
                                            size: 40, color: Colors.grey),
                                      ),
                                    );
                                  },
                                )),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: thmode.darkMode
                                      ? Colors.white
                                      : AppColors.darkBG,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                childCount: _filteredCats.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
