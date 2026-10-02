import 'package:flutter/material.dart';

class PatasText {

  TextStyle appBarTitle = const TextStyle(
    fontFamily: 'Roboto_flex',
    fontWeight: FontWeight.normal,
    fontSize: 28,
  );

  TextStyle header1 = const TextStyle(
    fontFamily: 'Fredoka',
    fontWeight: FontWeight.bold,
    fontSize: 30,
  );

  TextStyle litleHeader = const TextStyle(
    fontFamily: 'Roboto_flex',
    fontWeight: FontWeight.w500,
    fontSize: 10,
  );

  TextStyle miniHeader = const TextStyle(
    fontFamily: 'Roboto_flex',
    fontWeight: FontWeight.w500,
    fontSize: 8,
  );

  TextStyle highlightText = const TextStyle(
    fontFamily: 'Fredoka',
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  TextStyle body1 = const TextStyle(
    fontFamily: 'Roboto_flex',
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  TextStyle buttomText = const TextStyle(
    fontFamily: 'Roboto_flex',
    fontWeight: FontWeight.normal,
    fontSize: 22,
  );

  TextStyle authButtonTextWhite = const TextStyle(
    color: AppColors.lightBG,
    fontFamily: 'Fredoka',
    fontWeight: FontWeight.normal,
    fontSize: 22,
  );

  TextStyle authButtonTextPatas = const TextStyle(
    color: AppColors.patasColor,
    fontFamily: 'Fredoka',
    fontWeight: FontWeight.normal,
    fontSize: 22,
  );

  TextStyle miniButtomText = const TextStyle(
    fontFamily: 'Roboto_flex',
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

}

class AppColors {
  AppColors._();

  static const Color selectedColor = Colors.white;
  static Color bodyLight = Colors.orange.shade50;
  static const Color bodyRegister = Color(0xff526870); // WCAG AA: 5.9:1 em fundo branco (era #6a858d, ratio 3.9:1)
  static const Color bodyAbsoluteBlack = Color(0xff141414);
  static const Color darkBG = Color(0xff212121);
  static const Color lightBG = Color(0xffffffff);
  static const Color bodygray = Color(0xff444444);
  static const Color patasColor = Color(0xffE54F2F);
  static const Color patasIntense = Color(0xffFC3028);
  static const Color patasPink = Color(0xffD4185C); // WCAG AA: 5.1:1 em fundo branco (era #F22772, ratio 3.9:1)
  static const Color patasSoft = Color(0xffFC6E28);
  static const Color patasLightColor = Color.fromRGBO(224, 116, 93, 1.0);
  static const Color patasLight = Color(0xffcc0505);

  static List<Color> patasGradient = [
    const Color(0xffE54F2F),
    const Color(0xffFC6E28),
  ];
  static List<Color> greyGradient = [
    const Color(0xFFB5B5B5),
    const Color(0xFF7F7F7F),
  ];
  static const List<Color> greenGradient = [
    Color(0xFF63B5AF),
    Color(0xFF438883),
  ];

}
