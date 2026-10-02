import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/models/comment_model.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/comment_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/like_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/share_service.dart';
import 'package:patas_web_app/src/features/video/widgets/feed_video_player.dart';
import 'package:patas_web_app/src/common_widgets/settings_lines_icon.dart';
import 'package:patas_web_app/src/utils/date_utils.dart';

class PublicPostPage extends StatefulWidget {
  final String postId;

  const PublicPostPage({
    super.key,
    required this.postId,
  });

  @override
  State<PublicPostPage> createState() => _PublicPostPageState();
}

class _PublicPostPageState extends State<PublicPostPage> {
  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();
  final LikeService _likeService = LikeService();

  Post? _post;
  List<Comment> _comments = [];
  int _likesCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final post = await _postService.getPostById(widget.postId);
      if (post != null) {
        final comments = await _commentService.getComments(widget.postId);
        final likes = await _likeService.getLikeCount(widget.postId);
        if (mounted) {
          setState(() {
            _post = post;
            _comments = comments;
            _likesCount = likes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Esta publicação não foi encontrada ou foi removida.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Não foi possível carregar a publicação. Verifique sua conexão.';
        });
      }
    }
  }

  void _copyPostLink() {
    final url = 'https://patas.online/#/post?id=${widget.postId}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Link da publicação copiado!',
              style: TextStyle(fontFamily: 'Fredoka', color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.patasColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar com Logo Patas e Ações de Conversão
            _buildTopBar(isDark, isMobile),

            // Conteúdo principal com scroll
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(isDark)
                  : _errorMessage != null || _post == null
                      ? _buildErrorState(isDark)
                      : _buildPostContent(isDark, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra superior elegante com a marca Patas e botões de chamada para ação
  Widget _buildTopBar(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF282830) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Marca Patas com logo e texto
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(NamedRoute.home);
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/patas.svg',
                  height: isMobile ? 26 : 32,
                ),
                const SizedBox(width: 8),
                Text(
                  'Patas',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 20 : 24,
                    color: AppColors.patasColor,
                  ),
                ),
              ],
            ),
          ),

          // Botões de Ação para Conversão / Download
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(NamedRoute.home);
                },
                icon: const Icon(Icons.pets_rounded, size: 18),
                label: Text(
                  isMobile ? 'Entrar' : 'Entrar no Patas',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 18,
                    vertical: isMobile ? 8 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/patas.svg',
            height: 48,
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            color: AppColors.patasColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando publicação...',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 44,
                color: AppColors.patasColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Publicação não encontrada',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Este post pode ter sido removido pelo autor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(NamedRoute.home);
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Ir para o Patas'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.patasColor,
                    side: const BorderSide(color: AppColors.patasColor),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(NamedRoute.home);
                  },
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Explorar o Patas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Conteúdo do post + comentários + banner de conversão
  Widget _buildPostContent(bool isDark, bool isMobile) {
    final post = _post!;
    final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E24);
    final subtextColor = isDark ? const Color(0xFFA0A0AB) : const Color(0xFF6B7280);

    final String authorName = post.pet?.name ?? post.userName ?? 'Amigo Pet';
    final String? avatarUrl = post.pet?.photoUrl ?? post.userPhoto;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card do Post
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho do Post (Autor, Pet, Tempo e Opções)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          // Avatar com borda temática
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.patasColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey.shade300,
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: AppColors.patasColor.withValues(alpha: 0.1),
                                        child: const Icon(Icons.pets, color: AppColors.patasColor),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.patasColor.withValues(alpha: 0.1),
                                      child: const Icon(Icons.pets, color: AppColors.patasColor),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Nome do autor / Pet e tempo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        authorName,
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (post.pet != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.patasColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          post.pet!.species.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.patasColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  PatasDateUtils.formatFriendlyDate(post.createdAt),
                                  style: TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 12,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Novo Ícone Autoral de Opções do Post
                          IconButton(
                            tooltip: 'Opções da publicação',
                            icon: SettingsLinesIcon(
                              color: textColor,
                              size: 20,
                            ),
                            onPressed: () {
                              _showPostOptionsSheet(post, isDark);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Mídia do Post (Vídeo ou Imagem)
                    if (post.isVideo && post.videoUrl != null)
                      Container(
                        color: Colors.black,
                        child: FeedVideoPlayer(
                          videoUrl: post.videoUrl!,
                          thumbnailUrl: post.videoThumbnailUrl,
                        ),
                      )
                    else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark ? const Color(0xFF2A2A30) : Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.patasColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark ? const Color(0xFF2A2A30) : Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        ),
                      ),

                    // Barra de Interações (Curtidas, Comentários, Compartilhar)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Botão de Curtir
                          InkWell(
                            onTap: () {
                              _showInteractInAppMessage('curtir');
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/heart.svg',
                                    height: 22,
                                    width: 22,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.patasColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_likesCount',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Botão de Comentários
                          InkWell(
                            onTap: () {
                              _showInteractInAppMessage('comentar');
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/comment.svg',
                                    height: 22,
                                    width: 22,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.patasColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_comments.length}',
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Botão de Compartilhar
                          IconButton(
                            tooltip: 'Compartilhar publicação',
                            icon: SvgPicture.asset(
                              'assets/icons/share.svg',
                              height: 22,
                              width: 22,
                              colorFilter: const ColorFilter.mode(
                                AppColors.patasColor,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () {
                              ShareService().sharePost(post);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Legenda / Conteúdo de Texto
                    if (post.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 15,
                              color: textColor,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: '$authorName ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: post.content),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Seção de Comentários do Post
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comentários (${_comments.length})',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _showInteractInAppMessage('comentar');
                          },
                          child: const Text(
                            '+ Escrever comentário',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              color: AppColors.patasColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    if (_comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 36,
                                color: subtextColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ainda não há comentários nesta publicação.',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 14,
                                  color: subtextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Abra o Patas para interagir e deixar seu recado!',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.patasColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final commentName = comment.senderName ?? 'Amigo Pet';
                          final commentAvatar = comment.senderPhoto;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.patasColor.withValues(alpha: 0.1),
                                backgroundImage: (commentAvatar != null && commentAvatar.isNotEmpty)
                                    ? CachedNetworkImageProvider(commentAvatar)
                                    : null,
                                child: (commentAvatar == null || commentAvatar.isEmpty)
                                    ? const Icon(Icons.pets, size: 16, color: AppColors.patasColor)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          commentName,
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          PatasDateUtils.formatFriendlyDate(comment.createdAt),
                                          style: TextStyle(
                                            fontFamily: 'Fredoka',
                                            fontSize: 11,
                                            color: subtextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.content,
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 13.5,
                                        color: textColor.withValues(alpha: 0.9),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Banner de Conversão & Download do App Patas
              _buildDownloadBanner(isDark),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner com gradiente e chamado para ação da Play Store
  Widget _buildDownloadBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.patasColor,
            AppColors.patasColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.patasColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SvgPicture.asset(
                  'assets/icons/patas.svg',
                  height: 36,
                  width: 36,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gostou desta publicação?',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Conecte-se à maior rede social e ecossistema de pets do Brasil!',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(NamedRoute.home);
                  },
                  icon: const Icon(Icons.pets_rounded, color: AppColors.patasColor),
                  label: const Text(
                    'Entrar no Patas',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.patasColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(NamedRoute.home);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Página Inicial',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInteractInAppMessage(String action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Provider.of<DarkMode>(context, listen: false).darkMode;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.pets_rounded, size: 48, color: AppColors.patasColor),
              const SizedBox(height: 12),
              Text(
                'Quer $action esta publicação?',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entre na sua conta ou cadastre-se gratuitamente no Patas para curtir, comentar e postar sobre seus pets!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed(NamedRoute.home);
                  },
                  icon: const Icon(Icons.pets_rounded),
                  label: const Text(
                    'Entrar ou Criar Conta',
                    style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Voltar à publicação',
                  style: TextStyle(fontFamily: 'Fredoka', color: AppColors.patasColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPostOptionsSheet(Post post, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: AppColors.patasColor),
                title: const Text('Copiar link da publicação', style: TextStyle(fontFamily: 'Fredoka')),
                onTap: () {
                  Navigator.pop(context);
                  _copyPostLink();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: AppColors.patasColor),
                title: const Text('Compartilhar publicação', style: TextStyle(fontFamily: 'Fredoka')),
                onTap: () {
                  Navigator.pop(context);
                  ShareService().sharePost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded, color: AppColors.patasColor),
                title: const Text('Ir para o Patas', style: TextStyle(fontFamily: 'Fredoka')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(NamedRoute.home);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
