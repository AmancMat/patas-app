import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final bool initialMuted;
  final bool isStoryMode;
  final bool hideReplayButton;
  final bool manageVisibility;
  final void Function(Duration duration)? onDurationLoaded;
  final void Function(Duration position)? onPositionChanged;
  final VoidCallback? onVideoEnded;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.initialMuted = true,
    this.isStoryMode = false,
    this.hideReplayButton = false,
    this.manageVisibility = true,
    this.onDurationLoaded,
    this.onPositionChanged,
    this.onVideoEnded,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = false;
  late bool _isMuted;
  bool _hasFinished = false; // Controle de ciclo único
  bool _isReplaying = false; // Trava de proteção durante seek/replay
  bool _userPaused = false; // Registra se o usuário pausou manualmente

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuted;
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlay != widget.autoPlay && _isInitialized) {
      if (widget.autoPlay) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);

        widget.onDurationLoaded?.call(_controller.value.duration);

        _controller.setLooping(widget.looping);

        // Listener para detectar fim do vídeo e progresso
        _controller.addListener(_videoListener);

        await _controller.setVolume(_isMuted ? 0 : 1.0);

        // Se autoPlay for true e NÃO gerenciar visibilidade (ex: story atual), toca imediatamente
        if (widget.autoPlay && !widget.manageVisibility) {
          await _controller.play();
        }

        // Auto-hide controls após 3 segundos caso controles estejam ativos
        if (widget.showControls && _showControls) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _controller.value.isPlaying) {
              setState(() => _showControls = false);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao inicializar vídeo: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted || !_isInitialized || widget.isStoryMode || !widget.manageVisibility) return;

    final visibleFraction = info.visibleFraction;

    // Quando >= 60% do vídeo está visível na viewport do usuário
    if (visibleFraction >= 0.6) {
      // Dá play apenas se não foi pausado manualmente pelo usuário e não chegou ao fim
      if (!_userPaused && !_hasFinished && !_controller.value.isPlaying) {
        _controller.play();
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      }
    } else if (visibleFraction < 0.35) {
      // Quando sai da tela (menos de 35% visível): pausa automaticamente
      if (_controller.value.isPlaying) {
        _controller.pause();
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      }
    }
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    widget.onPositionChanged?.call(position);

    // Evita falsos positivos durante replay assíncrono ou buffer inicial
    if (_isReplaying) return;

    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 150) &&
        position > const Duration(seconds: 1) &&
        !_hasFinished) {
      setState(() {
        _hasFinished = true;
        _showControls = false; // Mantém controles ocultos para exibir apenas o botão de replay
      });
      widget.onVideoEnded?.call();
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
        _userPaused = true; // Usuário pausou manualmente
        _showControls = true;
      } else {
        _controller.play();
        _userPaused = false; // Usuário deu play manualmente
        _showControls = false;
        // Auto-hide após 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _controller.value.isPlaying) {
            setState(() => _showControls = false);
          }
        });
      }
    });
  }

  void _toggleControls() {
    if (!widget.showControls) return;

    setState(() => _showControls = !_showControls);

    // Auto-hide após 3 segundos se estiver tocando
    if (_showControls && _controller.value.isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() => _showControls = false);
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

    final bool isRotated = _controller.value.rotationCorrection == 90 ||
        _controller.value.rotationCorrection == 270;
    final double videoWidth = isRotated
        ? _controller.value.size.height
        : _controller.value.size.width;
    final double videoHeight = isRotated
        ? _controller.value.size.width
        : _controller.value.size.height;
    final bool isLandscape = (_controller.value.aspectRatio > 1.0);

    // Proporção inteligente: clampa entre 4:5 (0.8 - vertical máximo para feeds) e 16:9 (horizontal widescreen)
    Widget videoContent = Stack(
      alignment: Alignment.center,
      children: [
        // Vídeo ocupando 100% da área útil
        Positioned.fill(
          child: ClipRect(
            child: SizedBox.expand(
              child: FittedBox(
                fit: widget.isStoryMode
                    ? (isLandscape ? BoxFit.contain : BoxFit.cover)
                    : BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: videoWidth > 0 ? videoWidth : 16,
                  height: videoHeight > 0 ? videoHeight : 9,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          ),
        ),

          // Overlay de controles
          if (widget.showControls && _showControls)
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
                    // Botão de play/pause central
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
                    // Barra de progresso e tempo
                    Padding(
                      padding: context.isWide
                          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                          : EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Column(
                        children: [
                          // Barra de progresso
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
                          // Tempo
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

          // Ícone de play quando pausado (sempre visível)
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
          if (_hasFinished && !widget.hideReplayButton && !widget.isStoryMode)
            _buildWatchAgainOverlay(),

          // Botão de Som fixo no canto inferior direito
          if (_isInitialized && !_hasFinished && widget.showControls)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMuted = !_isMuted;
                    _controller.setVolume(_isMuted ? 0 : 1);
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

    if (widget.isStoryMode) {
      return SizedBox.expand(child: videoContent);
    }

    final double effectiveRatio = (_controller.value.aspectRatio > 0)
        ? _controller.value.aspectRatio
        : (16 / 9);
    final double targetRatio = effectiveRatio.clamp(0.8, 16 / 9);

    Widget feedPlayer = AspectRatio(
      aspectRatio: targetRatio,
      child: GestureDetector(
        onTap: _toggleControls,
        child: videoContent,
      ),
    );

    if (widget.manageVisibility) {
      return VisibilityDetector(
        key: Key('feed_video_${widget.videoUrl}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: feedPlayer,
      );
    }

    return feedPlayer;
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Assistir novamente',
                    style: TextStyle(
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
