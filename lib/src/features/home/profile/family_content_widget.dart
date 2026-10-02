import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';

class FamilyWidget {
  final String familyTitle;
  final String familyName;
  final String familyPhoto;

  FamilyWidget({
    required this.familyTitle,
    required this.familyName,
    required this.familyPhoto,
  });
}

final List<FamilyWidget> listF = [
  FamilyWidget(
      familyTitle: 'Mãe',
      familyName: 'Ana Silveira',
      familyPhoto: 'assets/mae.jpg'),
  FamilyWidget(
      familyTitle: 'Pai',
      familyName: 'Thiago Silveira',
      familyPhoto: 'assets/pai.jpg')
];

class FamilyContentWidget extends StatelessWidget {
  const FamilyContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return GridView.builder(
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 0.5,
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10),
        itemCount: listF.length,
        itemBuilder: (BuildContext ctx, index) {
          return Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 15, bottom: 8, left: 10),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Material(
                    //elevation: 4.0,
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    clipBehavior: Clip.hardEdge,
                    //color: Colors.transparent,
                    child: Image.asset(
                      listF[index].familyPhoto,
                      fit: BoxFit.cover,
                    )),
              ),
              Container(
                margin: const EdgeInsets.only(left: 12),
                width: 100,
                height: 20,
                child: Center(
                  child: Text(
                    listF[index].familyTitle,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 12),
                width: 100,
                height: 40,
                child: Center(
                  child: Text(
                    listF[index].familyName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }
}
