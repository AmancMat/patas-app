import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Player de vídeo exclusivo para Stories.
///
/// Responsabilidades:
/// - Reprodução imediata em tela cheia (100% da viewport) sem barras pretas artificiais.
/// - Ciclo único de duração real (sem looping forçado).
/// - Notificação de término para avanço automático do Story.
/// - Suporte a pausa instantânea via [isHolding] (Long Press do usuário).
/// - Zero controles visuais sobre a imagem (sem play button, seekbar ou replay).
class StoryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isActive;
  final bool isHolding;
  final bool isMuted;
  final void Function(Duration duration)? onDurationLoaded;
  final VoidCallback? onVideoEnded;

  const StoryVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isActive,
    this.isHolding = false,
    this.isMuted = false,
    this.onDurationLoaded,
    this.onVideoEnded,
  });

  @override
  State<StoryVideoPlayer> createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<StoryVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _hasEnded = false;

  @override
  void initState() {
    super.initState();
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
      _controller.setVolume(widget.isMuted ? 0.0 : 1.0);
      _controller.addListener(_videoListener);

      widget.onDurationLoaded?.call(_controller.value.duration);

      // Inicia imediatamente se o story estiver ativo e não estiver sendo segurado
      if (widget.isActive && !widget.isHolding) {
        await _controller.play();
      }
    } catch (e) {
      debugPrint('❌ [StoryVideoPlayer] Erro ao inicializar: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 150) &&
        position > const Duration(seconds: 1) &&
        !_hasEnded) {
      _hasEnded = true;
      widget.onVideoEnded?.call();
    }
  }

  @override
  void didUpdateWidget(covariant StoryVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isInitialized) return;

    // Atualização de volume
    if (oldWidget.isMuted != widget.isMuted) {
      _controller.setVolume(widget.isMuted ? 0.0 : 1.0);
    }

    // Gestão de Play / Pause baseada em isActive e isHolding
    final shouldPlay = widget.isActive && !widget.isHolding && !_hasEnded;

    if (shouldPlay) {
      if (!_controller.value.isPlaying) {
        _controller.play();
      }
    } else {
      if (_controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: Colors.white54,
            size: 48,
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
            ? Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            : const SizedBox.shrink(),
      );
    }

    // Leitura das dimensões físicas corrigidas por rotação
    final bool isRotated = _controller.value.rotationCorrection == 90 ||
        _controller.value.rotationCorrection == 270;
    final double rawWidth = _controller.value.size.width;
    final double rawHeight = _controller.value.size.height;
    final double visualWidth = isRotated ? rawHeight : rawWidth;
    final double visualHeight = isRotated ? rawWidth : rawHeight;
    final bool isLandscape = visualWidth > visualHeight;

    return SizedBox.expand(
      child: FittedBox(
        fit: isLandscape ? BoxFit.contain : BoxFit.cover,
        alignment: Alignment.center,
        child: isRotated
            ? SizedBox(
                width: visualWidth,
                height: visualHeight,
                child: OverflowBox(
                  minWidth: rawWidth,
                  maxWidth: rawWidth,
                  minHeight: rawHeight,
                  maxHeight: rawHeight,
                  child: VideoPlayer(_controller),
                ),
              )
            : SizedBox(
                width: visualWidth > 0 ? visualWidth : 16,
                height: visualHeight > 0 ? visualHeight : 9,
                child: VideoPlayer(_controller),
              ),
      ),
    );
  }
}
