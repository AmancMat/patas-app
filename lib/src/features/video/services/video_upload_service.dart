import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../main.dart';

class VideoUploadService {
  /// Upload de vídeo para o Supabase Storage
  /// Retorna a URL pública do vídeo
  Future<String> uploadVideo({
    required File videoFile,
    required String userId,
    required String type, // 'story' ou 'post'
    Function(double)? onProgress,
  }) async {
    try {

      final String extension = kIsWeb ? 'mp4' : videoFile.path.split('.').last;
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$userId.$extension';
      final String path = 'public/$type/$userId/$fileName';

      debugPrint('🎥 Iniciando upload de vídeo...');
      debugPrint('📍 Caminho: $path');
      
      if (!kIsWeb) {
        debugPrint(
            '📊 Tamanho: ${((await videoFile.length()) / (1024 * 1024)).toStringAsFixed(2)} MB');
      }

      // Upload do vídeo
      if (kIsWeb) {
        final bytes = await XFile(videoFile.path).readAsBytes();
        await supabase.storage.from('videos').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'video/mp4',
              ),
            );
      } else {
        await supabase.storage.from('videos').upload(
              path,
              videoFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'video/mp4',
              ),
            );
      }

      final String publicUrl =
          supabase.storage.from('videos').getPublicUrl(path);

      debugPrint('✅ Vídeo enviado com sucesso!');
      debugPrint('🔗 URL: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ ERRO ao fazer upload do vídeo: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Upload de thumbnail do vídeo
  /// Retorna a URL pública do thumbnail
  Future<String> uploadThumbnail({
    File? thumbnailFile,
    required String userId,
    required String type, // 'story' ou 'post'
  }) async {
    if (thumbnailFile == null) {
      debugPrint('ℹ️ Usando thumbnail padrão (null provided)');
      // Retornar uma URL de thumbnail padrão do sistema
      return 'https://fofwwmrsenavvpxvduvi.supabase.co/storage/v1/object/public/others/video_placeholder.jpg';
    }
    try {

      final String extension = (kIsWeb || thumbnailFile.path.split('.').length < 2) 
          ? 'jpg' 
          : thumbnailFile.path.split('.').last;
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${userId}_thumb.$extension';
      final String path = 'public/$type/$userId/$fileName';

      debugPrint('🖼️ Iniciando upload de thumbnail...');
      debugPrint('📍 Caminho: $path');

      // Upload do thumbnail
      if (kIsWeb) {
        final bytes = await XFile(thumbnailFile.path).readAsBytes();
        await supabase.storage.from('video_thumbnails').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );
      } else {
        await supabase.storage.from('video_thumbnails').upload(
              path,
              thumbnailFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );
      }

      final String publicUrl =
          supabase.storage.from('video_thumbnails').getPublicUrl(path);

      debugPrint('✅ Thumbnail enviado com sucesso!');
      debugPrint('🔗 URL: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ ERRO ao fazer upload do thumbnail: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fluxo completo: upload de vídeo + thumbnail
  /// Retorna um mapa com as URLs de ambos
  Future<VideoUploadResult> uploadVideoWithThumbnail({
    required File videoFile,
    File? thumbnailFile,
    required String userId,
    required String type,
    required int durationSeconds,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('📦 Iniciando upload completo (vídeo + thumbnail)...');

      // 1. Upload do vídeo
      final videoUrl = await uploadVideo(
        videoFile: videoFile,
        userId: userId,
        type: type,
        onProgress: onProgress,
      );

      // 2. Upload do thumbnail
      final thumbnailUrl = await uploadThumbnail(
        thumbnailFile: thumbnailFile,
        userId: userId,
        type: type,
      );

      debugPrint('✅ Upload completo finalizado!');

      return VideoUploadResult(
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugPrint('❌ ERRO no upload completo: $e');
      rethrow;
    }
  }

  /// Deleta um vídeo do storage
  Future<void> deleteVideo(String videoUrl) async {
    try {
      // Extrair o caminho do vídeo da URL
      final uri = Uri.parse(videoUrl);
      final path = uri.pathSegments
          .skip(3)
          .join('/'); // Remove /storage/v1/object/public/videos/

      debugPrint('🗑️ Deletando vídeo: $path');

      await supabase.storage.from('videos').remove([path]);

      debugPrint('✅ Vídeo deletado com sucesso!');
    } catch (e) {
      debugPrint('❌ ERRO ao deletar vídeo: $e');
      // Não propagar o erro, pois a deleção de mídia é secundária
    }
  }

  /// Deleta um thumbnail do storage
  Future<void> deleteThumbnail(String thumbnailUrl) async {
    try {
      // Extrair o caminho do thumbnail da URL
      final uri = Uri.parse(thumbnailUrl);
      final path = uri.pathSegments.skip(3).join('/');

      debugPrint('🗑️ Deletando thumbnail: $path');

      await supabase.storage.from('video_thumbnails').remove([path]);

      debugPrint('✅ Thumbnail deletado com sucesso!');
    } catch (e) {
      debugPrint('❌ ERRO ao deletar thumbnail: $e');
      // Não propagar o erro
    }
  }
}

class VideoUploadResult {
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSeconds;

  VideoUploadResult({
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
  });
}
