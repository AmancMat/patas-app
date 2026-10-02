import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';

enum VideoType { story, post }

class VideoValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? durationSeconds;

  VideoValidationResult({
    required this.isValid,
    this.errorMessage,
    this.durationSeconds,
  });
}

class VideoCompressionService {
  Subscription? _subscription;

  /// Comprime e corta o vídeo nativamente no Android/iOS (com bypass seguro na Web)
  Future<File?> compressVideo({
    required File videoFile,
    required VideoType type,
    int? maxDurationSeconds,
    Function(double)? onProgress,
  }) async {
    if (kIsWeb) {
      debugPrint('⚠️ Web: Bypass na compressão local de vídeo.');
      if (onProgress != null) onProgress(1.0);
      return videoFile;
    }

    try {
      final int targetMaxDuration = maxDurationSeconds ?? (type == VideoType.story ? 30 : 60);
      final originalSizeMb = (await videoFile.length()) / (1024 * 1024);
      debugPrint('🗜️ Analisando vídeo para otimização (Target máx: ${targetMaxDuration}s)...');
      debugPrint('📊 Tamanho original: ${originalSizeMb.toStringAsFixed(2)} MB');

      // 1. Obter duração real do vídeo original antes de qualquer ação
      int realDurationSeconds = 0;
      try {
        final probeController = VideoPlayerController.file(videoFile);
        await probeController.initialize();
        realDurationSeconds = probeController.value.duration.inSeconds;
        await probeController.dispose();
      } catch (e) {
        debugPrint('⚠️ Não foi possível obter duração exata com probe: $e');
      }

      final bool needsTrimming = realDurationSeconds > targetMaxDuration && targetMaxDuration > 0;

      // 2. Atalho de segurança: se o vídeo já é leve (<= 8MB) e não precisa de corte, não re-encoda
      if (!needsTrimming && originalSizeMb <= 8.0) {
        debugPrint('⚡ Vídeo já é leve (${originalSizeMb.toStringAsFixed(2)} MB) e tem ${realDurationSeconds}s. Mantendo original sem perda de codec.');
        if (onProgress != null) onProgress(1.0);
        return videoFile;
      }

      _subscription?.unsubscribe();
      if (onProgress != null) {
        _subscription = VideoCompress.compressProgress$.subscribe((progress) {
          onProgress(progress / 100.0);
        });
      }

      // 3. Executa a compressão de acordo com a necessidade de corte
      // IMPORTANTE: Se o vídeo NÃO precisa de corte, NÃO passar startTime e duration
      // para evitar corrupção de timestamps (PTS/DTS) e atom MOOV no MediaMuxer do Android.
      final MediaInfo? mediaInfo;
      if (needsTrimming) {
        debugPrint('✂️ Cortando e comprimindo vídeo de ${realDurationSeconds}s para ${targetMaxDuration}s...');
        mediaInfo = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
          startTime: 0,
          duration: targetMaxDuration,
        );
      } else {
        debugPrint('🗜️ Apenas comprimindo vídeo de ${realDurationSeconds}s (sem corte de duração)...');
        mediaInfo = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
      }

      _subscription?.unsubscribe();
      _subscription = null;

      if (mediaInfo != null && mediaInfo.file != null) {
        final compressedFile = mediaInfo.file!;
        final compressedSizeMb = (await compressedFile.length()) / (1024 * 1024);

        // 4. Sanity Check: Testar se o arquivo gerado realmente decodifica no player
        bool isPlayable = false;
        try {
          final testController = VideoPlayerController.file(compressedFile);
          await testController.initialize();
          if (testController.value.isInitialized && testController.value.duration > Duration.zero) {
            isPlayable = true;
          }
          await testController.dispose();
        } catch (e) {
          debugPrint('⚠️ Arquivo comprimido gerou erro no decoder: $e');
          isPlayable = false;
        }

        if (isPlayable) {
          debugPrint('✅ Vídeo comprimido e validado com sucesso!');
          debugPrint('📊 Novo tamanho: ${compressedSizeMb.toStringAsFixed(2)} MB (redução de ${(100 - (compressedSizeMb / originalSizeMb * 100)).toStringAsFixed(1)}%)');
          return compressedFile;
        } else {
          debugPrint('⚠️ O arquivo comprimido não é reproduzível (corrupção de codec). Retornando o original com segurança.');
          return videoFile;
        }
      } else {
        debugPrint('⚠️ Falha na compressão nativa, retornando arquivo original');
        return videoFile;
      }
    } catch (e) {
      debugPrint('❌ Erro na compressão nativa: $e');
      _subscription?.unsubscribe();
      _subscription = null;
      return videoFile;
    }
  }

  /// Gera thumbnail do vídeo
  Future<File?> generateThumbnail(File videoFile) async {
    if (kIsWeb) return null;
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 75,
        position: -1,
      );
      return thumbnailFile;
    } catch (e) {
      debugPrint('⚠️ Erro ao gerar thumbnail com VideoCompress: $e');
      return null;
    }
  }

  Future<VideoValidationResult> validateVideo({
    required File videoFile,
    required VideoType type,
  }) async {
    VideoPlayerController? controller;
    try {
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoFile.path));
      } else {
        controller = VideoPlayerController.file(videoFile);
      }

      await controller.initialize();
      final duration = controller.value.duration;
      final seconds = duration.inSeconds;

      debugPrint('🎬 Vídeo validado com sucesso! Duração real: ${seconds}s');

      return VideoValidationResult(
        isValid: true,
        durationSeconds: seconds,
      );
    } catch (e) {
      debugPrint('⚠️ Erro ao ler metadados do vídeo: $e');
      return VideoValidationResult(
        isValid: true,
        durationSeconds: 0,
      );
    } finally {
      controller?.dispose();
    }
  }

  Future<void> clearCache() async {
    if (!kIsWeb) {
      try {
        await VideoCompress.deleteAllCache();
      } catch (e) {
        debugPrint('⚠️ Erro ao limpar cache do VideoCompress: $e');
      }
    }
  }

  Future<void> cancelCompression() async {
    if (!kIsWeb) {
      try {
        await VideoCompress.cancelCompression();
      } catch (e) {
        debugPrint('⚠️ Erro ao cancelar compressão: $e');
      }
    }
  }
}
