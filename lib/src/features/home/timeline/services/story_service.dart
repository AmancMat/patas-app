import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/features/home/timeline/models/story_model.dart';
import 'package:patas_web_app/src/features/video/services/video_upload_service.dart';
import '../../../../../../main.dart';

class StoryService {
  final VideoUploadService _videoUploadService = VideoUploadService();
  Future<void> createStory({
    required File imageFile,
    String? petId,
    String? ongId,
    String? companyId,
    String? profileType,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final String fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = fileName;

      if (kIsWeb) {
        final bytes = await XFile(imageFile.path).readAsBytes();
        await supabase.storage
            .from('stories')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );
      } else {
        await supabase.storage
            .from('stories')
            .upload(
              path,
              imageFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );
      }

      final String imageUrl = supabase.storage
          .from('stories')
          .getPublicUrl(path);

      // 2. Insert Record
      await supabase.from('stories').insert({
        'user_id': user.id,
        'pet_id': petId,
        'ong_id': ongId,
        'company_id': companyId,
        'profile_type': profileType ?? 'pet',
        'media_url': imageUrl,
      });
    } catch (e) {
      debugPrint('StoryService: Erro ao criar story: $e');
      rethrow;
    }
  }

  /// Cria um story com vídeo (upload + inserção no banco)
  Future<void> createStoryWithVideo({
    required File videoFile,
    File? thumbnailFile,
    required int durationSeconds,
    String? petId,
    String? ongId,
    String? companyId,
    String? profileType,
    Function(double)? onUploadProgress,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      debugPrint('📝 Criando story com vídeo...');

      // 1. Upload do vídeo e thumbnail
      final uploadResult = await _videoUploadService.uploadVideoWithThumbnail(
        videoFile: videoFile,
        thumbnailFile: thumbnailFile,
        userId: user.id,
        type: 'story',
        durationSeconds: durationSeconds,
        onProgress: onUploadProgress,
      );

      debugPrint('✅ Upload concluído! Criando registro no banco...');

      // 2. Criar o story no banco de dados
      await supabase.from('stories').insert({
        'user_id': user.id,
        'pet_id': petId,
        'ong_id': ongId,
        'company_id': companyId,
        'profile_type': profileType ?? 'pet',
        'media_url': uploadResult.thumbnailUrl, // Usar thumbnail como media_url
        'is_video': true,
        'video_url': uploadResult.videoUrl,
        'video_thumbnail_url': uploadResult.thumbnailUrl,
        'video_duration': durationSeconds,
      });

      debugPrint('✅ Story com vídeo criado com sucesso!');
    } catch (e) {
      debugPrint('StoryService: Erro ao criar story com vídeo: $e');
      rethrow;
    }
  }

  Future<List<Story>> getStories() async {
    try {
      final currentUser = supabase.auth.currentUser;
      final String nowIso = DateTime.now().toIso8601String();
      debugPrint('StoryService: Buscando stories válidos após $nowIso');

      var query = supabase
          .from('stories')
          .select(
            '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
          )
          .gt('expires_at', nowIso);

      if (currentUser != null) {
        // 1. Buscar IDs de pets seguidos
        final followsResponse = await supabase
            .from('follows')
            .select('followed_pet_id')
            .eq('follower_id', currentUser.id);

        final List<String> followedPetIds = (followsResponse as List)
            .map((item) => item['followed_pet_id'])
            .whereType<String>()
            .toList();

        // 2. Buscar IDs de pets próprios
        final ownPetsResponse = await supabase
            .from('pets')
            .select('id')
            .eq('user_id', currentUser.id);

        final List<String> ownPetIds = (ownPetsResponse as List)
            .map((item) => item['id'])
            .whereType<String>()
            .toList();

        final List<String> allVisiblePetIds = [...followedPetIds, ...ownPetIds];

        // 3. Buscar IDs de ONGs próprias
        final ownOngsResponse = await supabase
            .from('ong_profiles')
            .select('id')
            .eq('user_id', currentUser.id);

        final List<String> ownOngIds = (ownOngsResponse as List)
            .map((item) => item['id'])
            .whereType<String>()
            .toList();

        // 4. Buscar IDs de Empresas próprias
        final ownCorpResponse = await supabase
            .from('company_profiles')
            .select('id')
            .eq('user_id', currentUser.id);

        final List<String> ownCorpIds = (ownCorpResponse as List)
            .map((item) => item['id'])
            .whereType<String>()
            .toList();

        // Construir filtro OR
        // O autor sempre vê os próprios stories (user_id é fixo)
        List<String> orFilters = ['user_id.eq.${currentUser.id}'];

        if (allVisiblePetIds.isNotEmpty) {
          orFilters.add('pet_id.in.(${allVisiblePetIds.join(",")})');
        }

        if (ownOngIds.isNotEmpty) {
          orFilters.add('ong_id.in.(${ownOngIds.join(",")})');
        }

        if (ownCorpIds.isNotEmpty) {
          orFilters.add('company_id.in.(${ownCorpIds.join(",")})');
        }

        query = query.or(orFilters.join(','));
      }

      final response = await query.order('created_at', ascending: false);

      debugPrint('StoryService: ${response.length} stories encontrados.');

      final List<Story> stories = (response as List)
          .map((item) => Story.fromJson(item))
          .toList();
      return stories;
    } on SocketException catch (e) {
      debugPrint('StoryService: Erro de conexão (SocketException): $e');
      // No caso de stories, retornar lista vazia é seguro para a UI
      return [];
    } catch (e) {
      if (e.toString().contains('ClientException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('AuthRetryableFetchException')) {
        debugPrint('StoryService: Erro de rede detectado: $e');
        return [];
      }
      debugPrint('StoryService: Erro ao buscar stories: $e');
      return [];
    }
  }

  Future<List<Story>> getDiscoveryStories({int limit = 10}) async {
    try {
      final String nowIso = DateTime.now().toIso8601String();
      final response = await supabase
          .from('stories')
          .select(
            '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
          )
          .gt('expires_at', nowIso)
          .order('created_at', ascending: false)
          .limit(limit);

      final List<Story> stories = (response as List)
          .map((item) => Story.fromJson(item))
          .toList();
      return stories;
    } catch (e) {
      debugPrint('StoryService: Erro ao buscar discovery stories: $e');
      return [];
    }
  }

  Future<List<Story>> getStoriesByPetId(String petId) async {
    try {
      final response = await supabase
          .from('stories')
          .select(
            '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
          )
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      final List<Story> stories = (response as List)
          .map((item) => Story.fromJson(item))
          .toList();
      return stories;
    } catch (e) {
      debugPrint('StoryService: Erro ao buscar stories do pet: $e');
      return [];
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      await supabase
          .from('stories')
          .delete()
          .eq('id', storyId)
          .eq('user_id', user.id);

      debugPrint('StoryService: Story $storyId deletado com sucesso.');
    } catch (e) {
      debugPrint('StoryService: Erro ao deletar story: $e');
      rethrow;
    }
  }
}
