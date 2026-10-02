import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/features/home/timeline/services/story_service.dart';
import 'package:patas_web_app/src/features/home/timeline/timeline_provider.dart';
import 'package:patas_web_app/src/features/video/services/video_picker_service.dart';
import 'package:patas_web_app/src/features/video/services/video_compression_service.dart';

enum StoryPublishState { idle, optimizing, uploading, success, error }

/// Gerenciador de publicação de stories em segundo plano.
/// Permite que o usuário continue navegando no app enquanto o vídeo
/// é comprimido, cortado e enviado sem bloquear a interface.
class StoryPublishProvider extends ChangeNotifier {
  StoryPublishState _state = StoryPublishState.idle;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;
  Timer? _autoDismissTimer;

  StoryPublishState get state => _state;
  bool get isPublishing =>
      _state == StoryPublishState.optimizing ||
      _state == StoryPublishState.uploading;
  bool get isSuccess => _state == StoryPublishState.success;
  bool get isError => _state == StoryPublishState.error;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;

  final VideoPickerService _videoPickerService = VideoPickerService();
  final StoryService _storyService = StoryService();

  void dismiss() {
    _autoDismissTimer?.cancel();
    _state = StoryPublishState.idle;
    _progress = 0.0;
    _statusMessage = '';
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> publishStory({
    required bool isVideo,
    File? videoFile,
    XFile? pickedVideoXFile,
    File? imageFile,
    File? thumbnailFile,
    required int durationSeconds,
    String? petId,
    TimelineProvider? timelineProvider,
  }) async {
    _autoDismissTimer?.cancel();
    _errorMessage = null;

    if (isVideo) {
      _state = StoryPublishState.optimizing;
      _progress = 0.05;
      _statusMessage = 'Otimizando vídeo para o Story...';
      notifyListeners();

      try {
        final rawFile = videoFile ??
            (pickedVideoXFile != null ? File(pickedVideoXFile.path) : null);
        if (rawFile == null) {
          throw Exception('Arquivo de vídeo não encontrado para processamento.');
        }

        final targetDuration = durationSeconds > 0 ? durationSeconds.clamp(1, 30) : 30;

        // 1. Otimização e corte físico em background
        final result = await _videoPickerService.compressAndProcessFile(
          videoFile: rawFile,
          type: VideoType.story,
          maxDurationSeconds: targetDuration,
          onCompressionProgress: (p) {
            _progress = 0.05 + (p * 0.65); // 5% a 70%
            notifyListeners();
          },
        );

        if (!result.success || result.videoFile == null) {
          throw Exception(
            result.errorMessage ??
                'Ocorreu um erro no sistema de otimização do vídeo.',
          );
        }

        final processedVideoFile = result.videoFile!;
        final effectiveThumb = result.thumbnailFile ?? thumbnailFile;

        // 2. Upload do vídeo e thumbnail
        _state = StoryPublishState.uploading;
        _statusMessage = 'Enviando Story...';
        _progress = 0.70;
        notifyListeners();

        await _storyService.createStoryWithVideo(
          videoFile: processedVideoFile,
          thumbnailFile: effectiveThumb,
          durationSeconds: targetDuration,
          petId: petId,
          onUploadProgress: (upProgress) {
            _progress = 0.70 + (upProgress * 0.28); // 70% a 98%
            notifyListeners();
          },
        );

        // 3. Sucesso
        _state = StoryPublishState.success;
        _progress = 1.0;
        _statusMessage = 'Story publicado com sucesso!';
        notifyListeners();

        // Atualiza a timeline silenciosamente para o novo story aparecer
        timelineProvider?.loadTimeline(silent: true);

        // Auto-dismiss após 3.5 segundos
        _autoDismissTimer = Timer(const Duration(milliseconds: 3500), () {
          dismiss();
        });
      } catch (e) {
        debugPrint('❌ [StoryPublishProvider] Erro ao processar/publicar story: $e');
        _state = StoryPublishState.error;
        _progress = 0.0;
        _errorMessage =
            'Não foi possível publicar seu story. Ocorreu um erro no processamento do vídeo.';
        notifyListeners();

        _autoDismissTimer = Timer(const Duration(seconds: 7), () {
          dismiss();
        });
      }
    } else {
      // Story com Imagem
      _state = StoryPublishState.uploading;
      _progress = 0.25;
      _statusMessage = 'Publicando seu Story...';
      notifyListeners();

      try {
        if (imageFile == null) {
          throw Exception('Arquivo de imagem não encontrado.');
        }

        await _storyService.createStory(
          imageFile: imageFile,
          petId: petId,
        );

        _state = StoryPublishState.success;
        _progress = 1.0;
        _statusMessage = 'Story publicado com sucesso!';
        notifyListeners();

        timelineProvider?.loadTimeline(silent: true);

        _autoDismissTimer = Timer(const Duration(milliseconds: 3500), () {
          dismiss();
        });
      } catch (e) {
        debugPrint('❌ [StoryPublishProvider] Erro ao publicar story com imagem: $e');
        _state = StoryPublishState.error;
        _errorMessage = 'Não foi possível publicar seu story: $e';
        notifyListeners();

        _autoDismissTimer = Timer(const Duration(seconds: 6), () {
          dismiss();
        });
      }
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }
}
