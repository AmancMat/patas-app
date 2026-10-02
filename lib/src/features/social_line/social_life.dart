import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';

class SocialLife extends StatefulWidget {
  const SocialLife({super.key});

  @override
  State<SocialLife> createState() => _SocialLifeState();
}

class _SocialLifeState extends State<SocialLife> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBG,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkBG,
        automaticallyImplyLeading: false,
        toolbarHeight: 85,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 4, right: 4),
              child: const Text(
                'Patas',
                style: TextStyle(
                  color: AppColors.patasColor,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Text(
              'Vida Social',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 80, right: 80),
              child: Text(
                'Em breve nesta sessão, você terá acesso a uma timeline excluvida da vida do seu pet! Com ela, vc poderá acompanhar e rever toda a história do seu pet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
