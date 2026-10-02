import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class UiLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const UiLinkButton(this.text, {required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: AutoSizeText(
        text,
        style: const TextStyle(
            fontSize: 20,
            color: Colors.white
        ),
      ),
    );
  }
}
