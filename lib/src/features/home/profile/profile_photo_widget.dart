import 'package:flutter/material.dart';
import 'dart:math';

class ProfilePhotoWidget extends StatefulWidget {
  const ProfilePhotoWidget({super.key});

  @override
  State<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  List<String> imageUrls = [
    'assets/test_photo/g1.jpg',
    'assets/test_photo/g2.jpg',
    'assets/test_photo/g3.jpg',
    'assets/test_photo/g4.jpg',
    'assets/test_photo/g5.jpg',
    'assets/test_photo/g6.jpg',
    'assets/test_photo/g7.jpg',
    'assets/test_photo/g8.jpg',
  ];

  Map<String, int> sizeCounter = {'1:1': 0, '1:2': 0};

  List<Pair<int, String>> imageSizes = [];

  String generateRandomRatio(int index) {
    if (imageSizes.length > index) {
      return imageSizes[index].second;
    }
    Random random = Random();
    List<String> ratios = ['1:1', '1:2'];
    String ratio = ratios[random.nextInt(ratios.length)];
    if (sizeCounter[ratio]! < 4) {
      sizeCounter[ratio] = (sizeCounter[ratio] ?? 0) + 1;
    } else {
      ratios.remove(ratio);
      ratio = ratios[random.nextInt(ratios.length)];
      sizeCounter[ratio] = (sizeCounter[ratio] ?? 0) + 1;
    }
    imageSizes.add(Pair(index, ratio));
    return ratio;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto de Perfil'),
      ),
      // body: StaggeredGridView.countBuilder(
      //   crossAxisCount: 2,
      //   itemCount: imageUrls.length,
      //   staggeredTileBuilder: (index) {
      //     return StaggeredTile.count(1, index.isEven ? 1.2 : 1.8);
      //   },
      //   mainAxisSpacing: 4.0,
      //   crossAxisSpacing: 4.0,
      //   itemBuilder: (BuildContext context, int index) {
      //     return GestureDetector(
      //       onTap: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (context) => DetailPhotoPage(
      //                   imageUrls: imageUrls[index], tag: 'image$index')),
      //         );
      //       },
      //       child: Hero(
      //         tag: 'image$index',
      //         child: Image.asset(
      //           imageUrls[index],
      //           fit: BoxFit.cover,
      //         ),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}

class Pair<K, V> {
  final K first;
  final V second;

  Pair(this.first, this.second);
}
