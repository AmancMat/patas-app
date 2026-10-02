import 'dart:async';
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';

class InfoCarouselWidget extends StatefulWidget {
  const InfoCarouselWidget({super.key});

  @override
  State<InfoCarouselWidget> createState() => _InfoCarouselWidgetState();
}

class _InfoCarouselWidgetState extends State<InfoCarouselWidget> {
  late final PageController _pageController;
  late final Timer _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Dica Especial do Dia',
      'description':
          'Pets também precisam de hidratação redobrada no calor. Mantenha sempre água fresca disponível!',
      'icon': Icons.lightbulb_outline_rounded,
      'gradient': AppColors.patasGradient,
    },
    {
      'title': 'Saúde em Dia',
      'description':
          'Mantenha o histórico de vacinas atualizado. Um pet vacinado é um pet protegido e feliz!',
      'icon': Icons.health_and_safety_outlined,
      'gradient': [const Color(0xff438883), const Color(0xff63B5AF)],
    },
    {
      'title': 'Pet do Mês',
      'description':
          'Poste fotos incríveis do seu amiguinho e ele poderá aparecer em destaque aqui na nossa rede!',
      'icon': Icons.star_outline_rounded,
      'gradient': [const Color(0xff6a858d), const Color(0xff8ba6ad)],
    },
    {
      'title': 'Comunidade Patas',
      'description':
          'Mais de 100 fotos foram postadas hoje! Explore a linha do tempo e descubra novos amigos.',
      'icon': Icons.pets_rounded,
      'gradient': [const Color(0xffE54F2F), const Color(0xffF22772)],
    },
    {
      'title': 'Frase do Dia',
      'description':
          '"Um cão é a única coisa na terra que te ama mais do que ama a si mesmo." - Josh Billings',
      'icon': Icons.favorite_border_rounded,
      'gradient': [const Color(0xffFC6E28), const Color(0xffFC3028)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Altura sempre fixa para evitar distorção em telas com proporções diferentes
    const double carouselHeight = 140;

    return SizedBox(
      height: carouselHeight,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _SlideCard(
                slide: slide,
                currentPage: _currentPage,
                totalSlides: _slides.length,
                slideIndex: index,
              );
            },
          ),
        ),
      ),
    );
  }
}

// Widget de cada slide extraído para melhorar a legibilidade
class _SlideCard extends StatelessWidget {
  final Map<String, dynamic> slide;
  final int currentPage;
  final int totalSlides;
  final int slideIndex;

  const _SlideCard({
    required this.slide,
    required this.currentPage,
    required this.totalSlides,
    required this.slideIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide['gradient'] as List<Color>,
        ),
      ),
      child: Stack(
        children: [
          // Ícone decorativo ao fundo
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              slide['icon'] as IconData,
              size: 100,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          // Conteúdo de texto
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slide['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          slide['description'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 30,
                  child: SizedBox(),
                ),
              ],
            ),
          ),
          // Indicadores de página
          Positioned(
            bottom: 10,
            right: 14,
            child: Row(
              children: List.generate(
                totalSlides,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(
                      alpha: currentPage == i ? 1.0 : 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
