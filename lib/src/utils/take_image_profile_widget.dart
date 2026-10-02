import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/utils/preview_photo_page.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../constants/app_colors.dart';
import '../ui/anexo.dart';

class TakeImageProfileWidget extends StatefulWidget {
  const TakeImageProfileWidget({super.key});

  @override
  State<TakeImageProfileWidget> createState() => _TakeImageProfileWidgetState();
}

class _TakeImageProfileWidgetState extends State<TakeImageProfileWidget> {
  File? arquivo;
  final picker = ImagePicker();

  Future getFileFromGalery() async {
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        arquivo = File(file.path);
      });
    }
  }

  showPreview(file) async {
    file = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => PreviewPhotoPage(file: file)));

    if (file != null) {
      setState(() => arquivo = file);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      backgroundColor: AppColors.darkBG,
      body: Container(
        height: 150,
        width: double.infinity,
        color: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
        child: Center(
            child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      // onTap: () =>
                      //     Get.to(
                      //           () =>
                      //           CameraCamera(onFile: (file) => showPreview(file)),
                      //     ),
                      child: const SizedBox(
                          height: 30,
                          width: 50,
                          child: Column(
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 30,
                                color: AppColors.patasColor,
                              ),
                            ],
                          )),
                    ),
                    GestureDetector(
                      onTap: () => getFileFromGalery(),
                      child: const SizedBox(
                        height: 30,
                        width: 50,
                        child: Column(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 30,
                              color: AppColors.patasColor,
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            if (arquivo != null) Anexo(arquivo: arquivo),
          ],
        )),
      ),
    );
  }
}
