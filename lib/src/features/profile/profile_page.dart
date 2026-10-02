import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patas_web_app/src/features/bottom_navi_bar/bottom_navi_bar.dart';
import 'package:patas_web_app/src/utils/cover_image.dart';
import 'package:patas_web_app/src/utils/profile_image.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../constants/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // final _userProfileController =

  final TextEditingController _namePetController = TextEditingController();
  final TextEditingController _racaPetController = TextEditingController();
  final TextEditingController _datePetController = TextEditingController();
  final TextEditingController _localBirthPetController =
      TextEditingController();
  final TextEditingController _localLivePetController = TextEditingController();
  final TextEditingController _nameMotherPetController =
      TextEditingController();
  final TextEditingController _nameFatherPetController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
      appBar: AppBar(
        backgroundColor:
            thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
        elevation: 0,
        title: Text(
          'Informações do Perfil',
          style: TextStyle(
              color: thmode.darkMode ? Colors.white : AppColors.darkBG,
              fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 400,
                    width: MediaQuery.of(context).size.width,
                    child: const CoverImage(),
                  ),
                  Container(
                    color: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    height: 80,
                    width: double.infinity,
                  )
                ],
              ),
              Positioned(
                  top: MediaQuery.of(context).size.height * .295,
                  left: MediaQuery.of(context).size.width * .03,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          offset: const Offset(0, 3),
                          blurRadius: 5,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      shape: const CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      child: Container(
                        color: Colors.blue,
                        width: MediaQuery.of(context).size.width * .32,
                        height: MediaQuery.of(context).size.width * .32,
                        child: const ProfileImage(),
                      ),
                    ),
                  )),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(
              top: 30,
            ),
            width: double.infinity,
            margin: const EdgeInsets.only(left: 16),
            child: Text(
              'Dados Pessoais',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16, right: 24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _namePetController,
                    validator: (value) {
                      if (_namePetController.text.isEmpty) {
                        return 'Este campo precisa ser preenchido';
                      }
                      return null;
                    },
                    style: TextStyle(
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                    cursorColor:
                        thmode.darkMode ? Colors.white : AppColors.darkBG,
                    decoration: InputDecoration(
                        fillColor:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        hintStyle: TextStyle(
                          color:
                              thmode.darkMode ? Colors.white : AppColors.darkBG,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color:
                              thmode.darkMode ? Colors.white : AppColors.darkBG,
                        ),
                        labelText: 'Nome do Pet',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 15)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _racaPetController,
                    validator: (value) {
                      if (_racaPetController.text.isEmpty) {
                        return 'Este campo precisa ser preenchido';
                      }
                      return null;
                    },
                    style: TextStyle(
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                    cursorColor:
                        thmode.darkMode ? Colors.white : AppColors.darkBG,
                    decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color:
                              thmode.darkMode ? Colors.white : AppColors.darkBG,
                        ),
                        labelText: 'Raça',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 15)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    readOnly: true,
                    controller: _datePetController,
                    validator: (value) {
                      if (_datePetController.text.isEmpty) {
                        return 'Este campo precisa ser preenchido';
                      }
                      return null;
                    },
                    onTap: () async {
                      final now = DateTime.now();
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(1970),
                        lastDate: now,
                        selectableDayPredicate: (date) {
                          return date.isBefore(now) ||
                              date.isAtSameMomentAs(now);
                        },
                      );

                      if (pickedDate != null) {
                        _datePetController.text =
                            DateFormat('dd/MM/yyyy').format(pickedDate);
                      }
                    },
                    style: TextStyle(
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                    cursorColor:
                        thmode.darkMode ? Colors.white : AppColors.darkBG,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(
                          width: 1,
                          color:
                              thmode.darkMode ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(
                          width: 1,
                          color:
                              thmode.darkMode ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                        fontSize: 12,
                      ),
                      labelText: 'Data de Nascimento',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 15,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _localBirthPetController,
                    validator: (value) {
                      if (_localBirthPetController.text.isEmpty) {
                        return 'Este campo precisa ser preenchido';
                      }
                      return null;
                    },
                    style: TextStyle(
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                    cursorColor:
                        thmode.darkMode ? Colors.white : AppColors.darkBG,
                    decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        labelStyle: TextStyle(
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                            fontSize: 12),
                        labelText: 'Local de Nascimento',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 15)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _localLivePetController,
                    validator: (value) {
                      if (_localLivePetController.text.isEmpty) {
                        return 'Este campo precisa ser preenchido';
                      }
                      return null;
                    },
                    style: TextStyle(
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                    cursorColor:
                        thmode.darkMode ? Colors.white : AppColors.darkBG,
                    decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        labelStyle: TextStyle(
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                            fontSize: 12),
                        labelText: 'Onde Vive',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 15)),
                  ),
                ),
                Container(
                  color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                  height: 1,
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                      top: 50, bottom: 30, left: 16, right: 16),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Família',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _nameMotherPetController,
                    validator: (value) {
                      if (_nameMotherPetController.text.isEmpty) {
                        return 'Este campo precisa ser preenchido';
                      }
                      return null;
                    },
                    style: TextStyle(
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                    cursorColor:
                        thmode.darkMode ? Colors.white : AppColors.darkBG,
                    decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        labelStyle: TextStyle(
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                            fontSize: 12),
                        labelText: 'Nome da Mãe',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 15)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: TextFormField(
                    controller: _nameFatherPetController,
                    validator: (value) {
                      if (_nameFatherPetController.text.isEmpty) {
                        return 'Este campo precisa ser preenchido';
                      }
                      return null;
                    },
                    style: TextStyle(
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                    cursorColor:
                        thmode.darkMode ? Colors.white : AppColors.darkBG,
                    decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            width: 1,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        labelStyle: TextStyle(
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                            fontSize: 12),
                        labelText: 'Nome do Pai',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 15)),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.only(bottom: 50, right: 250),
                //   child: MaterialButton(
                //       height: 42,
                //       minWidth: 50,
                //       color: AppColors.patasColor,
                //       shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(16)),
                //       onPressed: () {},
                //       child: Row(
                //         children: [
                //           Icon(
                //             Icons.add,
                //             color: thmode.darkMode
                //                 ? Colors.white
                //                 : AppColors.darkBG,
                //           ),
                //           Icon(
                //             Icons.face_outlined,
                //             color: thmode.darkMode
                //                 ? Colors.white
                //                 : AppColors.darkBG,
                //           )
                //         ],
                //       )),
                // ),
                Padding(
                  padding: const EdgeInsets.only(top: 50, bottom: 50),
                  child: MaterialButton(
                      height: 42,
                      minWidth: double.infinity,
                      color: AppColors.patasColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const BottomNaviBar()));
                      },
                      child: Text(
                        'Criar Perfil',
                        style: TextStyle(
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      )),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
