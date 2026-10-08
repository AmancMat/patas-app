import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:patas_web_app/src/features/health/dicas/texto_dicas_page.dart';
import 'package:patas_web_app/src/features/health/dicas/video_dicas_page.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/app.dart';
import '../../../constants/app_colors.dart';

enum DicasSubView { main, video, texto }

class _DicaVideoData {
  final String videoId;
  final String title;
  final String channel;
  final String duration;
  final String category;
  final Color categoryColor;

  const _DicaVideoData({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.duration,
    required this.category,
    required this.categoryColor,
  });
}

class _DicaTextoData {
  final String title;
  final String blogName;
  final String readingTime;
  final String category;
  final Color categoryColor;
  final String imageUrl;
  final String summary;
  final String url;

  const _DicaTextoData({
    required this.title,
    required this.blogName,
    required this.readingTime,
    required this.category,
    required this.categoryColor,
    required this.imageUrl,
    required this.summary,
    required this.url,
  });
}

class DicasPage extends StatefulWidget {
  final VoidCallback? onBack;
  const DicasPage({super.key, this.onBack});

  @override
  State<DicasPage> createState() => _DicasPageState();
}

class _DicasPageState extends State<DicasPage> {

  String _getCategoryLabel(String cat, BuildContext context) {
    switch (cat) {
      case 'Todos':
        return context.tr('health.cat_all');
      case 'Alimentação':
        return context.tr('health.cat_nutrition');
      case 'Comportamento':
        return context.tr('health.cat_behavior');
      case 'Saúde & Prevenção':
        return context.tr('health.cat_health_prevention');
      case 'Filhotes':
        return context.tr('health.cat_puppies');
      default:
        return cat;
    }
  }

  DicasSubView _currentView = DicasSubView.main;
  String _selectedCategory = 'Todos';

  static const List<String> _categories = [
    'Todos',
    'Alimentação',
    'Comportamento',
    'Saúde & Prevenção',
    'Filhotes',
  ];

  static const List<_DicaVideoData> _allVideos = [
    _DicaVideoData(
      videoId: 'uLUrzUUyPJM',
      title: 'Alimentos Proibidos para Cães e Gatos',
      channel: 'Perito Animal',
      duration: '9 min',
      category: 'Alimentação',
      categoryColor: Color(0xFFF57C00),
    ),
    _DicaVideoData(
      videoId: 'Bz9VB5d6QZA',
      title: 'Como Ensinar o Cão a Passear Sem Puxar',
      channel: 'Luís Zuccolo',
      duration: '11 min',
      category: 'Comportamento',
      categoryColor: Color(0xFF1976D2),
    ),
    _DicaVideoData(
      videoId: 'i8hBN8wApLY',
      title: '10 Sinais Silenciosos de Dor no seu Pet',
      channel: 'Perito Animal',
      duration: '8 min',
      category: 'Saúde & Prevenção',
      categoryColor: Color(0xFFD32F2F),
    ),
    _DicaVideoData(
      videoId: 'bd2o0Ue9vRI',
      title: 'Xixi e Cocô no Lugar Certo: Guia Fácil',
      channel: 'Luís Zuccolo',
      duration: '14 min',
      category: 'Filhotes',
      categoryColor: Color(0xFF7B1FA2),
    ),
    _DicaVideoData(
      videoId: '7I2wATeRVKM',
      title: 'Linguagem Corporal Felina: Entenda Seu Gato',
      channel: 'Perito Animal',
      duration: '10 min',
      category: 'Comportamento',
      categoryColor: Color(0xFF00897B),
    ),
    _DicaVideoData(
      videoId: 'xfkNMJJlJbI',
      title: 'Dicas de Ouro Para Higiene e Cuidados Diários',
      channel: 'Blog do Focinho',
      duration: '7 min',
      category: 'Saúde & Prevenção',
      categoryColor: Color(0xFF388E3C),
    ),
  ];

