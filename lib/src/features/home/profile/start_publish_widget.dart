import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/to_publish_page.dart';
import '../../../utils/responsive_layout.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class StartPublishWidget extends StatefulWidget {
  const StartPublishWidget({super.key});

  @override
  State<StartPublishWidget> createState() => _StartPublishWidgetState();
}

class _StartPublishWidgetState extends State<StartPublishWidget> {
  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.only(top: 10),
      height: 140,
      width: double.infinity,
      color: thmode.darkMode ? Colors.black54 : AppColors.bodyLight,
      child: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(left: 20),
                  child: const FaIcon(
                    FontAwesomeIcons.flag,
                    color: AppColors.patasColor,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      context.tr('feed.publish'),
                      style: TextStyle(
                        fontSize: 18,
                        color:
                            thmode.darkMode ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.settings,
                    color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
              top: 15,
              bottom: 10,
              left: 10,
              right: 15,
            ),
            height: 75,
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                if (context.isDesktop) {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierColor: Colors.black.withValues(alpha: 0.1),
                    builder: (context) => const Dialog(
                      insetPadding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      child: ToPublishPage(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ToPublishPage()),
                  );
                }
              },
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                          side: BorderSide(
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          )))),
              child: Text(
                context.tr('feed.quick_post_hint'),
                textAlign: TextAlign.start,
                style: TextStyle(
                    color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
