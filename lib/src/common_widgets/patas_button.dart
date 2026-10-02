import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum PatasButtonVariant {
  primary, // Gradiente padrão da marca (Laranja -> Magenta)
  secondary, // Outline / Transparente com borda
  accent, // Cor sólida alternativa (Laranja chapado)
  disabled, // Cinza inativo
}

enum PatasButtonSize {
  small, // Altura 36.0 (Card Actions)
  medium, // Altura 48.0 (Formulários padrão)
  large, // Altura 56.0 (Destaques de boas-vindas / Boas vindas)
}

class PatasButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final PatasButtonVariant variant;
  final PatasButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticsLabel;

  const PatasButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = PatasButtonVariant.primary,
    this.size = PatasButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.semanticsLabel,
  });

  // Raio de borda constante do design do Patas
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(24.0),
  );

  double get _height {
    switch (size) {
      case PatasButtonSize.small:
        return 36.0;
      case PatasButtonSize.medium:
        return 48.0;
      case PatasButtonSize.large:
        return 56.0;
    }
  }

  double get _fontSize {
    switch (size) {
      case PatasButtonSize.small:
        return 14.0;
      case PatasButtonSize.medium:
        return 16.0;
      case PatasButtonSize.large:
        return 18.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isButtonEnabled = onPressed != null && !isLoading;
    final double buttonHeight = _height;

    // Build decoration based on Variant
    BoxDecoration decoration;
    TextStyle textStyle = TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.bold,
      fontSize: _fontSize,
    );

    if (!isButtonEnabled) {
      decoration = BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: _borderRadius,
      );
      textStyle = textStyle.copyWith(color: Colors.grey.shade600);
    } else {
      switch (variant) {
        case PatasButtonVariant.primary:
          decoration = BoxDecoration(
            borderRadius: _borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: AppColors.patasGradient,
            ),
          );
          textStyle = textStyle.copyWith(color: Colors.white);
          break;

        case PatasButtonVariant.secondary:
          decoration = BoxDecoration(
            borderRadius: _borderRadius,
            border: Border.all(color: AppColors.patasColor, width: 2.0),
            color: Colors.transparent,
          );
          textStyle = textStyle.copyWith(color: AppColors.patasColor);
          break;

        case PatasButtonVariant.accent:
          decoration = BoxDecoration(
            borderRadius: _borderRadius,
            color: AppColors.patasColor,
          );
          textStyle = textStyle.copyWith(color: Colors.white);
          break;

        case PatasButtonVariant.disabled:
          decoration = BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: _borderRadius,
          );
          textStyle = textStyle.copyWith(color: Colors.grey.shade600);
          break;
      }
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: buttonHeight * 0.5,
        width: buttonHeight * 0.5,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == PatasButtonVariant.secondary
                ? AppColors.patasColor
                : Colors.white,
          ),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: _fontSize + 2.0,
              color: variant == PatasButtonVariant.secondary
                  ? AppColors.patasColor
                  : Colors.white,
            ),
            const SizedBox(width: 8.0),
          ],
          Text(text, style: textStyle, textAlign: TextAlign.center),
        ],
      );
    }

    Widget buttonWidget = SizedBox(
      height: buttonHeight,
      child: Card(
        elevation: isButtonEnabled && variant != PatasButtonVariant.secondary
            ? 3.0
            : 0.0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
        child: InkWell(
          borderRadius: _borderRadius,
          onTap: isButtonEnabled ? onPressed : null,
          child: Ink(
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.center,
                widthFactor: isFullWidth ? null : 1.0,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );

    if (isFullWidth) {
      buttonWidget = SizedBox(width: double.infinity, child: buttonWidget);
    }

    return Semantics(
      label: semanticsLabel ?? text,
      button: true,
      enabled: isButtonEnabled,
      onTap: isButtonEnabled ? onPressed : null,
      child: buttonWidget,
    );
  }
}
