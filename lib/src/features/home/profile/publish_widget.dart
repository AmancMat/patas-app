import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/features/home/timeline/services/like_service.dart';
import '../../../../app.dart';
import 'package:patas_web_app/src/features/home/timeline/services/comment_service.dart';
import 'package:patas_web_app/src/features/home/timeline/widgets/comments_sheet.dart';
import 'package:patas_web_app/src/features/home/timeline/services/share_service.dart';
import 'package:patas_web_app/src/features/home/profile/profile_page.dart';
import 'package:patas_web_app/src/features/ongs_corp/org_profile_page.dart';
import 'package:patas_web_app/src/providers/profile_view_provider.dart';
import '../../../constants/app_colors.dart';
import 'package:patas_web_app/src/providers/connectivity_provider.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import '../../../utils/publish_tools_dialog.dart';
import 'package:patas_web_app/src/utils/date_utils.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/features/video/widgets/feed_video_player.dart';
import 'package:patas_web_app/src/common_widgets/settings_lines_icon.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class PublishWidget extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onActionComplete;

  const PublishWidget({
    super.key,
    required this.posts,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final bool isDesktopPlatform = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    final bool zoomEnabled = !isDesktopPlatform && !context.isDesktop;

    // Se estiver sem posts e houver erro (conexão real offline vs instabilidade de servidor)
    if (!isLoading && posts.isEmpty && errorMessage != null) {
      final isDark = thmode.darkMode;
      final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
      final bool isRealOffline = connectivity.isOffline ||
          errorMessage!.contains('SocketException') ||
          errorMessage!.contains('ClientException') ||
          errorMessage!.contains('Network is unreachable') ||
          errorMessage!.contains('Failed host lookup');

      final IconData errorIcon = isRealOffline
          ? Icons.wifi_off_rounded
          : Icons.cloud_off_rounded;
      final String errorTitle = isRealOffline
          ? context.tr('feed.network_error')
          : context.tr('feed.server_instability');
      final String errorSubtitle = isRealOffline
          ? context.tr('feed.no_internet_desc')
          : context.tr('feed.server_instability_desc');

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.amber.withValues(alpha: 0.25) : Colors.amber.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? Colors.amber.withValues(alpha: 0.12) : Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  errorIcon,
                  size: 26,
                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                errorTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('feed.tap_to_retry'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Lista fake para o skeleton
    final displayPosts = isLoading
        ? List.generate(
            3,
            (index) => Post(
                  id: 'fake_$index',
                  userId: 'fake',
                  content:
                      'Esta é uma descrição de post de exemplo para o skeletonizer carregar corretamente e mostrar o shimmer.',
                  createdAt: DateTime.now(),
                  userName: 'Nome do Usuário',
                  imageUrl:
                      'https://placeholder.com/image.png', // URL fake para forçar o container da imagem
                ))
        : posts;

    return Skeletonizer(
      enabled: isLoading,
      effect: ShimmerEffect(
        baseColor: thmode.darkMode
            ? Colors.grey[800]!
            : AppColors.patasColor.withValues(alpha: 0.1),
        highlightColor: thmode.darkMode
            ? Colors.grey[700]!
            : AppColors.patasColor.withValues(alpha: 0.2),
      ),
      child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayPosts.length,
          itemBuilder: (BuildContext ctx, index) {
            final post = displayPosts[index];

            ImageProvider getProfileImage() {
              if (post.profileType == 'ong' && post.ong != null) {
                if (post.ong?.photoUrl != null &&
                    post.ong!.photoUrl!.isNotEmpty) {
                  return NetworkImage(post.ong!.photoUrl!);
                }
              } else if (post.profileType == 'company' && post.corp != null) {
                if (post.corp?.photoUrl != null &&
                    post.corp!.photoUrl!.isNotEmpty) {
                  return NetworkImage(post.corp!.photoUrl!);
                }
              } else if (post.pet != null &&
                  post.pet?.photoUrl != null &&
                  post.pet!.photoUrl!.isNotEmpty) {
                return NetworkImage(post.pet!.photoUrl!);
              }
              if (post.userPhoto != null && post.userPhoto!.isNotEmpty) {
                return NetworkImage(post.userPhoto!);
              }
              return const AssetImage('assets/atila_corraini.png');
            }

            String getDisplayName() {
              if (post.profileType == 'ong' && post.ong != null) {
                return post.ong!.name;
              } else if (post.profileType == 'company' && post.corp != null) {
                return post.corp!.name;
              } else if (post.pet != null) {
                return post.pet!.name;
              }
              return post.userName ?? 'Usuário';
            }

            return Container(
              margin: EdgeInsets.only(top: index == 0 ? 0 : 20),
              padding: const EdgeInsets.only(top: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: thmode.darkMode ? Colors.black54 : AppColors.bodyLight,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      // GestureDetector covering Avatar and Name/Date
                      Expanded(
                        flex: 9,
                        child: Semantics(
                          button: true,
                          label: context.tr('feed.open_profile_semantic', {'name': getDisplayName()}),
                          child: GestureDetector(
                            onTap: () {
                            if (context.isDesktop) {
                              final pvp = Provider.of<ProfileViewProvider>(context, listen: false);
                              
                              if (post.profileType == 'ong' && post.ong != null) {
                                pvp.setViewProfile(ong: post.ong);
                              } else if (post.profileType == 'company' && post.corp != null) {
                                pvp.setViewProfile(corp: post.corp);
                              } else {
                                pvp.setViewProfile(pet: post.pet);
                              }

                              // Navega para Home (2) -> Perfil (0)
                              bottomNavIndexNotifier.value = 2;
                              homeTabIndexNotifier.value = 0;
                            } else {
                              // Mobile: Mantém comportamento de tela cheia
                              if (post.profileType == 'ong' && post.ong != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrgProfilePage(ong: post.ong),
                                  ),
                                );
                              } else if (post.profileType == 'company' &&
                                  post.corp != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrgProfilePage(corp: post.corp),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(
                                      userId: post.userId,
                                      pet: post.pet,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Material(
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.hardEdge,
                                    child: SizedBox(
                                        height: 36,
                                        width: 36,
                                        child: Image(
                                          image: getProfileImage(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              Image.asset(
                                                  'assets/image_placeholder.png',
                                                  fit: BoxFit.cover),
                                        ))),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        getDisplayName(),
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: thmode.darkMode
                                                ? Colors.white
                                                : AppColors.darkBG,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Text(
                                        isLoading
                                            ? '00 de Jan às 00:00'
                                            : PatasDateUtils.formatFriendlyDate(
                                                post.createdAt),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
)
                      ),
                      IconButton(
                          tooltip: context.tr('feed.options_tooltip'),
                          icon: SettingsLinesIcon(
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.bodyAbsoluteBlack,
                            size: 22,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return PublishToolsDialog(
                                  post: post,
                                  onActionComplete: onActionComplete,
                                );
                              },
                            );
                          }),
                    ],
                  ),
                  if (post.isVideo && post.videoUrl != null)
                    // Exibir vídeo ocupando 100% da largura útil sem barras pretas
                    Container(
                      width: double.infinity,
                      color: thmode.darkMode ? Colors.black : const Color(0xFF111114),
                      child: !post.id.startsWith('fake')
                          ? FeedVideoPlayer(
                              videoUrl: post.videoUrl!,
                              thumbnailUrl: post.videoThumbnailUrl,
                            )
                          : AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                color: Colors.grey[850],
                              ),
                            ),
                    )
                  else if (post.imageUrl != null)
                    // Exibir imagem ocupando 100% da largura útil sem barras de preenchimento
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 560, // Limite estético vertical para fotos no feed
                        minWidth: double.infinity,
                      ),
                      child: Container(
                        width: double.infinity,
                        color: thmode.darkMode ? const Color(0xFF18181B) : Colors.grey.shade100,
                        child: post.imageUrl!.startsWith('http') &&
                                !post.id.startsWith('fake')
                            ? InteractiveViewer(
                                scaleEnabled: zoomEnabled,
                                panEnabled: zoomEnabled,
                                clipBehavior: Clip.none,
                                minScale: 1.0,
                                maxScale: 5.0,
                                child: CachedNetworkImage(
                                  imageUrl: post.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Skeletonizer(
                                    enabled: true,
                                    effect: ShimmerEffect(
                                      baseColor: thmode.darkMode
                                          ? Colors.grey[800]!
                                          : AppColors.patasColor
                                              .withValues(alpha: 0.1),
                                      highlightColor: thmode.darkMode
                                          ? Colors.grey[700]!
                                          : AppColors.patasColor
                                              .withValues(alpha: 0.2),
                                    ),
                                    child: Container(
                                      height: 280, // Altura padrão do shimmer
                                      width: double.infinity,
                                      color: thmode.darkMode
                                          ? Colors.grey[850]
                                          : Colors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, size: 40),
                                  ),
                                ),
                              )
                            : Container(
                                height: 200,
                              ),
                      ),
                    ),
                  Container(
                    color: thmode.darkMode ? Colors.black54 : AppColors.bodyLight,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    width: double.infinity,
                    child: ExpandablePostContent(
                      text: post.content,
                      isDark: thmode.darkMode,
                    ),
                  ),
                  Container(
                    color: Colors.white10,
                    height: 1,
                    width: double.infinity,
                  ),
                  Container(
                    color: thmode.darkMode ? Colors.black54 : AppColors.bodyLight,
                    height: 50,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        LikeButton(postId: post.id, thmode: thmode),
                        CommentButton(post: post, thmode: thmode),
                        _shareButton(post, context, thmode.darkMode),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  Widget _shareButton(Post post, BuildContext context, bool isDark) {
    return Semantics(
      button: true,
      label: context.tr('feed.share_semantic'),
      child: SizedBox(
        height: 50,
        width: 60,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ShareService().showShareModal(context, post, isDark: isDark);
          },
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/share.svg',
              height: 24,
              width: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.patasColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LikeButton extends StatefulWidget {
  final String postId;
  final DarkMode thmode;

  const LikeButton({super.key, required this.postId, required this.thmode});

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  final LikeService _likeService = LikeService();
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikeData();
  }

  Future<void> _loadLikeData() async {
    if (widget.postId.startsWith('fake')) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final isLiked = await _likeService.isLiked(widget.postId);
    final count = await _likeService.getLikeCount(widget.postId);

    if (mounted) {
      setState(() {
        _isLiked = isLiked;
        _likeCount = count;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    // UI otimista
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      final activePet =
          Provider.of<ActivePetProvider>(context, listen: false).activePet;
      final success = await _likeService.toggleLike(widget.postId,
          senderPetId: activePet?.id);
      // Se o resultado do servidor for diferente da nossa previsão otimista, corrigimos.
      // O toggleLike retorna o novo estado (true = like, false = deslike).
      // Mas minha implementacao do LikeService toggleLike retorna true se INSERIU (liked) e false se DELETOU (unliked).
      // Entao _isLiked deve ser igual a success.
      if (success != _isLiked) {
        if (mounted) {
          setState(() {
            _isLiked = success;
            // Ajuste contagem se necessário, mas geralmente o erro lança exceção
          });
        }
      }
    } catch (e) {
      // Reverte em caso de erro
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        width: 60,
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.patasColor),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      width: 80, // Largura suficiente
      child: Semantics(
        button: true,
        label: _isLiked
            ? context.tr('feed.unlike_semantic')
            : context.tr('feed.like_semantic'),
        child: InkWell(
          onTap: _toggleLike,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _isLiked
                  ? SvgPicture.asset(
                      'assets/icons/heart_filled.svg',
                      key: const ValueKey('liked'),
                      height: 26,
                      width: 26,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/icons/heart.svg',
                      key: const ValueKey('unliked'),
                      height: 26,
                      width: 26,
                    ),
            ),
            if (_likeCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '$_likeCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.thmode.darkMode
                        ? Colors.white
                        : AppColors.darkBG,
                  ),
                ),
              ),
          ],
        ),
      ),
)
    );
  }
}

class CommentButton extends StatefulWidget {
  final Post post;
  final DarkMode thmode;

  const CommentButton({super.key, required this.post, required this.thmode});

  @override
  State<CommentButton> createState() => _CommentButtonState();
}

class _CommentButtonState extends State<CommentButton> {
  final CommentService _commentService = CommentService();
  int _commentCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommentCount();
  }

  Future<void> _loadCommentCount() async {
    if (widget.post.id.startsWith('fake')) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final count = await _commentService.getCommentCount(widget.post.id);
    if (mounted) {
      setState(() {
        _commentCount = count;
        _isLoading = false;
      });
    }
  }

  Future<void> _openComments() async {
    if (widget.post.id.startsWith('fake')) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(post: widget.post),
    );

    // Refresh count after sheet closes
    _loadCommentCount();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        width: 60,
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.patasColor),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      width: 80, // Largura ajustada
      child: Semantics(
        button: true,
        label: context.tr('feed.comments_semantic'),
        child: InkWell(
          onTap: _openComments,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 26,
              width: 26,
              child: SvgPicture.asset(
                'assets/icons/comment.svg',
              ),
            ),
            if (_commentCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '$_commentCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.thmode.darkMode
                        ? Colors.white
                        : AppColors.darkBG,
                  ),
                ),
              ),
          ],
        ),
      ),
)
    );
  }
}

