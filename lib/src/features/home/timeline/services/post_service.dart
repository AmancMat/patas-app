import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/features/home/timeline/models/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/features/video/services/video_upload_service.dart';
import '../../../../features/love/services/patas_love_service.dart';
import '../../../../../../main.dart';

class PostService {
  final VideoUploadService _videoUploadService = VideoUploadService();

  /// Utilitário para retry em caso de falhas temporárias (rede)
  Future<T> _retry<T>(Future<T> Function() action, {int maxRetries = 3}) async {
    int attempts = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempts++;
        final isNetworkError =
            e.toString().contains('SocketException') ||
            e.toString().contains('ClientException') ||
            e.toString().contains('AuthRetryableFetchException');

        if (attempts >= maxRetries || !isNetworkError) {
          rethrow;
        }
        debugPrint(
          'PostService: Tentativa $attempts falhou. Tentando novamente...',
        );
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  Future<String> uploadPostImage(File image) async {
    return _retry(() async {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('Usuário não autenticado');

        final String extension = kIsWeb ? 'jpg' : image.path.split('.').last;
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}.$extension';
        final String path = 'public/posts/${user.id}/$fileName';

        if (kIsWeb) {
          final bytes = await XFile(image.path).readAsBytes();
          await supabase.storage
              .from('posts')
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
              .from('posts')
              .upload(
                path,
                image,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );
        }

        final String publicUrl = supabase.storage
            .from('posts')
            .getPublicUrl(path);
        return publicUrl;
      } catch (e) {
        debugPrint('Erro no upload da imagem do post: $e');
        rethrow;
      }
    });
  }

  Future<Post?> createPost(Post post) async {
    return _retry(() async {
      try {
        final Map<String, dynamic> postData = post.toJson()
          ..remove('id')
          ..remove('created_at');

        final response = await supabase
            .from('posts')
            .insert(postData)
            .select(
              '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
            )
            .single();
        return Post.fromJson(response);
      } catch (e) {
        debugPrint('PostService: Erro ao criar post: $e');
        rethrow;
      }
    });
  }

  /// Cria um post com vídeo (upload + inserção no banco)
  Future<Post?> createPostWithVideo({
    required File videoFile,
    File? thumbnailFile,
    required int durationSeconds,
    required String content,
    String? petId,
    String? ongId,
    String? companyId,
    String? profileType,
    Function(double)? onUploadProgress,
  }) async {
    return _retry(() async {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('Usuário não autenticado');

        debugPrint('📝 Criando post com vídeo...');

        // 1. Upload do vídeo e thumbnail
        final uploadResult = await _videoUploadService.uploadVideoWithThumbnail(
          videoFile: videoFile,
          thumbnailFile: thumbnailFile,
          userId: user.id,
          type: 'post',
          durationSeconds: durationSeconds,
          onProgress: onUploadProgress,
        );

        debugPrint('✅ Upload concluído! Criando registro no banco...');

        // 2. Criar o post no banco de dados
        final postData = {
          'user_id': user.id,
          'pet_id': petId,
          'ong_id': ongId,
          'company_id': companyId,
          'profile_type': profileType ?? 'pet',
          'content': content,
          'is_video': true,
          'video_url': uploadResult.videoUrl,
          'video_thumbnail_url': uploadResult.thumbnailUrl,
          'video_duration': durationSeconds,
        };

        final response = await supabase
            .from('posts')
            .insert(postData)
            .select(
              '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
            )
            .single();

        debugPrint('✅ Post com vídeo criado com sucesso!');
        return Post.fromJson(response);
      } catch (e) {
        debugPrint('PostService: Erro ao criar post com vídeo: $e');
        rethrow;
      }
    });
  }

  Future<List<Post>> getPosts({
    String? userId,
    String? petId,
    String? ongId,
    String? companyId,
  }) async {
    try {
      final currentUser = supabase.auth.currentUser;

      // Query básica com joins para todos os tipos de perfis
      var query = supabase
          .from('posts')
          .select(
            '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
          );

      // Aplica filtros de dono ou pet específicos (perfil)
      if (ongId != null) {
        query = query.eq('ong_id', ongId);
      } else if (companyId != null) {
        query = query.eq('company_id', companyId);
      } else if (petId != null) {
        query = query.eq('pet_id', petId);
      } else if (userId != null) {
        query = query.eq('user_id', userId);
      } else if (currentUser != null) {
        // TIMELINE: Mostrar apenas posts de pets seguidos ou pets do próprio usuário

        // 1. Buscar IDs de pets seguidos
        final followsResponse = await supabase
            .from('follows')
            .select('followed_pet_id')
            .eq('follower_id', currentUser.id);

        final List<String> followedPetIds = (followsResponse as List)
            .map((item) => item['followed_pet_id'])
            .whereType<String>()
            .toList();

        // ── COLD START ─────────────────────────────────────────────
        // Se o usuário não segue nenhum pet ainda, exibe o feed baseado nos interesses
        if (followedPetIds.isEmpty) {
          return await _getColdStartPosts(currentUser.id);
        }
        // ── FIM COLD START ─────────────────────────────────────────

        // 3. Buscar IDs de ONGs próprias
        final ownOngsResponse = await supabase
            .from('ong_profiles')
            .select('id')
            .eq('user_id', currentUser.id);

        final List<String> ownOngIds = (ownOngsResponse as List)
            .map((item) => item['id'])
            .whereType<String>()
            .toList();

        // 4. Buscar IDs de pets próprios
        final ownPetsResponse = await supabase
            .from('pets')
            .select('id')
            .eq('user_id', currentUser.id);

        final List<String> ownPetIds = (ownPetsResponse as List)
            .map((item) => item['id'])
            .whereType<String>()
            .toList();

        final List<String> allVisiblePetIds = [...followedPetIds, ...ownPetIds];

        // 5. Buscar IDs de Empresas próprias
        final ownCorpResponse = await supabase
            .from('company_profiles')
            .select('id')
            .eq('user_id', currentUser.id);

        final List<String> ownCorpIds = (ownCorpResponse as List)
            .map((item) => item['id'])
            .whereType<String>()
            .toList();

        // Construir filtro OR para incluir pets seguidos/próprios E organizações próprias
        List<String> orFilters = [];

        if (allVisiblePetIds.isNotEmpty) {
          orFilters.add('pet_id.in.(${allVisiblePetIds.join(",")})');
        }

        if (ownOngIds.isNotEmpty) {
          orFilters.add('ong_id.in.(${ownOngIds.join(",")})');
        }

        if (ownCorpIds.isNotEmpty) {
          orFilters.add('company_id.in.(${ownCorpIds.join(",")})');
        }

        if (orFilters.isNotEmpty) {
          query = query.or(orFilters.join(','));
        } else {
          return [];
        }
      }

      // Se tiver usuário logado, filtramos os posts que ele OCULTOU
      if (currentUser != null) {
        final hiddenResponse = await supabase
            .from('hidden_posts')
            .select('post_id')
            .eq('user_id', currentUser.id);

        final List<String> hiddenPostIds = (hiddenResponse as List)
            .map((item) => item['post_id'])
            .whereType<String>()
            .toList();

        if (hiddenPostIds.isNotEmpty) {
          query = query.not('id', 'in', '(${hiddenPostIds.join(",")})');
        }
      }

      final response = await query.order('created_at', ascending: false);

      final List<Post> posts = (response as List)
          .map((postData) => Post.fromJson(postData))
          .toList();

      // Filtra posts de tutores bloqueados no Patas Love
      if (currentUser != null) {
        try {
          final blockedIds = await PatasLoveService()
              .getBlockedUserIds(currentUser.id);
          if (blockedIds.isNotEmpty) {
            return posts
                .where((p) => !blockedIds.contains(p.userId))
                .toList();
          }
        } catch (_) {
          // Falha silenciosa: se não conseguir obter bloqueios, retorna todos os posts
        }
      }

      return posts;
    } on SocketException catch (e) {
      debugPrint('PostService: Erro de conexão (SocketException): $e');
      throw 'Sem conexão com o servidor. Verifique sua internet.';
    } catch (e) {
      if (e.toString().contains('ClientException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('AuthRetryableFetchException')) {
        debugPrint('PostService: Erro de rede detectado: $e');
        throw 'Erro de rede. Verifique sua conexão.';
      }
      debugPrint('PostService: Erro ao buscar posts: $e');
      rethrow;
    }
  }

  Future<void> hidePost(String postId) async {
    return _retry(() async {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('Usuário não autenticado');

        await supabase.from('hidden_posts').insert({
          'user_id': user.id,
          'post_id': postId,
        });
      } catch (e) {
        debugPrint('PostService: Erro ao ocultar post: $e');
        rethrow;
      }
    });
  }

  Future<void> deletePost(String postId) async {
    return _retry(() async {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) {
          debugPrint('PostService: Tentativa de deletar sem usuário logado');
          throw Exception('Usuário não autenticado');
        }

        final List<dynamic> data = await supabase
            .from('posts')
            .delete()
            .eq('id', postId)
            .select();

        if (data.isEmpty) {
          debugPrint(
            'PostService: Nenhuma linha deletada. Verifique as políticas RLS.',
          );
        }
      } catch (e) {
        debugPrint('Erro detalhado ao deletar post: $e');
        rethrow;
      }
    });
  }

  Future<List<Post>> getDiscoveryPosts({int limit = 20, int offset = 0}) async {
    try {
      final response = await supabase
          .from('posts')
          .select(
            '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
          )
          .not('image_url', 'is', null) // Apenas posts com imagem para o grid
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<Post> posts = (response as List)
          .map((postData) => Post.fromJson(postData))
          .toList();

      return posts;
    } catch (e) {
      debugPrint('PostService: Erro ao buscar discovery posts: $e');
      return [];
    }
  }

  Future<Post?> getPostById(String postId) async {
    try {
      final response = await supabase
          .from('posts')
          .select(
            '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
          )
          .eq('id', postId)
          .maybeSingle();

      if (response == null) return null;
      return Post.fromJson(response);
    } catch (e) {
      debugPrint('PostService: Erro ao buscar post por ID: $e');
      return null;
    }
  }

  Future<List<Post>> _getColdStartPosts(String userId) async {
    try {
      // 1. Carregar interesses do usuário
      final userRow = await supabase
          .from('users')
          .select('interests')
          .eq('id', userId)
          .maybeSingle();

      final interests = userRow?['interests'];
      final speciesList = (interests is Map)
          ? (interests['species'] as List?)?.whereType<String>().toList()
          : null;

      final wantsAll =
          speciesList == null ||
          speciesList.isEmpty ||
          speciesList.contains('todos');

      // 2. Montar query base
      final baseSelect =
          '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)';

      List<dynamic> response = [];

      if (!wantsAll && speciesList.isNotEmpty) {
        // 3a. Filtrar por espécies de interesse
        final petsOfSpecies = await supabase
            .from('pets')
            .select('id')
            .inFilter('species', speciesList);

        final coldStartPetIds = (petsOfSpecies as List)
            .map((e) => e['id'])
            .whereType<String>()
            .toList();

        if (coldStartPetIds.isNotEmpty) {
          response = await supabase
              .from('posts')
              .select(baseSelect)
              .inFilter('pet_id', coldStartPetIds)
              .order('created_at', ascending: false)
              .limit(30);
        }
      }

      // Se a resposta filtrada for vazia (ou o usuário selecionou 'todos' / não configurou),
      // fazemos o fallback automático para o feed global recente para nunca exibir uma tela vazia.
      if (response.isEmpty) {
        response = await supabase
            .from('posts')
            .select(baseSelect)
            .order('created_at', ascending: false)
            .limit(30);
      }

      return (response).map((postData) => Post.fromJson(postData)).toList();
    } catch (e) {
      debugPrint('PostService: Erro no Cold Start: $e');
      return [];
    }
  }

  // Buscar publicações de um pet específico ordenadas por data de criação para o Patas História
  Future<List<Post>> getPostsByPetId(String petId) async {
    try {
      final response = await supabase
          .from('posts')
          .select(
            '*, tutor_profiles(name, photo_url), pets(*), ong_profiles(*), company_profiles(*)',
          )
          .eq('pet_id', petId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((postData) => Post.fromJson(postData))
          .toList();
    } catch (e) {
      debugPrint('PostService: Erro ao buscar posts por petId: $e');
      return [];
    }
  }

  // ── FIM COLD START ────────────────────────────────────────────────────
}
