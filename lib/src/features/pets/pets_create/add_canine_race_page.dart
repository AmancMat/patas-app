import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';

import '../models/pet_race_model.dart';

final List<PetRace> lisDogs = [
  PetRace(
      photoPath: 'assets/dogs_images/Affenpinscher.jpg', name: 'Affenpinscher'),
  PetRace(
      photoPath: 'assets/dogs_images/Afghan_Hound.jpg', name: 'Afghan Hound'),
  PetRace(
      photoPath: 'assets/dogs_images/airedale_terrier_v3.jpg',
      name: 'Airedale Terrier'),
  PetRace(photoPath: 'assets/dogs_images/akita_v3.jpg', name: 'Akita'),
  PetRace(
      photoPath: 'assets/dogs_images/Alaskan_Klee_Kai.jpg',
      name: 'Alaskan Klee Kai'),
  PetRace(
      photoPath: 'assets/dogs_images/Alaskan_Malamute.jpg',
      name: 'Alaskan Malamute'),
  PetRace(
      photoPath: 'assets/dogs_images/American_Bulldog.jpg',
      name: 'American Bulldog'),
  PetRace(
      photoPath: 'assets/dogs_images/American_English_Coonhound.jpg',
      name: 'American English Coonhound'),
  PetRace(
      photoPath: 'assets/dogs_images/American_Eskimo_Dog.jpg',
      name: 'American Eskimo Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/american_foxhound.webp',
      name: 'American Foxhound'),
  PetRace(
      photoPath: 'assets/dogs_images/American_Hairless_Terrier.webp',
      name: 'American Hairless Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/American_Leopard_Hound.jpg',
      name: 'American Leopard Hound'),
  PetRace(
      photoPath: 'assets/dogs_images/American_Staffordshire_Terrier.webp',
      name: 'American Staffordshire Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/American_Water_Spaniel.webp',
      name: 'American Water Spaniel'),
  PetRace(
      photoPath: 'assets/dogs_images/Anatolian_Shepherd_Dog.jpg',
      name: 'Anatolian Shepherd Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Appenzeller_Sennenhund.jpg',
      name: 'Appenzeller Sennenhund'),
  PetRace(
      photoPath: 'assets/dogs_images/Australian_Cattle_Dog.webp',
      name: 'Australian Cattle Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Australian_Kelpie.jpg',
      name: 'Australian Kelpie'),
  PetRace(
      photoPath: 'assets/dogs_images/Australian_Shepherd.webp',
      name: 'Australian Shepherd'),
  PetRace(
      photoPath: 'assets/dogs_images/Australian_Stumpy_Tail_Cattle_Dog.jpg',
      name: 'Australian Stumpy Tail Cattle Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Australian_Terrier.jpg',
      name: 'Australian Terrier'),
  PetRace(photoPath: 'assets/dogs_images/Azawakh.jpg', name: 'Azawakh'),
  PetRace(
      photoPath: 'assets/dogs_images/Barbado_da_Terceira.jpg',
      name: 'Barbado da Terceira'),
  PetRace(photoPath: 'assets/dogs_images/Barbet.webp', name: 'Barbet'),
  PetRace(photoPath: 'assets/dogs_images/Basenji.webp', name: 'Basenji'),
  PetRace(
      photoPath: 'assets/dogs_images/Basset_Fauve_de_Bretagne.webp',
      name: 'Basset Fauve de Bretagne'),
  PetRace(
      photoPath: 'assets/dogs_images/Basset_Hound.jpg', name: 'Basset Hound'),
  PetRace(
      photoPath: 'assets/dogs_images/Bavarian_Mountain_Scent_Hound.webp',
      name: 'Bavarian Mountain Scent Hound'),
  PetRace(photoPath: 'assets/dogs_images/Beagles.webp', name: 'Beagle'),
  PetRace(
      photoPath: 'assets/dogs_images/Bearded_Collie.webp',
      name: 'Bearded Collie'),
  PetRace(photoPath: 'assets/dogs_images/Beauceron.webp', name: 'Beauceron'),
  PetRace(
      photoPath: 'assets/dogs_images/Bedlington_Terrier.webp',
      name: 'Bedlington Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/Belgian_Laekenois.jpg',
      name: 'Belgian Laekenois'),
  PetRace(
      photoPath: 'assets/dogs_images/Belgian_Malinois.webp',
      name: 'Belgian Malinois'),
  PetRace(
      photoPath: 'assets/dogs_images/Belgian_Sheepdog.webp',
      name: 'Belgian Sheepdog'),
  PetRace(
      photoPath: 'assets/dogs_images/Belgian_Tervuren.jpg',
      name: 'Belgian Tervuren'),
  PetRace(
      photoPath: 'assets/dogs_images/Bergamasco_Sheepdog.webp',
      name: 'Bergamasco Sheepdog'),
  PetRace(
      photoPath: 'assets/dogs_images/Berger_Picard.jpg', name: 'Berger Picard'),
  PetRace(
      photoPath: 'assets/dogs_images/Bernese_Mountain_Dog.webp',
      name: 'Bernese Mountain Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Bichon_Frise.webp', name: 'Bichon Frise'),
  PetRace(
      photoPath: 'assets/dogs_images/Biewer_Terrier.webp',
      name: 'Biewer Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/Black_and_Tan_Coonhound.webp',
      name: 'Black and Tan Coonhound'),
  PetRace(
      photoPath: 'assets/dogs_images/Black_Russian_Terrier.webp',
      name: 'Black Russian Terrier'),
  PetRace(photoPath: 'assets/dogs_images/Bloodhound.webp', name: 'Bloodhound'),
  PetRace(
      photoPath: 'assets/dogs_images/Bluetick_Coonhound.jpg',
      name: 'Bluetick Coonhound'),
  PetRace(photoPath: 'assets/dogs_images/Boerboel.webp', name: 'Boerboel'),
  PetRace(
      photoPath: 'assets/dogs_images/Bohemian_Shepherd.jpg',
      name: 'Bohemian Shepherd'),
  PetRace(photoPath: 'assets/dogs_images/Bolognese.jpg', name: 'Bolognese'),
  PetRace(
      photoPath: 'assets/dogs_images/Border_Collie.webp',
      name: 'Border Collie'),
  PetRace(
      photoPath: 'assets/dogs_images/Border_Terrier.webp',
      name: 'Border Terrier'),
  PetRace(photoPath: 'assets/dogs_images/Borzoi.webp', name: 'Borzoi'),
  PetRace(
      photoPath: 'assets/dogs_images/Boston_Terrier.webp',
      name: 'Boston Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/Bouvier_des_Flandres.webp',
      name: 'Bouvier des Flandres'),
  PetRace(photoPath: 'assets/dogs_images/Boxer.webp', name: 'Boxer'),
  PetRace(
      photoPath: 'assets/dogs_images/Boykin_Spaniel.webp',
      name: 'Boykin Spaniel'),
  PetRace(
      photoPath: 'assets/dogs_images/Bracco_Italiano.jpg',
      name: 'Bracco Italiano'),
  PetRace(
      photoPath: 'assets/dogs_images/Braque_du_Bourbonnais.jpg',
      name: 'Braque du Bourbonnais'),
  PetRace(
      photoPath: 'assets/dogs_images/Braque_Francais_Pyrenean.webp',
      name: 'Braque Francais Pyrenean'),
  PetRace(photoPath: 'assets/dogs_images/Briard.webp', name: 'Briard'),
  PetRace(photoPath: 'assets/dogs_images/Brittany.webp', name: 'Brittany'),
  PetRace(photoPath: 'assets/dogs_images/Broholmer.jpg', name: 'Broholmer'),
  PetRace(
      photoPath: 'assets/dogs_images/Brussels_Griffon.webp',
      name: 'Brussels Griffon'),
  PetRace(photoPath: 'assets/dogs_images/Bulldog.webp', name: 'Bulldog'),
  PetRace(
      photoPath: 'assets/dogs_images/Bullmastiff.webp', name: 'Bullmastiff'),
  PetRace(
      photoPath: 'assets/dogs_images/bull_terrier.webp', name: 'Bull Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/Cairn_Terrier.webp',
      name: 'Cairn Terrier'),
  PetRace(photoPath: 'assets/dogs_images/Canaan_Dog.webp', name: 'Canaan Dog'),
  PetRace(photoPath: 'assets/dogs_images/Cane_Corso.webp', name: 'Cane Corso'),
  PetRace(
      photoPath: 'assets/dogs_images/Cardigan_Welsh_Corgi.webp',
      name: 'Cardigan Welsh Corgi'),
  PetRace(
      photoPath: 'assets/dogs_images/Carolina_Dog.webp', name: 'Carolina Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Catahoula_Leopard-Dog.webp',
      name: 'Catahoula Leopard Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Caucasian_Shepherd_Dog.jpg',
      name: 'Caucasian Shepherd Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Cavalier_King_Charles_Spaniel.webp',
      name: 'Cavalier King Charles Spaniel'),
  PetRace(
      photoPath: 'assets/dogs_images/Central_Asian_Shepherd_Dog.jpg',
      name: 'Central Asian Shepherd Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Cesky_Terrier.webp',
      name: 'Cesky Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/Chesapeake_Bay_Retriever.webp',
      name: 'Chesapeake Bay Retriever'),
  PetRace(photoPath: 'assets/dogs_images/Chihuahua.webp', name: 'Chihuahua'),
  PetRace(
      photoPath: 'assets/dogs_images/Chinese_Crested.webp',
      name: 'Chinese Crested'),
  PetRace(
      photoPath: 'assets/dogs_images/Chinese_Shar_Pei.webp',
      name: 'Chinese Shar Pei'),
  PetRace(photoPath: 'assets/dogs_images/Chinook.webp', name: 'Chinook'),
  PetRace(photoPath: 'assets/dogs_images/Chow_Chow.webp', name: 'Chow Chow'),
  PetRace(
      photoPath: 'assets/dogs_images/Cirneco_dellEtna.jpg',
      name: 'Cirneco dell Etna'),
  PetRace(
      photoPath: 'assets/dogs_images/Clumber_Spaniel.webp',
      name: 'Clumber Spaniel'),
  PetRace(
      photoPath: 'assets/dogs_images/Cocker_Spaniel.webp',
      name: 'Cocker Spaniel'),
  PetRace(photoPath: 'assets/dogs_images/Collie.jpg', name: 'Collie'),
  PetRace(
      photoPath: 'assets/dogs_images/Coton_de_Tulear.jpg',
      name: 'Coton de Tulear'),
  PetRace(
      photoPath: 'assets/dogs_images/Croatian_Sheepdog.jpg',
      name: 'Croatian Sheepdog'),
  PetRace(
      photoPath: 'assets/dogs_images/Curly_Coated_Retriever.webp',
      name: 'Curly Coated Retriever'),
  PetRace(
      photoPath: 'assets/dogs_images/Czechoslovakian_Vlcak.jpg',
      name: 'Czechoslovakian Vlcak'),
  PetRace(photoPath: 'assets/dogs_images/Dachshund.webp', name: 'Dachshund'),
  PetRace(photoPath: 'assets/dogs_images/Dalmatian.webp', name: 'Dalmatian'),
  PetRace(
      photoPath: 'assets/dogs_images/Dandie_Dinmont_Terrier.jpg',
      name: 'Dandie Dinmont Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/Danish_Swedish_Farmdog.webp',
      name: 'Danish Swedish Farmdog'),
  PetRace(
      photoPath: 'assets/dogs_images/Deutscher_Wachtelhund.jpg',
      name: 'Deutscher Wachtelhund'),
  PetRace(
      photoPath: 'assets/dogs_images/Doberman_Pinscher.webp',
      name: 'Doberman Pinscher'),
  PetRace(
      photoPath: 'assets/dogs_images/Dogo_Argentino.webp',
      name: 'Dogo Argentino'),
  PetRace(
      photoPath: 'assets/dogs_images/Dogue_de_Bordeaux.webp',
      name: 'Dogue de Bordeaux'),
  PetRace(
      photoPath: 'assets/dogs_images/Drentsche_Patrijshond.jpg',
      name: 'Drentsche Patrijshond'),
  PetRace(photoPath: 'assets/dogs_images/Drever.webp', name: 'Drever'),
  PetRace(
      photoPath: 'assets/dogs_images/Dutch_Shepherd.jpg',
      name: 'Dutch Shepherd'),
  PetRace(
      photoPath: 'assets/dogs_images/English_Cocker_Spaniel.jpg',
      name: 'English Cocker Spaniel'),
  PetRace(
      photoPath: 'assets/dogs_images/English_Foxhound.webp',
      name: 'English Foxhound'),
  PetRace(
      photoPath: 'assets/dogs_images/English_Setter.jpg',
      name: 'English Setter'),
  PetRace(
      photoPath: 'assets/dogs_images/English_Springer_Spaniel.webp',
      name: 'English Springer Spaniel'),
  PetRace(
      photoPath: 'assets/dogs_images/English_Toy_Spaniel.webp',
      name: 'English Toy Spaniel'),
  PetRace(
      photoPath: 'assets/dogs_images/Entlebucher_Mountain_Dog.webp',
      name: 'Entlebucher Mountain Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Estrela_Mountain_Dog.jpg',
      name: 'Estrela Mountain Dog'),
  PetRace(
      photoPath: 'assets/dogs_images/Fila_Brasileiro.jpg',
      name: 'Fila Brasileiro'),
  PetRace(
      photoPath: 'assets/dogs_images/French_Bulldog.webp',
      name: 'French Bulldog'),
  PetRace(
      photoPath: 'assets/dogs_images/German_Shepherd.webp',
      name: 'German Shepherd'),
  PetRace(
      photoPath: 'assets/dogs_images/Golden_Retriever.webp',
      name: 'Golden Retriever'),
  PetRace(photoPath: 'assets/dogs_images/Great_Dane.webp', name: 'Great Dane'),
  PetRace(photoPath: 'assets/dogs_images/Greyhound.webp', name: 'Greyhound'),
  PetRace(
      photoPath: 'assets/dogs_images/Jack_Russell_Terrier.webp',
      name: 'Jack Russell Terrier'),
  PetRace(
      photoPath: 'assets/dogs_images/Labrador_Retriever.webp',
      name: 'Labrador Retriever'),
  PetRace(photoPath: 'assets/dogs_images/Lhasa_Apso.webp', name: 'Lhasa Apso'),
  PetRace(photoPath: 'assets/dogs_images/Maltese.webp', name: 'Maltese'),
  PetRace(photoPath: 'assets/dogs_images/Mastiff.webp', name: 'Mastiff'),
  PetRace(
      photoPath: 'assets/dogs_images/Old_English_Sheepdog.webp',
      name: 'Old English Sheepdog'),
  PetRace(photoPath: 'assets/dogs_images/Papillon.webp', name: 'Papillon'),
  PetRace(photoPath: 'assets/dogs_images/Pekingese.webp', name: 'Pekingese'),
  PetRace(photoPath: 'assets/dogs_images/Pitbull.jpg', name: 'Pitbull'),
  PetRace(photoPath: 'assets/dogs_images/Pomeranian.webp', name: 'Pomeranian'),
  PetRace(photoPath: 'assets/dogs_images/Poodle.webp', name: 'Poodle'),
  PetRace(photoPath: 'assets/dogs_images/Pug.webp', name: 'Pug'),
  PetRace(photoPath: 'assets/dogs_images/Rottweiler.jpg', name: 'Rottweiler'),
  PetRace(
      photoPath: 'assets/dogs_images/Saint_Bernard.webp',
      name: 'Saint Bernard'),
  PetRace(photoPath: 'assets/dogs_images/Samoyed.webp', name: 'Samoyed'),
  PetRace(photoPath: 'assets/dogs_images/Shar_Pei.webp', name: 'Shar Pei'),
  PetRace(photoPath: 'assets/dogs_images/Shiba_Inu.webp', name: 'Shiba Inu'),
  PetRace(photoPath: 'assets/dogs_images/Shih_Tzu.webp', name: 'Shih Tzu'),
  PetRace(
      photoPath: 'assets/dogs_images/Siberian_Husky.webp',
      name: 'Siberian Husky'),
  PetRace(photoPath: 'assets/dogs_images/Vizsla.webp', name: 'Vizsla'),
  PetRace(photoPath: 'assets/dogs_images/Weimaraner.webp', name: 'Weimaraner'),
  PetRace(photoPath: 'assets/dogs_images/Whippet.webp', name: 'Whippet'),
  PetRace(
      photoPath: 'assets/dogs_images/Yorkshire_Terrier.webp',
      name: 'Yorkshire Terrier'),
];

class AddCanineRacePage extends StatefulWidget {
  const AddCanineRacePage({super.key});

  @override
  State<AddCanineRacePage> createState() => _AddCanineRacePageState();
}

class _AddCanineRacePageState extends State<AddCanineRacePage> {
  final TextEditingController _searchController = TextEditingController();
  List<PetRace> _filteredDogs = lisDogs;

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
      _filteredDogs = lisDogs.where((dog) {
        return dog.name.toLowerCase().contains(query);
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
        title: 'Raças de Cães',
        subtitle: 'Escolha a raça do seu cão',
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
              hintText: 'Pesquisar raças...',
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
          // Especial case for SRD / Outra at the top if search is empty or matches
          if (_searchController.text.isEmpty ||
              _srdOption.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, _srdOption.name),
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
                          _srdOption.name,
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
                  final dog = _filteredDogs[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, dog.name),
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
                                  dog.photoPath,
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
                              dog.name,
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
                childCount: _filteredDogs.length,
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
