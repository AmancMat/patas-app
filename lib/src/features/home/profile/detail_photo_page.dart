import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class DetailPhotoPage extends StatelessWidget {
  final String imageUrls;
  final String tag;

  const DetailPhotoPage({super.key, required this.imageUrls, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: (){
          Navigator.pop(context);
        },
        child: Hero(
          tag: tag,
          child: SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: PhotoView(
                  imageProvider: AssetImage(imageUrls))),
        ),
      ),
    );
  }
}
