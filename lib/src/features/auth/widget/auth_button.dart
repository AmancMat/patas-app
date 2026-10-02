import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/bottom_navi_bar/bottom_navi_bar.dart';
import '../../../constants/app_colors.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: TextButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const BottomNaviBar()));
          },
          style: ButtonStyle(
              elevation: WidgetStateProperty.all(6),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0),
              ))),
          child: Text(
            'Entrar',
            style: PatasText().authButtonTextWhite,
          )),
    );
  }
}
