import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/home/profile/publish_widget.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:patas_web_app/src/features/home/timeline/models/story_model.dart';
import 'package:patas_web_app/src/features/home/timeline/services/post_service.dart';
import 'package:patas_web_app/src/features/home/timeline/services/story_service.dart';
import 'package:patas_web_app/src/features/home/timeline/story_widget.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DiscoveryFeedBackground extends StatefulWidget {
  const DiscoveryFeedBackground({super.key});

  @override
  State<DiscoveryFeedBackground> createState() =>
      _DiscoveryFeedBackgroundState();
}

class _DiscoveryFeedBackgroundState extends State<DiscoveryFeedBackground> {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();
  final ScrollController _scrollController = ScrollController();
  List<Post> _posts = [];
  List<Story> _stories = [];
  bool _isLoading = true;
  Timer? _resumeTimer;
  bool _isAutoScrolling = false;
  bool _isUserTouching = false;

  final List<Post> _dummyPosts = List.generate(
    3,
    (index) => Post(
      id: 'dummy-$index',
      userId: 'dummy',
      content: 'Carregando o texto da publicação aqui...',
      createdAt: DateTime.now(),
      userName: 'Carregando...',
    ),
  );

  final List<Story> _dummyStories = List.generate(
    5,
    (index) => Story(
      id: 'dummy-$index',
      userId: 'dummy',
      mediaUrl: '',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      userName: 'Tutor',
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadDiscoveryPosts();
  }

  Future<void> _loadDiscoveryPosts() async {
    try {
      final posts = await _postService.getDiscoveryPosts(limit: 20);
      final stories = await _storyService.getDiscoveryStories();

      debugPrint('DiscoveryFeedBackground: Posts loaded: ${posts.length}');
      debugPrint('DiscoveryFeedBackground: Stories loaded: ${stories.length}');

      if (mounted) {
        setState(() {
          _posts = posts;
          _stories = stories;
          _isLoading = false;
        });

        // Inicia o auto scroll após carregar os posts
        if (_posts.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar discovery posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startAutoScroll() {
    if (!mounted) return;
    _isAutoScrolling = true;
    _continueAutoScroll();
  }

  void _continueAutoScroll() {
    if (!_isAutoScrolling || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final remainingScroll = maxScroll - currentScroll;

    if (remainingScroll <= 1) {
      _scrollController.jumpTo(0);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _isAutoScrolling) {
          _continueAutoScroll();
        }
      });
      return;
    }

    // Desloca 30 pixels por segundo
    final durationMs = (remainingScroll / 30.0 * 1000).toInt();

    _scrollController
        .animateTo(
          maxScroll,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        )
        .then((_) {
          if (mounted && _isAutoScrolling && !_isUserTouching) {
            if (_scrollController.hasClients &&
                _scrollController.offset >=
                    _scrollController.position.maxScrollExtent - 1) {
              _continueAutoScroll();
            }
          }
        });
  }

  void _pauseAutoScroll() {
    _isAutoScrolling = false;
    _resumeTimer?.cancel();
  }

  void _resumeAutoScrollAfterDelay() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && !_isUserTouching) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pauseAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _showLoginCTA() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Crie sua conta gratuitamente no Patas para interagir com o conteúdo!',
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 16),
        ),
        backgroundColor: AppColors.patasColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayPosts = _isLoading ? _dummyPosts : _posts;
    final displayStories = _isLoading ? _dummyStories : _stories;

    if (!_isLoading && _posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Skeletonizer(
      enabled: _isLoading,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTap: _showLoginCTA,
            behavior: HitTestBehavior.opaque,
            child: Listener(
              onPointerDown: (_) {
                if (_isLoading) return;
                _isUserTouching = true;
                _pauseAutoScroll();
              },
              onPointerUp: (_) {
                if (_isLoading) return;
                _isUserTouching = false;
                _resumeAutoScrollAfterDelay();
              },
              onPointerCancel: (_) {
                if (_isLoading) return;
                _isUserTouching = false;
                _resumeAutoScrollAfterDelay();
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_isLoading) return false;
                  if (notification is UserScrollNotification) {
                    if (notification.direction != ScrollDirection.idle) {
                      _pauseAutoScroll();
                      if (!_isUserTouching) {
                        _resumeAutoScrollAfterDelay();
                      }
                    }
                  } else if (notification is ScrollEndNotification) {
                    if (!_isAutoScrolling && !_isUserTouching) {
                      _resumeAutoScrollAfterDelay();
                    }
                  }
                  return false;
                },
                child: ListView(
                  controller: _scrollController,
                  physics: _isLoading 
                      ? const NeverScrollableScrollPhysics() 
                      : const BouncingScrollPhysics(), // Desativa scroll durante o load
                  padding: EdgeInsets.only(
                    left: context.isDesktop
                        ? (constraints.maxWidth - Breakpoints.feedMaxWidth) / 2
                        : 16,
                    right: context.isDesktop
                        ? (constraints.maxWidth - Breakpoints.feedMaxWidth) / 2
                        : 16,
                    top: 100, // Espaço para a AppBar
                    bottom: 20,
                  ),
                  children: [
                    AbsorbPointer(
                      child: Container(
                        height: 160,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: StoryWidget(
                          stories: displayStories,
                          isLoading: false,
                          onStoryCreated: () {},
                        ),
                      ),
                    ),
                    AbsorbPointer(
                      child: PublishWidget(posts: displayPosts, isLoading: false),
                    ),
                    // Duplica a lista internamente para criar efeito infinito mais suave,
                    // já que o auto scroll joga de volta pro topo quando acaba.
                    AbsorbPointer(
                      child: PublishWidget(posts: displayPosts, isLoading: false),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
