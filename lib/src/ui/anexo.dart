import 'dart:io';

import 'package:flutter/material.dart';


class Anexo extends StatelessWidget {

  final File? arquivo;

  const Anexo({super.key, required this.arquivo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
        width: double.infinity,
        child: Image.file(arquivo!, fit: BoxFit.cover));
  }
}
