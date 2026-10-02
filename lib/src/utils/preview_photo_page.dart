import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PreviewPhotoPage extends StatelessWidget {
  final File? file;

  const PreviewPhotoPage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
              child: Stack(
            children: [
              Positioned.fill(
                  child: Image.file(
                file!,
                fit: BoxFit.cover,
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppColors.patasColor.withValues(alpha: 0.5),
                        child: IconButton(
                            onPressed: () {
                              //Get.back(result: file);
                            },
                            icon: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 30,
                            )),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppColors.patasColor.withValues(alpha: 0.5),
                        child: IconButton(
                            onPressed: () {
                              //Get.back();
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            )),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ))
        ],
      ),
    );
  }
}
