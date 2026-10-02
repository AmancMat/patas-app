import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../constants/app_colors.dart';

class ProfileImage extends StatefulWidget {
  const ProfileImage({super.key});

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  String selectedImagePath = '';

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    return Scaffold(
      backgroundColor:
          thmode.darkMode ? AppColors.bodygray : AppColors.selectedColor,
      body: GestureDetector(
        onTap: () async {
          selectImage();
          setState(() {});
        },
        child: Center(
          child: Stack(
            children: [
              selectedImagePath == ''
                  ? Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/image_publish_content.png',
                        height: 100.h,
                        width: 100.w,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Align(
                      alignment: Alignment.center,
                      child: Image.file(
                        File(selectedImagePath),
                        height: 200.h,
                        width: 200.w,
                        fit: BoxFit.cover,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future selectImage() {
    if (context.isWide) {
      return selectImageFromGallery().then((path) {
        if (path != '') {
          selectedImagePath = path;
          setState(() {});
        }
      });
    }

    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)), //this right here
            child: SizedBox(
              height: 150.h,
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  children: [
                    Text(
                      'Escolher a partir de...',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            selectedImagePath = await selectImageFromGallery();
                            // print('Image_Path:-');
                            // print(selectedImagePath);
                            if (selectedImagePath != '') {
                              if (context.mounted) Navigator.pop(context);
                              setState(() {});
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text("No Image Captured !"),
                                ));
                              }
                            }
                          },
                          child: Card(
                              elevation: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.r),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/gallery.png',
                                      height: 60.h,
                                      width: 60.w,
                                    ),
                                    const Text('Gallery'),
                                  ],
                                ),
                              )),
                        ),
                        GestureDetector(
                          onTap: () async {
                            selectedImagePath = await selectImageFromCamera();
                            // print('Image_Path:-');
                            // print(selectedImagePath);
                            if (selectedImagePath != '') {
                              if (context.mounted) Navigator.pop(context);
                              setState(() {});
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text("No Image Captured !"),
                                ));
                              }
                            }
                          },
                          child: Card(
                              elevation: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.r),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/camera.png',
                                      height: 60.h,
                                      width: 60.w,
                                    ),
                                    const Text('Camera'),
                                  ],
                                ),
                              )),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  selectImageFromGallery() async {
    XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 10);
    if (file != null) {
      return file.path;
    } else {
      return '';
    }
  }

//
  selectImageFromCamera() async {
    XFile? file = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 10);
    if (file != null) {
      return file.path;
    } else {
      return '';
    }
  }
}
