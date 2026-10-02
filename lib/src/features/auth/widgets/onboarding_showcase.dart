import 'dart:async';
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';

class OnboardingShowcase extends StatefulWidget {
  const OnboardingShowcase({super.key});

  @override
  State<OnboardingShowcase> createState() => _OnboardingShowcaseState();
}

class _OnboardingShowcaseState extends State<OnboardingShowcase> {
  int _currentSlideIndex = 0;
  Timer? _timer;

  final List<String> _phrases = [
    "Conecte-se com pessoas\napaixonadas por animais.",
    "Acompanhe e cuide da saúde\ndo seu pet em um só lugar.",
    "Descubra ONGs, adote, e ajude\na salvar vidas todos os dias.",
  ];

  final List<String> _images = [
    'assets/v.jpeg',
    'assets/vet_clinic.png',
    'assets/adoption.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAnimationCycle();
  }

  void _startAnimationCycle() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentSlideIndex = (_currentSlideIndex + 1) % _phrases.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─── Animação da Imagem: Entra pela direita, sai pela esquerda ──────────────
  Widget _imageTransitionBuilder(Widget child, Animation<double> animation) {
    final isEntering = child.key == ValueKey<int>(_currentSlideIndex);
    final offset = isEntering
        ? Tween<Offset>(
            begin: const Offset(0.15, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          )
        : Tween<Offset>(
            begin: const Offset(-0.15, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
          );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }

  // ─── Animação da Frase: Entra pela esquerda, sai pela direita ──────────────
  Widget _phraseTransitionBuilder(Widget child, Animation<double> animation) {
    final isEntering = child.key == ValueKey<int>(_currentSlideIndex);
    final offset = isEntering
        ? Tween<Offset>(
            begin: const Offset(-0.15, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          )
        : Tween<Offset>(
            begin: const Offset(0.15, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
          );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }

  // ─── Animação Mobile/Tablet: Entra de cima, sai para baixo ────────────────
  Widget _verticalTransitionBuilder(Widget child, Animation<double> animation) {
    final isEntering = child.key == ValueKey<int>(_currentSlideIndex);
    final offset = isEntering
        ? Tween<Offset>(
            begin: const Offset(0.0, -0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          )
        : Tween<Offset>(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
          );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }

  Widget _buildImage({double? width, double? height}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1000),
      transitionBuilder: _imageTransitionBuilder,
      child: Container(
        key: ValueKey<int>(_currentSlideIndex),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            _images[_currentSlideIndex],
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: width,
              height: height,
              color: AppColors.patasColor.withValues(alpha: 0.1),
              child: const Icon(
                Icons.pets,
                size: 60,
                color: AppColors.patasColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhrase({
    required bool isDark,
    required double fontSize,
    required bool isVertical,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1000),
      transitionBuilder: isVertical
          ? _verticalTransitionBuilder
          : _phraseTransitionBuilder,
      child: Text(
        key: ValueKey<int>(_currentSlideIndex),
        _phrases[_currentSlideIndex],
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1.35,
          color: isDark ? Colors.white : AppColors.darkBG,
          shadows: [
            if (!isDark)
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkMode>(context).darkMode;
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : (isTablet ? 32 : 40),
          ),
          child: isDesktop
              // ── Desktop: imagem + frase empilhados verticalmente no panel esquerdo
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildImage(width: 440, height: 300),
                    const SizedBox(height: 40),
                    _buildPhrase(
                      isDark: isDark,
                      fontSize: 23,
                      isVertical: false,
                    ),
                  ],
                )
              // ── Mobile / Tablet: imagem + frase em coluna, com animação vertical
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildImage(
                      width: double.infinity,
                      height: isMobile ? 200 : 280,
                    ),
                    SizedBox(height: isMobile ? 20 : 28),
                    _buildPhrase(
                      isDark: isDark,
                      fontSize: isMobile ? 18 : 22,
                      isVertical: true,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