class ExpandablePostContent extends StatefulWidget {
  final String text;
  final bool isDark;

  const ExpandablePostContent({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  State<ExpandablePostContent> createState() => _ExpandablePostContentState();
}

class _ExpandablePostContentState extends State<ExpandablePostContent> {
  bool _isExpanded = false;
  static const int _charLimit = 60;

  @override
  Widget build(BuildContext context) {
    if (widget.text.length <= _charLimit) {
      return Text(
        widget.text,
        style: TextStyle(
          color: widget.isDark ? Colors.white : AppColors.darkBG,
          fontSize: 14,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: _isExpanded ? 'Recolher texto' : 'Expandir texto',
          child: GestureDetector(
            onTap: () {
            if (!_isExpanded) {
              setState(() => _isExpanded = true);
            }
          },
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _isExpanded
                      ? widget.text
                      : '${widget.text.substring(0, _charLimit)}...',
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : AppColors.darkBG,
                    fontSize: 14,
                    fontFamily: 'Roboto_flex',
                  ),
                ),
              ],
            ),
          ),
        ),
),
        Semantics(
          button: true,
          label: _isExpanded ? 'Mostrar menos' : 'Mostrar mais',
          child: GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              _isExpanded ? context.tr('feed.read_less') : context.tr('feed.read_more'),
              style: const TextStyle(
                color: AppColors.patasColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
)
      ],
    );
  }
}