  static const List<_DicaTextoData> _allArticles = [
    _DicaTextoData(
      title: 'Alimentos Proibidos: O que seu cão não pode comer',
      blogName: 'Blog Cobasi',
      readingTime: '5 min',
      category: 'Alimentação',
      categoryColor: Color(0xFFF57C00),
      imageUrl:
          'https://cobasiblog.blob.core.windows.net/production-ofc/2019/12/o-que-cachorro-nao-pode-comer-capa.webp',
      summary:
          'Chocolate, cebola, uvas e xilitol: conheça os alimentos cotidianos altamente perigosos para cães.',
      url: 'https://blog.cobasi.com.br/o-que-cachorro-nao-pode-comer/',
    ),
    _DicaTextoData(
      title: 'Como Adestrar Cachorro em Casa: Dicas e Tutoriais',
      blogName: 'Blog Cobasi',
      readingTime: '6 min',
      category: 'Comportamento',
      categoryColor: Color(0xFF1976D2),
      imageUrl:
          'https://cobasiblog.blob.core.windows.net/production-ofc/2023/06/31A7860_1CG.webp',
      summary:
          'Aprenda os comandos básicos (senta, fica e junto) com reforço positivo, paciência e petiscos.',
      url: 'https://blog.cobasi.com.br/como-adestrar-um-cachorro/',
    ),
    _DicaTextoData(
      title: 'Vacina V10 Canina: Para que serve e quando aplicar',
      blogName: 'Blog Cobasi',
      readingTime: '4 min',
      category: 'Saúde & Prevenção',
      categoryColor: Color(0xFFD32F2F),
      imageUrl:
          'https://cobasiblog.blob.core.windows.net/production-ofc/2021/02/Vacina-v10-capa.png',
      summary:
          'Proteção essencial contra cinomose, parvovirose e leptospirose. Saiba o calendário de doses e reforços.',
      url: 'https://blog.cobasi.com.br/vacina-v10/',
    ),
    _DicaTextoData(
      title: 'Tártaro em Cachorro: Cuidados com a Saúde Bucal',
      blogName: 'Blog Cobasi',
      readingTime: '4 min',
      category: 'Saúde & Prevenção',
      categoryColor: Color(0xFF00897B),
      imageUrl:
          'https://cobasiblog.blob.core.windows.net/production-ofc/2020/01/tartaro-em-cachorro-capa.png',
      summary:
          'O acúmulo de cálculo dental pode comprometer órgãos vitais. Veja como prevenir com escovação correta.',
      url: 'https://blog.cobasi.com.br/tartaro-em-cachorro/',
    ),
    _DicaTextoData(
      title: 'Como Cuidar de um Filhote de Cachorro em Casa',
      blogName: 'Blog Cobasi',
      readingTime: '5 min',
      category: 'Filhotes',
      categoryColor: Color(0xFF7B1FA2),
      imageUrl:
          'https://blog.cobasi.com.br/wp-content/uploads/2020/11/filhote-capa.png',
      summary:
          'Guia para os primeiros meses: adaptação, tapete higiênico, rotina de alimentação e noites tranquilas.',
      url: 'https://blog.cobasi.com.br/filhote-de-cachorro/',
    ),
    _DicaTextoData(
      title: 'Como Acabar com Pulgas no Pet e no Ambiente',
      blogName: 'Blog Cobasi',
      readingTime: '5 min',
      category: 'Saúde & Prevenção',
      categoryColor: Color(0xFFE65100),
      imageUrl:
          'https://cobasiblog.blob.core.windows.net/production-ofc/2020/12/como-acabar-com-pulgas-capa-alt.webp',
      summary:
          '95% dos parasitas estão no ambiente da casa. Veja a estratégia correta de eliminação e prevenção contínua.',
      url: 'https://blog.cobasi.com.br/como-acabar-com-pulgas/',
    ),
    _DicaTextoData(
      title: 'Vacinas para Gatos: Guia Completo de Proteção',
      blogName: 'Blog Cobasi',
      readingTime: '4 min',
      category: 'Saúde & Prevenção',
      categoryColor: Color(0xFF43A047),
      imageUrl:
          'https://cobasiblog.blob.core.windows.net/production-ofc/2022/07/vacina-para-gatos-confira-o-calendario-completo-260x160.webp',
      summary:
          'Diferenças entre V3, V4 e V5 e por que felinos de apartamento também necessitam de imunização regular.',
      url: 'https://blog.cobasi.com.br/vacinas-para-gatos/',
    ),
  ];

