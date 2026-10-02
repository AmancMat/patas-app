import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const LoginButton({
    super.key,
    this.onPressed,
    required this.text,
  });

  final BorderRadius _borderRadius =
  const BorderRadius.all(Radius.circular(24.0));

  @override
  Widget build(BuildContext context) {
    return Ink(
      height: 48.0,
      decoration: BoxDecoration(
          borderRadius: _borderRadius,
          color: AppColors.lightBG
      ),
      child: InkWell(
        borderRadius: _borderRadius,
        onTap: onPressed,
        child: Align(
          child: Text(
            text,
            style: AppTextStyles.mediumText18.copyWith(
              color: AppColors.lightBG,
            ),
          ),
        ),
      ),
    );
  }
}
