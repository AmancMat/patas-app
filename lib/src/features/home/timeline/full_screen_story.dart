import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:patas_web_app/src/features/home/timeline/models/story_model.dart';
import 'package:patas_web_app/src/providers/profile_view_provider.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../profile/profile_page.dart';
import 'package:patas_web_app/src/features/ongs_corp/org_profile_page.dart';
import 'package:patas_web_app/src/features/video/widgets/story_video_player.dart';
import 'package:patas_web_app/src/utils/publish_tools_dialog.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:patas_web_app/src/features/home/timeline/services/like_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/comment_service.dart';
import 'package:patas_web_app/src/features/home/timeline/widgets/comments_sheet.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';

class FullScreenStory extends StatefulWidget {
  final List<Story> stories;

  const FullScreenStory({super.key, required this.stories});

  @override
  State<FullScreenStory> createState() => _FullScreenStoryState();
}

class _FullScreenStoryState extends State<FullScreenStory>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _timer;
  late AnimationController _progressController;
  final TransformationController _transformationController =
      TransformationController();

  // Estado para likes e comments
  final Map<String, bool> _isLikedMap = {};
  final Map<String, int> _likeCountMap = {};
  final Map<String, int> _commentCountMap = {};
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();

  final bool _isStoryMuted = false;
  double _dragOffsetY = 0.0;
  bool _isDismissing = false;
  late AnimationController _snapAnimationController;
  Animation<double>? _snapAnimation;

  // Duração padrão para fotos (6 segundos)
  static const Duration defaultPhotoDuration = Duration(seconds: 6);
  // Duração máxima para stories de vídeo (30 segundos)
  static const Duration maxVideoDuration = Duration(seconds: 30);
  bool _isAdvancingStory = false;
  bool _isHolding = false;

  void _onHoldStart() {
    if (!_isHolding) {
      setState(() => _isHolding = true);
      _progressController.stop();
    }
  }

  void _onHoldEnd() {
    if (_isHolding) {
      setState(() => _isHolding = false);
      _progressController.forward();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: defaultPhotoDuration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _snapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _snapAnimationController.addListener(() {
      if (_snapAnimation != null) {
        setState(() {
          _dragOffsetY = _snapAnimation!.value;
        });
      }
    });

    _startTimer();

    // Carregar dados de likes e comments para todos os stories
    _loadInteractionData();
  }

  Future<void> _loadInteractionData() async {
    // Carregar todos em paralelo para ser mais rápido
    await Future.wait(widget.stories.map((s) => _loadStats(s.id)));
  }

  Future<void> _loadStats(String storyId) async {
    if (storyId.startsWith('fake')) return;
    final likes = await _likeService.getLikeCount(storyId, isStory: true);
    final comments = await _commentService.getCommentCount(storyId, isStory: true);
    
    if (mounted) {
      setState(() {
        _likeCountMap[storyId] = likes;
        _commentCountMap[storyId] = comments;
      });
    }

    final liked = await _likeService.isLiked(storyId, isStory: true);
    if (mounted) {
      setState(() {
        _isLikedMap[storyId] = liked;
      });
    }
  }

  void _startTimer() {
    _progressController.stop();
    if (_currentIndex < 0 || _currentIndex >= widget.stories.length) return;
    final currentStory = widget.stories[_currentIndex];

    Duration duration;
    if (currentStory.isVideo) {
      final seconds = currentStory.videoDurationSeconds;
      if (seconds != null && seconds > 0) {
        duration = Duration(seconds: seconds.clamp(1, 30));
      } else {
        duration = maxVideoDuration;
      }
    } else {
      duration = defaultPhotoDuration;
    }

    _progressController.duration = duration;
    _progressController.reset();
    _progressController.forward();
  }

  void _nextStory() {
    if (_isAdvancingStory) return;
    _isAdvancingStory = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      _isAdvancingStory = false;
    });

    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startTimer();
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startTimer();
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isDismissing) return;
    if (_snapAnimationController.isAnimating) {
      _snapAnimationController.stop();
    }
    _progressController.stop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _dragOffsetY += details.primaryDelta ?? 0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final velocity = details.primaryVelocity ?? 0;
    final absOffset = _dragOffsetY.abs();

    // Se o usuário arrastou com velocidade (> 300 px/s) ou mais de 90 pixels de distância
    if (velocity.abs() > 300 || absOffset > 90) {
      _dismissStory(velocity);
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    _snapAnimation = Tween<double>(
      begin: _dragOffsetY,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _snapAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _snapAnimationController.duration = const Duration(milliseconds: 220);
    _snapAnimationController.forward(from: 0.0).then((_) {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  void _dismissStory(double velocity) {
    setState(() => _isDismissing = true);
    final double screenH = MediaQuery.of(context).size.height;
    final double targetOffset = (_dragOffsetY >= 0 || velocity > 0)
        ? screenH * 0.9
        : -screenH * 0.9;

    _snapAnimation = Tween<double>(
      begin: _dragOffsetY,
      end: targetOffset,
    ).animate(
      CurvedAnimation(
        parent: _snapAnimationController,
        curve: Curves.easeInCubic,
      ),
    );
    _snapAnimationController.duration = const Duration(milliseconds: 180);
    _snapAnimationController.forward(from: 0.0).then((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _snapAnimationController.dispose();
    _transformationController.dispose();
    _pageController.dispose();
    _progressController.dispose();
    _timer?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final Story story = widget.stories[_currentIndex];
    String displayName = '';
    String displayPhoto = '';

    if (story.profileType == 'ong' && story.ong != null) {
      displayName = story.ong!.name;
      displayPhoto = story.ong!.photoUrl ?? '';
    } else if (story.profileType == 'company' && story.corp != null) {
      displayName = story.corp!.name;
      displayPhoto = story.corp!.photoUrl ?? '';
    } else {
      displayName = story.pet?.name ?? story.userName ?? 'Usuário Patas';
      displayPhoto = story.pet?.photoUrl ?? story.userPhoto ?? '';
    }

    final double absOffset = _dragOffsetY.abs();
    final double dragProgress = (absOffset / 300.0).clamp(0.0, 1.0);
    final double currentScale = (1.0 - dragProgress * 0.28).clamp(0.70, 1.0);
    final double currentBorderRadius = dragProgress * 32.0;
    final double bgOpacity = (1.0 - dragProgress * 0.85).clamp(0.0, 1.0);

    Widget storyCard = Transform.translate(
      offset: Offset(0, _dragOffsetY),
      child: Transform.scale(
        scale: currentScale,
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            context.isWide ? 24 : currentBorderRadius,
          ),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: absOffset > 10
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 25,
                        spreadRadius: 4,
                      )
                    ]
                  : null,
            ),
            child: _buildStoryStack(story, displayName, displayPhoto),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      body: context.isWide
          // ── Desktop: story centralizado com proporção 9:16 ──
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: storyCard,
                ),
              ),
            )
          // ── Mobile: tela cheia com arraste interativo ──
          : storyCard,
    );
  }

  Widget _buildStoryStack(
      Story story, String displayName, String displayPhoto) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.stories.length,
          onPageChanged: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
              _startTimer();
            }
          },
              itemBuilder: (context, index) {
                final currentStory = widget.stories[index];

                return SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: currentStory.isVideo && currentStory.videoUrl != null
                      ? // Exibir vídeo
                      StoryVideoPlayer(
                          videoUrl: currentStory.videoUrl!,
                          thumbnailUrl: currentStory.videoThumbnailUrl,
                          isActive: index == _currentIndex,
                          isHolding: _isHolding,
                          isMuted: _isStoryMuted,
                          onVideoEnded: () {
                            if (index == _currentIndex) {
                              _nextStory();
                            }
                          },
                          onDurationLoaded: (dur) {
                            if (index == _currentIndex && dur.inSeconds > 0) {
                              final effectiveSeconds = dur.inSeconds.clamp(1, 30);
                              if (_progressController.duration?.inSeconds != effectiveSeconds) {
                                final currentVal = _progressController.value;
                                _progressController.duration = Duration(seconds: effectiveSeconds);
                                _progressController.forward(from: currentVal);
                              }
                            }
                          },
                        )
                      : // Exibir imagem
                      InteractiveViewer(
                          transformationController: _transformationController,
                          clipBehavior: Clip.none,
                          minScale: 1.0,
                          maxScale: 5.0,
                          onInteractionStart: (_) {
                            // Pausa o progress bar quando começa a interagir
                            _progressController.stop();
                          },
                          onInteractionEnd: (_) {
                            // Retoma o progress bar quando termina
                            _progressController.forward();
                          },
                          child: CachedNetworkImage(
                            imageUrl: currentStory.mediaUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) {
                              final thmode = Provider.of<DarkMode>(context);
                              return Skeletonizer(
                                enabled: true,
                                effect: ShimmerEffect(
                                  baseColor: thmode.darkMode
                                      ? Colors.grey[850]!
                                      : Colors.grey[300]!,
                                  highlightColor: thmode.darkMode
                                      ? Colors.grey[800]!
                                      : Colors.grey[100]!,
                                ),
                                child: Container(
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                            ),
                          ),
                        ),
                );
              },
            ),

            // Áreas de toque laterais e gesto vertical (arrastar para cima ou para baixo para fechar o story / long press para pausar e ocultar UI)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                onLongPressStart: (_) => _onHoldStart(),
                onLongPressEnd: (_) => _onHoldEnd(),
                onLongPressCancel: () => _onHoldEnd(),
                child: Row(
                  children: [
                    // Lado Esquerdo (35% da tela): volta para o story anterior
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_isHolding) return;
                          if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
                            _previousStory();
                          }
                        },
                      ),
                    ),
                    // Espaço Central (30% da tela): neutro (permite pausar ou interagir sem pular acidentalmente)
                    Expanded(
                      flex: 30,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_isHolding) return;
                          // Toque central pode avançar normalmente
                          if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
                            _nextStory();
                          }
                        },
                      ),
                    ),
                    // Lado Direito (35% da tela): avança para o próximo story
                    Expanded(
                      flex: 35,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_isHolding) return;
                          if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
                            _nextStory();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Artefatos de interface (ocultados suavemente durante Long Press / Hold)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isHolding,
                child: AnimatedOpacity(
                  opacity: _isHolding ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Stack(
                    children: [

            // Barras de Progresso
            Positioned(
              top: context.isWide ? 20 : 50.h,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index < _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: index == _currentIndex
                          ? AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressController.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),

            // Cabeçalho (Seta de voltar na extrema esquerda + Avatar + Nome)
            Positioned(
              top: context.isWide ? 32 : 56.h,
              left: context.isWide ? 16 : 8.w, // Bem na extrema esquerda
              right: context.isWide ? 80 : 54.w, // Espaço para botão de opções
              child: Row(
                children: [
                  // Botão de voltar na extrema esquerda
                  IconButton(
                    tooltip: 'Voltar',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: context.isWide ? 32 : 36.r,
                      minHeight: context.isWide ? 32 : 36.r,
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: context.isWide ? 18 : 22.r,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: context.isWide ? 6 : 6.w),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (context.isWide) {
                          // No Desktop, fechamos o overlay e navegamos internamente
                          Navigator.pop(context);

                          final pvp = Provider.of<ProfileViewProvider>(context,
                              listen: false);
                          if (story.profileType == 'ong' && story.ong != null) {
                            pvp.setViewProfile(ong: story.ong);
                          } else if (story.profileType == 'company' &&
                              story.corp != null) {
                            pvp.setViewProfile(corp: story.corp);
                          } else if (story.pet != null) {
                            pvp.setViewProfile(pet: story.pet);
                          }

                          // Ir para aba home (2) e aba interna perfil (0)
                          bottomNavIndexNotifier.value = 2;
                          homeTabIndexNotifier.value = 0;
                        } else {
                          // No Mobile, mantemos o comportamento de tela cheia
                          if (story.profileType == 'ong' && story.ong != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrgProfilePage(ong: story.ong),
                              ),
                            );
                          } else if (story.profileType == 'company' &&
                              story.corp != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrgProfilePage(corp: story.corp),
                              ),
                            );
                          } else if (story.pet != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfilePage(pet: story.pet),
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            height: context.isWide ? 38 : 42.r,
                            width: context.isWide ? 38 : 42.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.patasColor,
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: context.isWide ? 17 : 20.r,
                              backgroundImage: displayPhoto.isNotEmpty
                                  ? NetworkImage(displayPhoto)
                                  : const AssetImage(
                                          'assets/image_placeholder.png')
                                      as ImageProvider,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.isWide ? 16 : 17.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2.0,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Botão Fechar (X) apenas no Desktop
            if (context.isWide)
              Positioned(
                top: 32,
                right: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Fechar story',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

            // Botões de interação vertical (lado direito)
            Positioned(
              right: context.isWide ? 10 : 16.w,
              bottom: context.isWide ? 80 : 100.h,
              child: Column(
                children: [
                  _buildLikeButton(story),
                  SizedBox(height: context.isWide ? 16 : 24.h),
                  _buildCommentButton(story),
                  SizedBox(height: context.isWide ? 16 : 24.h),
                  _buildActionButton(
                    svgAssetPath: 'assets/icons/share.svg',
                    label: '',
                    onTap: () async {
                      _progressController.stop();
                      try {
                        await SharePlus.instance.share(ShareParams(
                          text: 'Confira este story no Patas!',
                          subject:
                              'Story de ${story.pet?.name ?? story.userName}',
                        ));
                      } finally {
                        if (mounted) {
                          _progressController.forward();
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            // Botão de opções (três pontos) no topo direito
            Positioned(
              top: context.isWide ? 32 : 56.h,
              right: context.isWide ? 80 : 8.w,
              child: IconButton(
                tooltip: 'Opções do story',
                icon: Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: context.isWide ? 24 : 28.r,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2.h),
                      blurRadius: 4.r,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                onPressed: () {
                  // Pausar o timer do story
                  _progressController.stop();

                  // Converter Story para Post para usar o mesmo dialog
                  final fakePost = Post(
                    id: story.id,
                    userId: story.userId,
                    userName: story.userName,
                    userPhoto: story.userPhoto,
                    imageUrl: story.mediaUrl,
                    content: '',
                    createdAt: story.createdAt,
                    petId: story.petId,
                    pet: story.pet,
                  );

                  if (context.isWide) {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Fechar',
                      barrierColor: Colors.black.withValues(alpha: 0.5),
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, anim1, anim2) {
                        return Center(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Material(
                              color: Colors.transparent,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 400),
                                child: PublishToolsDialog(
                                  post: fakePost,
                                  isStory: true,
                                  onActionComplete: () {
                                    Navigator.pop(
                                        context); // Fecha story se excluído
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ).then((_) {
                      if (mounted) _progressController.forward();
                    });
                  } else {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return PublishToolsDialog(
                          post: fakePost,
                          isStory: true,
                          onActionComplete: () {
                            Navigator.pop(context);
                          },
                        );
                      },
                    ).then((_) {
                      if (mounted) _progressController.forward();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  ),
],
);
  }

  // Widget de botão de curtir com funcionalidade completa
  Widget _buildLikeButton(Story story) {
    final isLiked = _isLikedMap[story.id] ?? false;
    final likeCount = _likeCountMap[story.id] ?? 0;

    return Semantics(
      button: true,
      label: isLiked ? 'Descurtir story' : 'Curtir story',
      child: GestureDetector(
        onTap: () async {
        if (story.id.startsWith('fake')) return;

        // Pausar timer durante interação
        _progressController.stop();

        // UI otimista
        setState(() {
          _isLikedMap[story.id] = !isLiked;
          _likeCountMap[story.id] = (likeCount + (isLiked ? -1 : 1));
        });

        try {
          final activePet =
              Provider.of<ActivePetProvider>(context, listen: false).activePet;
          final success = await _likeService.toggleLike(
            story.id,
            senderPetId: activePet?.id,
            isStory: true,
          );

          // Corrigir se necessário
          if (success != _isLikedMap[story.id]) {
            if (mounted) {
              setState(() {
                _isLikedMap[story.id] = success;
              });
            }
          }
        } catch (e) {
          // Reverter em caso de erro
          if (mounted) {
            setState(() {
              _isLikedMap[story.id] = isLiked;
              _likeCountMap[story.id] = likeCount;
            });
          }
        } finally {
          // Retomar timer
          if (mounted) {
            _progressController.forward();
          }
        }
      },
      child: Column(
        children: [
          Container(
            width: context.isWide ? 40 : 48.r,
            height: context.isWide ? 40 : 48.r,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isLiked
                    ? Icon(
                        Icons.favorite,
                        key: const ValueKey('liked'),
                        color: Colors.red,
                        size: context.isWide ? 24 : 28.r,
                      )
                    : SvgPicture.asset(
                        'assets/icons/heart.svg',
                        key: const ValueKey('unliked'),
                        height: context.isWide ? 22 : 28.r,
                        width: context.isWide ? 22 : 28.r,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            ),
          ),
          if (likeCount > 0) SizedBox(height: context.isWide ? 2 : 4.h),
          if (likeCount > 0)
            Text(
              '$likeCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.isWide ? 12 : 12.sp,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1.h),
                    blurRadius: 2.r,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
);
  }

  // Widget de botão de comentar com funcionalidade completa
  Widget _buildCommentButton(Story story) {
    final commentCount = _commentCountMap[story.id] ?? 0;

    return Semantics(
      button: true,
      label: 'Comentar no story',
      child: GestureDetector(
        onTap: () async {
        if (story.id.startsWith('fake')) return;

        // Pausar timer durante comentários
        _progressController.stop();

        // Converter Story para Post para usar o CommentsSheet existente
        final fakePost = Post(
          id: story.id,
          userId: story.userId,
          userName: story.userName,
          userPhoto: story.userPhoto,
          imageUrl: story.mediaUrl,
          content: '',
          createdAt: story.createdAt,
          petId: story.petId,
          pet: story.pet,
        );

        if (context.isWide) {
          await showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Fechar',
            barrierColor: Colors.black.withValues(alpha: 0.5),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, anim1, anim2) {
              return Center(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 500, maxHeight: 600),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CommentsSheet(
                      post: fakePost,
                      isStory: true,
                    ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CommentsSheet(
              post: fakePost,
              isStory: true,
            ),
          );
        }

        // Atualizar contagem após fechar
        if (!story.id.startsWith('fake')) {
          final newCount =
              await _commentService.getCommentCount(story.id, isStory: true);
          if (mounted) {
            setState(() {
              _commentCountMap[story.id] = newCount;
            });
          }
        }

        // Retomar timer
        if (mounted) {
          _progressController.forward();
        }
      },
      child: Column(
        children: [
          Container(
            width: context.isWide ? 40 : 48.r,
            height: context.isWide ? 40 : 48.r,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/comment.svg',
                height: context.isWide ? 22 : 28.r,
                width: context.isWide ? 22 : 28.r,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          if (commentCount > 0) SizedBox(height: context.isWide ? 2 : 4.h),
          if (commentCount > 0)
            Text(
              '$commentCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.isWide ? 12 : 12.sp,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1.h),
                    blurRadius: 2.r,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
);
  }

  // Widget helper para botões de ação
  Widget _buildActionButton({
    IconData? icon,
    String? svgAssetPath,
    IconData? fontAwesomeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label.isNotEmpty ? label : 'Compartilhar story',
      child: GestureDetector(
        onTap: onTap,
      child: Column(
        children: [
          Container(
            width: context.isWide ? 40 : 48.r,
            height: context.isWide ? 40 : 48.r,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: svgAssetPath != null
                  ? SvgPicture.asset(
                      svgAssetPath,
                      height: context.isWide ? 22 : 28.r,
                      width: context.isWide ? 22 : 28.r,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    )
                  : fontAwesomeIcon != null
                      ? FaIcon(
                          fontAwesomeIcon,
                          color: Colors.white,
                          size: context.isWide ? 20 : 26.r,
                        )
                      : Icon(
                          icon!,
                          color: Colors.white,
                          size: context.isWide ? 24 : 28.r,
                        ),
            ),
          ),
          if (label.isNotEmpty) SizedBox(height: 4.h),
          if (label.isNotEmpty)
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1.h),
                    blurRadius: 2.r,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
);
  }
}