  void _switchView(DicasSubView view) {
    setState(() {
      _currentView = view;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir o link: $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_currentView == DicasSubView.video) {
      content = VideoDicasPage(
        key: const ValueKey('video'),
        onBack: () => _switchView(DicasSubView.main),
      );
    } else if (_currentView == DicasSubView.texto) {
      content = TextoDicasPage(
        key: const ValueKey('texto'),
        onBack: () => _switchView(DicasSubView.main),
      );
    } else {
      content = RepaintBoundary(
        key: const ValueKey('main'),
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: content,
    );
  }

  List<_DicaVideoData> get _filteredVideos {
    if (_selectedCategory == 'Todos') return _allVideos;
    return _allVideos.where((v) => v.category == _selectedCategory).toList();
  }

  List<_DicaTextoData> get _filteredArticles {
    if (_selectedCategory == 'Todos') return _allArticles;
    return _allArticles.where((a) => a.category == _selectedCategory).toList();
  }

  Widget _buildMobileLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('health.tips_page_title'),
        subtitle: context.tr('health.tips_page_subtitle'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Categorias em chips horizontais ──
          _buildCategoryChips(isDark),
          const SizedBox(height: 18),

          // ── Seção de Vídeos em Carrossel Horizontal ──
          _buildSectionHeader(
            title: 'Vídeos Recomendados',
            icon: Icons.play_circle_fill_rounded,
            iconColor: Colors.redAccent,
            actionLabel: 'Ver todos (${_allVideos.length})',
            onAction: () => _switchView(DicasSubView.video),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildVideosCarousel(isDark, isDesktop: false),
          const SizedBox(height: 24),

          // ── Seção de Leituras em Carrossel Horizontal ──
          _buildSectionHeader(
            title: 'Leituras & Cuidados',
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.patasColor,
            actionLabel: 'Ver artigos (${_allArticles.length})',
            onAction: () => _switchView(DicasSubView.texto),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildArticlesCarousel(isDark, isDesktop: false),
          const SizedBox(height: 24),

          // ── Hubs de Acesso Direto ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHubShortcuts(isDark, isDesktop: false),
          ),
          const SizedBox(height: 24),

          // ── Padding Dinâmico Obrigatório ──
          const MobileScrollPadding(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final bgColor = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PatasEssencialAppBar(
        title: context.tr('health.tips_page_title'),
        subtitle: context.tr('health.tips_page_subtitle'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            children: [
              // ── Categorias ──
              _buildCategoryChips(isDark),
              const SizedBox(height: 24),

              // ── Seção de Vídeos ──
              _buildSectionHeader(
                title: 'Vídeos Recomendados',
                icon: Icons.play_circle_fill_rounded,
                iconColor: Colors.redAccent,
                actionLabel: 'Ver todos os canais e vídeos (${_allVideos.length})',
                onAction: () => _switchView(DicasSubView.video),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildVideosCarousel(isDark, isDesktop: true),
              const SizedBox(height: 32),

              // ── Seção de Artigos ──
              _buildSectionHeader(
                title: 'Leituras & Cuidados',
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.patasColor,
                actionLabel: 'Ver todos os artigos (${_allArticles.length})',
                onAction: () => _switchView(DicasSubView.texto),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildArticlesCarousel(isDark, isDesktop: true),
              const SizedBox(height: 32),

              // ── Hubs de Acesso Direto ──
              _buildHubShortcuts(isDark, isDesktop: true),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pílulas de Categorias ──────────────────────────────────────────────────
  Widget _buildCategoryChips(bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.patasColor
                    : (isDark ? const Color(0xFF26262B) : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.patasColor
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.patasColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                _getCategoryLabel(cat, context),
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Cabeçalho de Seção ───────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkBG,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.patasColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Carrossel de Vídeos ───────────────────────────────────────────────────
  Widget _buildVideosCarousel(bool isDark, {required bool isDesktop}) {
    final videos = _filteredVideos;
    if (videos.isEmpty) {
      return _buildEmptySection(
        'Nenhum vídeo encontrado para esta categoria.',
        isDark,
      );
    }

    final cardWidth = isDesktop ? 250.0 : 220.0;
    final cardHeight = isDesktop ? 210.0 : 195.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final video = videos[index];
          final thumbnailUrl =
              'https://img.youtube.com/vi/${video.videoId}/hqdefault.jpg';

          return SizedBox(
            width: cardWidth,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _launchUrl(
                  'https://www.youtube.com/watch?v=${video.videoId}'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Thumbnail com fallback
                      Positioned.fill(
                        child: Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black26,
                            child: const Icon(Icons.video_library_rounded,
                                color: Colors.white38, size: 40),
                          ),
                        ),
                      ),
                      // Degradê escuro para contraste
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.35, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Badge de Categoria (Superior Esquerdo)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: video.categoryColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            video.category,
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Badge de Duração (Superior Direito)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: Colors.white, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                video.duration,
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botão Play central
                      Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      // Título e Canal na base
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.redAccent, size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  video.channel,
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Carrossel de Artigos ──────────────────────────────────────────────────
  Widget _buildArticlesCarousel(bool isDark, {required bool isDesktop}) {
    final articles = _filteredArticles;
    if (articles.isEmpty) {
      return _buildEmptySection(
        'Nenhum artigo encontrado para esta categoria.',
        isDark,
      );
    }

    final cardWidth = isDesktop ? 270.0 : 235.0;
    final cardHeight = isDesktop ? 230.0 : 218.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final article = articles[index];

          return SizedBox(
            width: cardWidth,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _launchUrl(article.url),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem com tags
                      SizedBox(
                        height: 96,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              article.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: isDark ? Colors.white10 : Colors.black12,
                                child: const Icon(Icons.article_rounded,
                                    color: Colors.grey, size: 36),
                              ),
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                            // Tag de Categoria
                            Positioned(
                              top: 7,
                              left: 7,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: article.categoryColor.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  article.category,
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Tempo de Leitura
                            Positioned(
                              top: 7,
                              right: 7,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '⏱ ${article.readingTime}',
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Conteúdo Textual
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                      color: isDark ? Colors.white : AppColors.darkBG,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    article.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 10,
                                      height: 1.25,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    article.blogName,
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 9,
                                      color: isDark ? Colors.white38 : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text(
                                    'Ler artigo →',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.patasColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Atalhos dos Hubs Completos ───────────────────────────────────────────
  Widget _buildHubShortcuts(bool isDark, {required bool isDesktop}) {
    final card1 = _buildHubCard(
      title: context.tr('health.youtube_channels_hub'),
      subtitle: context.tr('health.youtube_channels_sub'),
      icon: Icons.ondemand_video_rounded,
      iconColor: Colors.redAccent,
      countLabel: '${_allVideos.length}+ vídeos',
      onTap: () => _switchView(DicasSubView.video),
      isDark: isDark,
    );

    final card2 = _buildHubCard(
      title: context.tr('health.articles_library_hub'),
      subtitle: context.tr('health.articles_library_sub'),
      icon: Icons.library_books_rounded,
      iconColor: AppColors.patasColor,
      countLabel: '${_allArticles.length}+ artigos',
      onTap: () => _switchView(DicasSubView.texto),
      isDark: isDark,
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: card1),
          const SizedBox(width: 20),
          Expanded(child: card2),
        ],
      );
    }

    return Column(
      children: [
        card1,
        const SizedBox(height: 10),
        card2,
      ],
    );
  }

  Widget _buildHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String countLabel,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 10.5,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                countLabel,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.patasColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ),
    );
  }
}
