import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/video/services/video_compression_service.dart';

class VideoPickerService {
  final ImagePicker _picker = ImagePicker();
  final VideoCompressionService _compressionService = VideoCompressionService();

  /// Seleciona um vídeo da galeria
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Permite escolher da galeria para posterior corte
      );

      if (video == null) return null;

      return File(video.path);
    } catch (e) {
      debugPrint('Erro ao selecionar vídeo: $e');
      return null;
    }
  }

  /// Seleciona um vídeo da câmera
  Future<File?> pickVideoFromCamera({Duration? maxDuration}) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration ?? const Duration(seconds: 60),
      );

      if (video == null) return null;

      return File(video.path);
    } catch (e) {
      debugPrint('Erro ao gravar vídeo: $e');
      return null;
    }
  }

  /// Seleciona apenas o arquivo bruto de vídeo
  Future<File?> pickVideoOnly({
    required VideoType type,
    required ImageSource source,
  }) async {
    if (source == ImageSource.gallery) {
      return pickVideoFromGallery();
    } else {
      final maxDuration = type == VideoType.story
          ? const Duration(seconds: 30)
          : const Duration(seconds: 60);
      return pickVideoFromCamera(maxDuration: maxDuration);
    }
  }

  /// Valida duração e integridade do arquivo de vídeo
  Future<VideoValidationResult> validateVideoFile({
    required File videoFile,
    required VideoType type,
  }) async {
    return _compressionService.validateVideo(
      videoFile: videoFile,
      type: type,
    );
  }

  /// Comprime e corta fisicamente o arquivo de vídeo
  Future<VideoPickResult> compressAndProcessFile({
    required File videoFile,
    required VideoType type,
    int? maxDurationSeconds,
    Function(double)? onCompressionProgress,
  }) async {
    try {
      final thumbnail = await _compressionService.generateThumbnail(videoFile);

      final compressedVideo = await _compressionService.compressVideo(
        videoFile: videoFile,
        type: type,
        maxDurationSeconds: maxDurationSeconds,
        onProgress: onCompressionProgress,
      );

      final finalVideo = compressedVideo ?? videoFile;

      return VideoPickResult(
        success: true,
        videoFile: finalVideo,
        thumbnailFile: thumbnail,
        durationSeconds: maxDurationSeconds,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Erro no processamento/compressão do vídeo: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      return VideoPickResult(
        success: false,
        errorMessage: 'Erro ao comprimir vídeo: $e',
      );
    }
  }

  /// Fluxo completo: seleciona, valida e comprime o vídeo
  Future<VideoPickResult?> pickAndProcessVideo({
    required BuildContext context,
    required VideoType type,
    required ImageSource source,
    int? maxDurationSeconds,
    Function(double)? onCompressionProgress,
  }) async {
    try {
      debugPrint('🎥 Iniciando seleção de vídeo...');

      // 1. Selecionar vídeo bruto
      final videoFile = await pickVideoOnly(type: type, source: source);
      if (videoFile == null) {
        debugPrint('⚠️ Nenhum vídeo selecionado');
        return null;
      }

      debugPrint('✅ Vídeo selecionado: ${videoFile.path}');

      // 2. Validar vídeo
      final validation = await validateVideoFile(
        videoFile: videoFile,
        type: type,
      );

      if (!validation.isValid) {
        debugPrint('❌ Validação falhou: ${validation.errorMessage}');
        return VideoPickResult(
          success: false,
          errorMessage: validation.errorMessage,
        );
      }

      final int finalTargetDuration = maxDurationSeconds ?? validation.durationSeconds ?? (type == VideoType.story ? 30 : 60);

      // 3. Comprimir e cortar vídeo
      final result = await compressAndProcessFile(
        videoFile: videoFile,
        type: type,
        maxDurationSeconds: finalTargetDuration,
        onCompressionProgress: onCompressionProgress,
      );

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ ERRO no processamento: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      return VideoPickResult(
        success: false,
        errorMessage: 'Erro ao processar vídeo: ${e.toString()}',
      );
    }
  }
}

class VideoPickResult {
  final bool success;
  final File? videoFile;
  final File? thumbnailFile;
  final int? durationSeconds;
  final String? errorMessage;

  VideoPickResult({
    required this.success,
    this.videoFile,
    this.thumbnailFile,
    this.durationSeconds,
    this.errorMessage,
  });
}
