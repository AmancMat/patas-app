import 'package:flutter/foundation.dart';
import 'package:patas_web_app/src/models/notification_model.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart';
import '../models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/models/follow_item_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';

class FollowService {
  final _supabase = supabase;

  /// Segue uma organização (ONG ou Empresa)
  Future<void> followOrg({String? ongId, String? companyId}) async {
    debugPrint(
      'FollowService: followOrg(ongId: $ongId, companyId: $companyId)',
    );
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    if (ongId == null && companyId == null) {
      throw Exception('ID da organização não fornecido');
    }

    try {
      await _supabase.from('follows').insert({
        'follower_id': user.id,
        'followed_ong_id': ongId,
        'followed_company_id': companyId,
      });
      debugPrint('FollowService: followOrg sucesso');
    } on PostgrestException catch (e) {
      debugPrint('FollowService: Erro ao seguir organização: ${e.message}');
      rethrow;
    }
  }

  /// Deixa de seguir uma organização
  Future<void> unfollowOrg({String? ongId, String? companyId}) async {
    debugPrint(
      'FollowService: unfollowOrg(ongId: $ongId, companyId: $companyId)',
    );
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      var query = _supabase.from('follows').delete().eq('follower_id', user.id);

      if (ongId != null) {
        query = query.eq('followed_ong_id', ongId);
      } else if (companyId != null) {
        query = query.eq('followed_company_id', companyId);
      } else {
        throw Exception('ID da organização não fornecido');
      }

      await query;
      debugPrint('FollowService: unfollowOrg sucesso');
    } on PostgrestException catch (e) {
      debugPrint(
        'FollowService: Erro ao deixar de seguir organização: ${e.message}',
      );
      rethrow;
    }
  }

  /// Verifica se o usuário atual segue a organização
  Future<bool> isFollowingOrg({String? ongId, String? companyId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      var query = _supabase.from('follows').select().eq('follower_id', user.id);

      if (ongId != null) {
        query = query.eq('followed_ong_id', ongId);
      } else if (companyId != null) {
        query = query.eq('followed_company_id', companyId);
      } else {
        return false;
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('FollowService: Erro ao verificar follow org: $e');
      return false;
    }
  }

  /// Obtém a quantidade de seguidores de uma organização
  Future<int> getOrgFollowersCount({String? ongId, String? companyId}) async {
    try {
      var query = _supabase.from('follows').select('id');

      if (ongId != null) {
        query = query.eq('followed_ong_id', ongId);
      } else if (companyId != null) {
        query = query.eq('followed_company_id', companyId);
      } else {
        return 0;
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      debugPrint('FollowService: Erro ao contar seguidores da org: $e');
      return 0;
    }
  }

  /// Segue um pet
  Future<void> followPet(String petId, {String? senderPetId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      await _supabase.from('follows').insert({
        'follower_id': user.id,
        'followed_pet_id': petId,
      });

      // Enviar notificação para o dono do pet seguido
      _sendFollowNotification(petId, senderPetId);
    } on PostgrestException catch (e) {
      debugPrint('Erro ao seguir pet: ${e.message}');
      rethrow;
    }
  }

  /// Deixa de seguir um pet
  Future<void> unfollowPet(String petId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('followed_pet_id', petId);
    } on PostgrestException catch (e) {
      debugPrint('Erro ao deixar de seguir pet: ${e.message}');
      rethrow;
    }
  }

  /// Verifica se o usuário atual segue o pet
  Future<bool> isFollowing(String petId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', user.id)
          .eq('followed_pet_id', petId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Erro ao verificar follow: $e');
      return false;
    }
  }

  /// Obtém a quantidade de seguidores de um pet
  Future<int> getFollowersCount(String petId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('*')
          .eq('followed_pet_id', petId);

      return response.length;
    } catch (e) {
      debugPrint('Erro ao contar seguidores: $e');
      return 0;
    }
  }

  /// Obtém a quantidade de pets que um usuário segue
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('*')
          .eq('follower_id', userId);

      return response.length;
    } catch (e) {
      debugPrint('Erro ao contar seguindo: $e');
      return 0;
    }
  }

  /// Obtém a lista unificada de todos os perfis (Pets, ONGs, Empresas) que um usuário segue
  Future<List<FollowItem>> getFollowingItems(String userId) async {
    try {
      final follows = await _supabase
          .from('follows')
          .select('followed_pet_id, followed_ong_id, followed_company_id')
          .eq('follower_id', userId);

      final petIds = (follows as List)
          .map((f) => f['followed_pet_id'])
          .whereType<String>()
          .toList();
      final ongIds = follows
          .map((f) => f['followed_ong_id'])
          .whereType<String>()
          .toList();
      final corpIds = follows
          .map((f) => f['followed_company_id'])
          .whereType<String>()
          .toList();

      final List<Future> queries = [];
      if (petIds.isNotEmpty) {
        queries.add(_supabase.from('pets').select().inFilter('id', petIds));
      } else {
        queries.add(Future.value(<dynamic>[]));
      }

      if (ongIds.isNotEmpty) {
        queries.add(_supabase.from('ong_profiles').select().inFilter('id', ongIds));
      } else {
        queries.add(Future.value(<dynamic>[]));
      }

      if (corpIds.isNotEmpty) {
        queries.add(_supabase.from('company_profiles').select().inFilter('id', corpIds));
      } else {
        queries.add(Future.value(<dynamic>[]));
      }

      final results = await Future.wait(queries);
      final petsData = results[0] as List;
      final ongsData = results[1] as List;
      final corpsData = results[2] as List;

      final List<FollowItem> items = [];

      for (final p in petsData) {
        final pet = Pet.fromJson(p);
        items.add(FollowItem(
          id: pet.id,
          name: pet.name,
          photoUrl: pet.photoUrl,
          subtitle: pet.breed ?? (pet.species.isNotEmpty ? pet.species : 'Pet'),
          type: FollowItemType.pet,
          pet: pet,
        ));
      }

      for (final o in ongsData) {
        final ong = OngProfile.fromJson(o);
        final acts = ong.activityAreas;
        final subtitle = (acts != null && acts.isNotEmpty)
            ? acts.join(', ')
            : (ong.about?.isNotEmpty == true ? ong.about! : 'ONG de Proteção Animal');
        items.add(FollowItem(
          id: ong.id,
          name: ong.name,
          photoUrl: ong.photoUrl,
          subtitle: subtitle,
          type: FollowItemType.ong,
          ong: ong,
        ));
      }

      for (final c in corpsData) {
        final corp = CorpProfile.fromJson(c);
        items.add(FollowItem(
          id: corp.id,
          name: corp.name,
          photoUrl: corp.photoUrl,
          subtitle: corp.category.isNotEmpty ? corp.category : 'Empresa Parceira',
          type: FollowItemType.corp,
          corp: corp,
        ));
      }

      return items;
    } catch (e) {
      debugPrint('Erro ao buscar itens de seguindo: $e');
      return [];
    }
  }

  /// Obtém a lista de quem segue um pet específico (Pets, ONGs, Empresas ou Tutores)
  Future<List<FollowItem>> getFollowersItems(String petId) async {
    try {
      final follows = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('followed_pet_id', petId);

      final followerIds = (follows as List)
          .map((f) => f['follower_id'])
          .whereType<String>()
          .toList();
      if (followerIds.isEmpty) return [];

      final results = await Future.wait([
        _supabase.from('pets').select().inFilter('user_id', followerIds),
        _supabase.from('ong_profiles').select().inFilter('user_id', followerIds),
        _supabase.from('company_profiles').select().inFilter('user_id', followerIds),
        _supabase.from('tutor_profiles').select().inFilter('id', followerIds),
      ]);

      final petsData = results[0] as List;
      final ongsData = results[1] as List;
      final corpsData = results[2] as List;
      final tutorsData = results[3] as List;

      final List<FollowItem> items = [];
      final Set<String> processedFollowerIds = {};

      // 1. Prioridade: Se o seguidor tem um Pet cadastrado
      for (final p in petsData) {
        final userId = p['user_id'] as String?;
        if (userId != null && !processedFollowerIds.contains(userId)) {
          processedFollowerIds.add(userId);
          final pet = Pet.fromJson(p);
          items.add(FollowItem(
            id: pet.id,
            name: pet.name,
            photoUrl: pet.photoUrl,
            subtitle: pet.breed ?? (pet.species.isNotEmpty ? pet.species : 'Pet'),
            type: FollowItemType.pet,
            pet: pet,
          ));
        }
      }

      // 2. Se for uma ONG seguidora
      for (final o in ongsData) {
        final userId = o['user_id'] as String?;
        if (userId != null && !processedFollowerIds.contains(userId)) {
          processedFollowerIds.add(userId);
          final ong = OngProfile.fromJson(o);
          items.add(FollowItem(
            id: ong.id,
            name: ong.name,
            photoUrl: ong.photoUrl,
            subtitle: 'ONG de Proteção',
            type: FollowItemType.ong,
            ong: ong,
          ));
        }
      }

      // 3. Se for uma Empresa seguidora
      for (final c in corpsData) {
        final userId = c['user_id'] as String?;
        if (userId != null && !processedFollowerIds.contains(userId)) {
          processedFollowerIds.add(userId);
          final corp = CorpProfile.fromJson(c);
          items.add(FollowItem(
            id: corp.id,
            name: corp.name,
            photoUrl: corp.photoUrl,
            subtitle: corp.category.isNotEmpty ? corp.category : 'Empresa',
            type: FollowItemType.corp,
            corp: corp,
          ));
        }
      }

      // 4. Se for tutor sem pet cadastrado ainda
      for (final t in tutorsData) {
        final tutorId = t['id'] as String?;
        if (tutorId != null && !processedFollowerIds.contains(tutorId)) {
          processedFollowerIds.add(tutorId);
          items.add(FollowItem(
            id: tutorId,
            name: t['name'] ?? 'Tutor',
            photoUrl: t['photo_url'],
            subtitle: 'Tutor',
            type: FollowItemType.tutor,
            userId: tutorId,
          ));
        }
      }

      return items;
    } catch (e) {
      debugPrint('Erro ao buscar itens de seguidores: $e');
      return [];
    }
  }

  /// Obtém a lista de pets que seguem um pet específico
  Future<List<Pet>> getFollowers(String petId) async {
    try {
      final follows = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('followed_pet_id', petId);

      final followerIds = (follows as List)
          .map((f) => f['follower_id'])
          .whereType<String>()
          .toList();
      if (followerIds.isEmpty) return [];

      final petsResponse = await _supabase
          .from('pets')
          .select()
          .inFilter('user_id', followerIds);

      return (petsResponse as List).map((p) => Pet.fromJson(p)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar seguidores: $e');
      return [];
    }
  }

  /// Obtém a lista de pets que um usuário segue
  Future<List<Pet>> getFollowing(String userId) async {
    try {
      final follows = await _supabase
          .from('follows')
          .select('followed_pet_id')
          .eq('follower_id', userId);

      final followedPetIds = (follows as List)
          .map((f) => f['followed_pet_id'])
          .whereType<String>()
          .toList();
      if (followedPetIds.isEmpty) return [];

      final petsResponse = await _supabase
          .from('pets')
          .select()
          .inFilter('id', followedPetIds);

      return (petsResponse as List).map((p) => Pet.fromJson(p)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar seguindo: $e');
      return [];
    }
  }

  /// Método privado para enviar notificação de follow
  Future<void> _sendFollowNotification(
    String petId,
    String? senderPetId,
  ) async {
    try {
      // Busca o dono do pet que está sendo seguido
      final petResponse = await _supabase
          .from('pets')
          .select('user_id, name')
          .eq('id', petId)
          .single();

      final petOwnerId = petResponse['user_id'];
      final petName = petResponse['name'];
      if (petOwnerId == null) return;

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Busca o nome do autor (pet ou usuário)
      String senderName = 'Alguém';
      if (senderPetId != null) {
        final petRes = await _supabase
            .from('pets')
            .select('name')
            .eq('id', senderPetId)
            .single();
        senderName = petRes['name'] ?? 'Alguém';
      } else {
        final userRes = await _supabase
            .from('tutor_profiles')
            .select('name')
            .eq('id', currentUser.id)
            .single();
        senderName = userRes['name'] ?? 'Alguém';
      }

      await SupabaseNotificationService().sendNotification(
        receiverUserId: petOwnerId,
        senderPetId: senderPetId,
        type: NotificationType.follow,
        title: 'Novo seguidor!',
        content: '$senderName começou a seguir seu pet $petName.',
        data: {'pet_id': petId},
      );
    } catch (e) {
      debugPrint('FollowService: Erro ao enviar notificação: $e');
    }
  }
}
