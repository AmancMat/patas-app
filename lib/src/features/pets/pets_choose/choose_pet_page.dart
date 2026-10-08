import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';

import 'package:patas_web_app/src/localization/localizations_ext.dart';

class MyPets {
  final String imageMyPet;
  final String nameMyPet;

  MyPets({required this.imageMyPet, required this.nameMyPet});
}

final List<MyPets> listPets = [
  MyPets(
      imageMyPet: 'assets/my_pets/atila_corraini.png',
      nameMyPet: 'Átila Corraini'),
  MyPets(imageMyPet: 'assets/my_pets/tobby.jpeg', nameMyPet: 'Tobby Martins'),
  MyPets(imageMyPet: 'assets/my_pets/pingo.jpg', nameMyPet: 'Pingo Amâncio'),
  MyPets(
      imageMyPet: 'assets/my_pets/abrigo-amor-sem-fronteiras.jpeg',
      nameMyPet: 'Abrigo Amor Sem Fronteiras'),
];

class ChoosePetPage extends StatefulWidget {
  const ChoosePetPage({super.key});

  @override
  State<ChoosePetPage> createState() => _ChoosePetPageState();
}

class _ChoosePetPageState extends State<ChoosePetPage> {
  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      backgroundColor:
          thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
      appBar: PatasEssencialAppBar(
        title: context.tr('profile.choose_pet_title'),
        subtitle: context.tr('profile.choose_pet_subtitle'),
        leadingIcon: const Icon(
          Icons.pets_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        showBackButton: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.only(top: 50, left: 16, right: 26),
          child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 1 / 1.3,
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 20),
              itemCount: listPets.length,
              itemBuilder: (BuildContext ctx, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.patasColor,
                          child: CircleAvatar(
                              radius: 48,
                              backgroundImage:
                                  AssetImage(listPets[index].imageMyPet)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          listPets[index].nameMyPet,
                          textAlign: TextAlign.center,
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
                );
              }),
        ),
      ),
    ),
  ),
);
  }
}
