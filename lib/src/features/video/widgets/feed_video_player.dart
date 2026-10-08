import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

/// Player de vídeo exclusivo para Publicações do Feed.
///
/// Responsabilidades:
/// - Proporção adaptativa inteligente corrigida por rotação (4:5 a 16:9).
/// - Preenchimento total com [BoxFit.cover] sem faixas pretas laterais.
/// - Execução baseada em visibilidade de rolagem (play quando >= 60%, pause quando < 35%).
/// - Pausa manual com precedência sobre o scroll (_userPaused).
/// - Botão de áudio sutil no canto inferior direito.
/// - Botão central de play quando pausado e botão "Assistir novamente" ao término.
class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool initialMuted;

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.initialMuted = true,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = false;
  late bool _isMuted;
  bool _hasFinished = false;
  bool _isReplaying = false;
  bool _userPaused = false;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuted;
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller.initialize();

      if (!mounted) {
        _controller.dispose();
        return;
      }

      setState(() {
        _isInitialized = true;
      });

      _controller.setLooping(false);
      await _controller.setVolume(_isMuted ? 0.0 : 1.0);
      _controller.addListener(_videoListener);
    } catch (e) {
      debugPrint('❌ [FeedVideoPlayer] Erro ao inicializar: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted || !_isInitialized) return;

    final visibleFraction = info.visibleFraction;

    // Quando >= 60% visível na tela: play automático se não pausado manualmente
    if (visibleFraction >= 0.6) {
      if (!_userPaused && !_hasFinished && !_controller.value.isPlaying) {
        _controller.play();
        if (mounted) {
          setState(() => _showControls = false);
        }
      }
    } else if (visibleFraction < 0.35) {
      // Quando sai da tela (< 35% visível): pausa automaticamente
      if (_controller.value.isPlaying) {
        _controller.pause();
        if (mounted) {
          setState(() => _showControls = false);
        }
      }
    }
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (_isReplaying) return;

    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 150) &&
        position > const Duration(seconds: 1) &&
        !_hasFinished) {
      setState(() {
        _hasFinished = true;
        _showControls = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_hasFinished) {
      _replayVideo();
      return;
    }

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _userPaused = true;
        _showControls = true;
      } else {
        _controller.play();
        _userPaused = false;
        _showControls = false;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _controller.value.isPlaying) {
            setState(() => _showControls = false);
          }
        });
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);

    if (_showControls && _controller.value.isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  Future<void> _replayVideo() async {
    _isReplaying = true;
    setState(() {
      _hasFinished = false;
      _userPaused = false;
      _showControls = false;
    });

    try {
      await _controller.seekTo(Duration.zero);
      await _controller.play();
    } finally {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _isReplaying = false;
        }
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    final double videoWidth = _controller.value.size.width;
    final double videoHeight = _controller.value.size.height;

    // Proporção real do vídeo baseada na orientação
    final double videoAspect = (videoWidth > 0 && videoHeight > 0)
        ? (videoWidth / videoHeight)
        : (_controller.value.aspectRatio > 0 ? _controller.value.aspectRatio : 1.0);

    // No feed, vídeos verticais usam 4:5 (0.8) até 16:9 para horizontais
    final double targetRatio = videoAspect.clamp(0.8, 16 / 9);

    debugPrint('🎥 [FeedVideoPlayer REAL] url: ${widget.videoUrl}');
    debugPrint('🎥 [FeedVideoPlayer REAL] size: ${videoWidth}x$videoHeight, aspect: $videoAspect, targetRatio: $targetRatio');

    Widget videoContent = Stack(
      alignment: Alignment.center,
      children: [
        // Vídeo ocupando 100% da área útil com BoxFit.cover
        Positioned.fill(
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: SizedBox(
                width: videoWidth > 0 ? videoWidth : 16,
                height: videoHeight > 0 ? videoHeight : 9,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),

        // Overlay de controles rápidos (play/pause e barra de tempo)
        if (_showControls)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          padding: EdgeInsets.all(context.isWide ? 12 : 16.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: context.isWide ? 32 : 48.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: context.isWide
                        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                        : EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Column(
                      children: [
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.white,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.isWide ? 11 : 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.isWide ? 11 : 12.sp,
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

        // Ícone de play quando pausado pelo usuário
        if (!_controller.value.isPlaying && !_showControls && !_hasFinished)
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: EdgeInsets.all(context.isWide ? 12 : 16.r),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: context.isWide ? 32 : 48.r,
                ),
              ),
            ),
          ),

        // Overlay "Assistir novamente"
        if (_hasFinished) _buildWatchAgainOverlay(),

        // Botão de Som fixo no canto inferior direito
        if (!_hasFinished)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isMuted = !_isMuted;
                  _controller.setVolume(_isMuted ? 0.0 : 1.0);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: context.isWide ? 18 : 20,
                ),
              ),
            ),
          ),
      ],
    );

    Widget feedPlayer = AspectRatio(
      aspectRatio: targetRatio,
      child: GestureDetector(
        onTap: _toggleControls,
        child: videoContent,
      ),
    );

    return VisibilityDetector(
      key: Key('feed_video_${widget.videoUrl}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: feedPlayer,
    );
  }

  Widget _buildWatchAgainOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: InkWell(
            onTap: _replayVideo,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.patasColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.replay_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('feed.watch_again'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: const Color(0xFF111114),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando vídeo...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.isWide ? 13 : 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: const Color(0xFF111114),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48.r,
              ),
              SizedBox(height: 16.h),
              Text(
                'Erro ao carregar vídeo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializeVideo();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
