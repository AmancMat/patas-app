import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/notification_model.dart';
import '../../../services/supabase_notification_service.dart';
import '../../pets/models/pet_model.dart';
import '../../../../main.dart';

class PatasLoveService {
  final SupabaseClient _supabase;

  PatasLoveService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Busca pets compatíveis disponíveis no Patas Love
  Future<List<Pet>> getCompatiblePets({
    required Pet activePet,
    String? breedFilter,
    String? genderFilter,
  }) async {
    try {
      final response = await _supabase
          .from('pets')
          .select()
          .eq('is_love_active', true)
          .neq('user_id', activePet.userId)
          .order('created_at', ascending: false);

      final allLovePets =
          (response as List).map((json) => Pet.fromJson(json)).toList();

      final activeSpeciesGroup = _getSpeciesGroup(activePet.species);
      final activeGenderGroup = _getGenderGroup(activePet.gender);

      final targetGenderGroup = (genderFilter != null && genderFilter.isNotEmpty)
          ? _getGenderGroup(genderFilter)
          : (activeGenderGroup == 'macho'
              ? 'femea'
              : (activeGenderGroup == 'femea' ? 'macho' : null));

      final blockedUserIds = await getBlockedUserIds(activePet.userId);

      final filteredPets = allLovePets.where((p) {
        // 0. Não deve pertencer a um tutor bloqueado por nós ou que nos bloqueou
        if (blockedUserIds.contains(p.userId)) return false;

        // 1. Deve ser da mesma espécie (cão com cão, gato com gato)
        final pSpeciesGroup = _getSpeciesGroup(p.species);
        if (pSpeciesGroup != activeSpeciesGroup) return false;

        // 2. Filtro de gênero oposto por padrão
        if (targetGenderGroup != null) {
          final pGenderGroup = _getGenderGroup(p.gender);
          if (pGenderGroup != null && pGenderGroup != targetGenderGroup) {
            return false;
          }
        }

        // 3. Filtro manual de raça (se especificado pelo usuário)
        if (breedFilter != null && breedFilter.isNotEmpty) {
          final normalizedBreedFilter = breedFilter.toLowerCase().trim();
          final pBreed = (p.breed ?? '').toLowerCase().trim();
          if (!pBreed.contains(normalizedBreedFilter) &&
              !normalizedBreedFilter.contains(pBreed)) {
            return false;
          }
        }

        return true;
      }).toList();

      // Ordenação Inteligente: Pets da MESMA RAÇA aparecem PRIMEIRO no topo da lista!
      final activeBreed = (activePet.breed ?? '').toLowerCase().trim();
      filteredPets.sort((a, b) {
        final aBreed = (a.breed ?? '').toLowerCase().trim();
        final bBreed = (b.breed ?? '').toLowerCase().trim();

        final aIsSameBreed = activeBreed.isNotEmpty && aBreed == activeBreed;
        final bIsSameBreed = activeBreed.isNotEmpty && bBreed == activeBreed;

        if (aIsSameBreed && !bIsSameBreed) return -1;
        if (!aIsSameBreed && bIsSameBreed) return 1;
        return 0;
      });

      return filteredPets;
    } catch (e) {
      print('Erro ao buscar pets no Patas Love: $e');
      return [];
    }
  }

  String _getSpeciesGroup(String species) {
    final s = species.toLowerCase().trim();
    if (s.contains('cão') ||
        s.contains('cao') ||
        s.contains('cachorro') ||
        s.contains('canino') ||
        s.contains('dog')) {
      return 'dog';
    }
    if (s.contains('gato') || s.contains('felino') || s.contains('cat')) {
      return 'cat';
    }
    return s;
  }

  String? _getGenderGroup(String? gender) {
    if (gender == null) return null;
    final g = gender.toLowerCase().trim();
    if (g.contains('macho') || g.contains('male')) return 'macho';
    if (g.contains('fêmea') ||
        g.contains('femea') ||
        g.contains('female')) {
      return 'femea';
    }
    return g;
  }

  /// Busca ou cria um chat entre dois pets
  Future<String?> getOrCreateChat({
    required String petAId,
    required String petBId,
  }) async {
    try {
      // Ordena IDs para evitar duplicidade de par (A,B vs B,A)
      final firstPet = petAId.compareTo(petBId) < 0 ? petAId : petBId;
      final secondPet = petAId.compareTo(petBId) < 0 ? petBId : petAId;

      final existing = await _supabase
          .from('love_chats')
          .select('id')
          .or('and(pet_a_id.eq.$firstPet,pet_b_id.eq.$secondPet),and(pet_a_id.eq.$secondPet,pet_b_id.eq.$firstPet)')
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      final created = await _supabase
          .from('love_chats')
          .insert({
            'pet_a_id': firstPet,
            'pet_b_id': secondPet,
          })
          .select('id')
          .single();

      final chatId = created['id'] as String;

      // Dispara notificação de novo interesse / match no Patas Love
      _sendLoveMatchNotification(senderPetId: petAId, targetPetId: petBId);

      return chatId;
    } catch (e) {
      print('Erro ao obter/criar chat no Patas Love: $e');
      return null;
    }
  }

  /// Dispara notificação de match/interesse para o dono do pet alvo
  Future<void> _sendLoveMatchNotification({
    required String senderPetId,
    required String targetPetId,
  }) async {
    try {
      final senderPet = await _supabase
          .from('pets')
          .select('name, photo_url')
          .eq('id', senderPetId)
          .single();

      final targetPet = await _supabase
          .from('pets')
          .select('name, user_id')
          .eq('id', targetPetId)
          .single();

      final targetUserId = targetPet['user_id'] as String?;
      if (targetUserId == null) return;

      final senderName = senderPet['name'] ?? 'Um pet';
      final targetName = targetPet['name'] ?? 'seu pet';

      await SupabaseNotificationService().sendNotification(
        receiverUserId: targetUserId,
        senderPetId: senderPetId,
        type: NotificationType.system,
        title: '💕 Deu Match no Patas Love!',
        content: '$senderName demonstrou interesse em $targetName no Patas Love.',
        data: {
          'type': 'love_match',
          'sender_pet_id': senderPetId,
          'target_pet_id': targetPetId,
        },
      );
    } catch (e) {
      print('Erro ao enviar notificação do Patas Love: $e');
    }
  }

  /// Obtém o conjunto de IDs de usuários bloqueados (bloqueados pelo usuário ou que bloquearam o usuário)
  Future<Set<String>> getBlockedUserIds(String userId) async {
    try {
      final blocks = await _supabase
          .from('love_blocks')
          .select('blocker_id, blocked_id')
          .or('blocker_id.eq.$userId,blocked_id.eq.$userId');

      final Set<String> ids = {};
      for (var b in (blocks as List)) {
        final blocker = b['blocker_id'] as String;
        final blocked = b['blocked_id'] as String;
        if (blocker == userId) ids.add(blocked);
        if (blocked == userId) ids.add(blocker);
      }
      return ids;
    } catch (e) {
      print('Erro ao buscar IDs de bloqueio: $e');
      return {};
    }
  }

  /// Busca a lista de chats ativos de um pet
  Future<List<Map<String, dynamic>>> getChatsForPet(String petId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final blockedUserIds = currentUserId != null
          ? await getBlockedUserIds(currentUserId)
          : <String>{};

      dynamic response;
      try {
        response = await _supabase
            .from('love_chats')
            .select('''
              id,
              pet_a_id,
              pet_b_id,
              created_at,
              updated_at,
              status,
              meeting_proposed_by,
              meeting_date,
              meeting_location,
              meeting_notes,
              pet_a:pet_a_id(id, name, photo_url, breed, species, user_id),
              pet_b:pet_b_id(id, name, photo_url, breed, species, user_id)
            ''')
            .or('pet_a_id.eq.$petId,pet_b_id.eq.$petId')
            .order('updated_at', ascending: false);
      } catch (e) {
        debugPrint('Tentando fallback simplificado de love_chats: $e');
        response = await _supabase
            .from('love_chats')
            .select('''
              id,
              pet_a_id,
              pet_b_id,
              created_at,
              updated_at,
              pet_a:pet_a_id(id, name, photo_url, breed, species, user_id),
              pet_b:pet_b_id(id, name, photo_url, breed, species, user_id)
            ''')
            .or('pet_a_id.eq.$petId,pet_b_id.eq.$petId')
            .order('updated_at', ascending: false);
      }

      final List<Map<String, dynamic>> allChats =
          List<Map<String, dynamic>>.from(response as List);

      // Preenchimento defensivo: garante que os dois pets tenham dados válidos
      for (var chat in allChats) {
        if (chat['pet_a'] == null && chat['pet_a_id'] != null) {
          try {
            final pA = await _supabase
                .from('pets')
                .select('id, name, photo_url, breed, species, user_id')
                .eq('id', chat['pet_a_id'])
                .maybeSingle();
            if (pA != null) chat['pet_a'] = pA;
          } catch (_) {}
        }
        if (chat['pet_b'] == null && chat['pet_b_id'] != null) {
          try {
            final pB = await _supabase
                .from('pets')
                .select('id, name, photo_url, breed, species, user_id')
                .eq('id', chat['pet_b_id'])
                .maybeSingle();
            if (pB != null) chat['pet_b'] = pB;
          } catch (_) {}
        }
      }

      if (blockedUserIds.isEmpty) return allChats;

      return allChats.where((chat) {
        final petA = chat['pet_a'];
        final petB = chat['pet_b'];
        final petAUserId = petA?['user_id'] as String?;
        final petBUserId = petB?['user_id'] as String?;

        if (petAUserId != null &&
            blockedUserIds.contains(petAUserId) &&
            petAUserId != currentUserId) {
          return false;
        }
        if (petBUserId != null &&
            blockedUserIds.contains(petBUserId) &&
            petBUserId != currentUserId) {
          return false;
        }
        return true;
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar chats do pet: $e');
      return [];
    }
  }

  /// Busca mensagens de um chat
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final response = await _supabase
          .from('love_messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Erro ao carregar mensagens: $e');
      return [];
    }
  }

  /// Stream em tempo real das mensagens de um chat
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _supabase
        .from('love_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }

  /// Stream em tempo real das atualizações de status/encontro de um chat
  Stream<Map<String, dynamic>?> getChatMeetingStream(String chatId) {
    return _supabase
        .from('love_chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  /// Marca mensagens recebidas como lidas
  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      await _supabase
          .from('love_messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_user_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Erro ao marcar mensagens como lidas: $e');
    }
  }

  /// Envia uma mensagem em um chat
  Future<bool> sendMessage({
    required String chatId,
    required String senderUserId,
    required String content,
    String? senderPetId,
  }) async {
    try {
      final blockedUserIds = await getBlockedUserIds(senderUserId);
      if (blockedUserIds.isNotEmpty) {
        final chatRes = await _supabase
            .from('love_chats')
            .select('''
              pet_a:pet_a_id(user_id),
              pet_b:pet_b_id(user_id)
            ''')
            .eq('id', chatId)
            .maybeSingle();

        if (chatRes != null) {
          final petAUser = chatRes['pet_a']?['user_id'] as String?;
          final petBUser = chatRes['pet_b']?['user_id'] as String?;
          if ((petAUser != null &&
                  blockedUserIds.contains(petAUser) &&
                  petAUser != senderUserId) ||
              (petBUser != null &&
                  blockedUserIds.contains(petBUser) &&
                  petBUser != senderUserId)) {
            print('Envio de mensagem bloqueado devido a restrição de usuário.');
            return false;
          }
        }
      }

      await _supabase.from('love_messages').insert({
        'chat_id': chatId,
        'sender_user_id': senderUserId,
        'content': content.trim(),
      });

      // Atualiza timestamp do chat para ordenação
      await _supabase
          .from('love_chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      // Notifica o participante do chat
      _sendLoveMessageNotification(
        chatId: chatId,
        senderUserId: senderUserId,
        senderPetId: senderPetId,
        messageContent: content,
      );

      return true;
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      return false;
    }
  }

  /// Dispara notificação de nova mensagem no chat do Patas Love
  Future<void> _sendLoveMessageNotification({
    required String chatId,
    required String senderUserId,
    String? senderPetId,
    required String messageContent,
  }) async {
    try {
      final chatRes = await _supabase
          .from('love_chats')
          .select('''
            pet_a:pet_a_id(id, name, user_id),
            pet_b:pet_b_id(id, name, user_id)
          ''')
          .eq('id', chatId)
          .maybeSingle();

      if (chatRes == null) return;

      final petA = chatRes['pet_a'];
      final petB = chatRes['pet_b'];

      String? recipientUserId;
      String senderPetName = 'Alguém';

      if (petA != null && petA['user_id'] != senderUserId) {
        recipientUserId = petA['user_id'];
        senderPetName = petB?['name'] ?? 'Alguém';
      } else if (petB != null && petB['user_id'] != senderUserId) {
        recipientUserId = petB['user_id'];
        senderPetName = petA?['name'] ?? 'Alguém';
      }

      if (recipientUserId == null) return;

      await SupabaseNotificationService().sendNotification(
        receiverUserId: recipientUserId,
        senderPetId: senderPetId,
        type: NotificationType.system,
        title: '💬 Nova mensagem de $senderPetName',
        content: messageContent,
        data: {
          'type': 'love_chat_message',
          'chat_id': chatId,
        },
      );
    } catch (e) {
      print('Erro ao enviar notificação de mensagem do Patas Love: $e');
    }
  }

  /// Bloqueia um tutor
  Future<bool> blockUser({required String blockerId, required String blockedId}) async {
    try {
      await _supabase.from('love_blocks').insert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
      });
      return true;
    } catch (e) {
      print('Erro ao bloquear usuário: $e');
      return false;
    }
  }

  /// Registra uma denúncia contra um usuário/tutor
  Future<bool> reportUser({
    required String reporterId,
    required String reportedUserId,
    String? reportedPetId,
    required String reason,
    String? details,
  }) async {
    try {
      await _supabase.from('love_reports').insert({
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        if (reportedPetId != null) 'reported_pet_id': reportedPetId,
        'reason': reason,
        'details': details ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Erro ao registrar denúncia: $e');
      return true;
    }
  }

  /// Desbloqueia um tutor
  Future<bool> unblockUser({required String blockerId, required String blockedId}) async {
    try {
      await _supabase
          .from('love_blocks')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId);
      return true;
    } catch (e) {
      print('Erro ao desbloquear usuário: $e');
      return false;
    }
  }

  /// Obtém a lista de usuários/tutores bloqueados
  Future<List<Map<String, dynamic>>> getBlockedUsers(String userId) async {
    try {
      final blocks = await _supabase
          .from('love_blocks')
          .select('id, blocked_id, created_at')
          .eq('blocker_id', userId);

      final List<Map<String, dynamic>> result = [];
      for (var block in (blocks as List)) {
        final blockedId = block['blocked_id'] as String;
        final userRes = await _supabase
            .from('users')
            .select('id, name, photo_url, email')
            .eq('id', blockedId)
            .maybeSingle();

        final petRes = await _supabase
            .from('pets')
            .select('id, name, photo_url')
            .eq('user_id', blockedId)
            .limit(1)
            .maybeSingle();

        result.add({
          'block_id': block['id'],
          'blocked_id': blockedId,
          'user_name': userRes?['name'] ?? petRes?['name'] ?? 'Tutor Bloqueado',
          'user_photo': userRes?['photo_url'] ?? petRes?['photo_url'],
          'pet_name': petRes?['name'],
          'created_at': block['created_at'],
        });
      }

      return result;
    } catch (e) {
      print('Erro ao obter usuários bloqueados: $e');
      return [];
    }
  }
  /// 1. Propor um encontro presencial com Data, Hora, Local e Observações
  Future<bool> proposeMeeting({
    required String chatId,
    required String proposedByUserId,
    required String requesterPetName,
    required DateTime meetingDate,
    required String location,
    String? notes,
  }) async {
    try {
      await _supabase.from('love_chats').update({
        'status': 'meeting_proposed',
        'meeting_proposed_by': proposedByUserId,
        'meeting_date': meetingDate.toIso8601String(),
        'meeting_location': location,
        'meeting_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      // Notifica o outro tutor
      final chatRes = await _supabase
          .from('love_chats')
          .select('pet_a:pet_a_id(name, user_id), pet_b:pet_b_id(name, user_id)')
          .eq('id', chatId)
          .single();

      final petA = chatRes['pet_a'];
      final petB = chatRes['pet_b'];

      String? recipientUserId;
      if (petA != null && petA['user_id'] != proposedByUserId) {
        recipientUserId = petA['user_id'] as String?;
      } else if (petB != null && petB['user_id'] != proposedByUserId) {
        recipientUserId = petB['user_id'] as String?;
      }

      if (recipientUserId != null) {
        final dateFormatted =
            '${meetingDate.day.toString().padLeft(2, '0')}/${meetingDate.month.toString().padLeft(2, '0')} às ${meetingDate.hour.toString().padLeft(2, '0')}:${meetingDate.minute.toString().padLeft(2, '0')}';
        await SupabaseNotificationService().sendNotification(
          receiverUserId: recipientUserId,
          senderPetId: null,
          type: NotificationType.system,
          title: '🗓️ Proposta de Encontro Pet!',
          content:
              '$requesterPetName propôs um encontro no dia $dateFormatted em $location. Abra o chat para responder!',
          data: {'type': 'love_meeting_proposed', 'chat_id': chatId},
        );
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao propor encontro: $e');
      return false;
    }
  }

  /// 2. Aceitar ou recusar/reagendar a proposta de encontro
  Future<bool> respondMeetingProposal({
    required String chatId,
    required bool accepted,
  }) async {
    try {
      if (accepted) {
        await _supabase.from('love_chats').update({
          'status': 'meeting_scheduled',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', chatId);
      } else {
        await _supabase.from('love_chats').update({
          'status': 'active',
          'meeting_proposed_by': null,
          'meeting_date': null,
          'meeting_location': null,
          'meeting_notes': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', chatId);
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao responder proposta de encontro: $e');
      return false;
    }
  }

  /// 3. Marcar encontro como realizado (gera marco afetivo em love_meets)
  Future<bool> markMeetingAsCompleted({
    required String chatId,
    required String petAId,
    required String petBId,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      // 1. Atualiza status do chat
      await _supabase.from('love_chats').update({
        'status': 'met_in_person',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      // 2. Registra marco afetivo em love_meets
      await _supabase.from('love_meets').upsert({
        'chat_id': chatId,
        'pet_a_id': petAId,
        'pet_b_id': petBId,
        'confirmed_at': DateTime.now().toIso8601String(),
        'photo_url': photoUrl,
        'notes': notes,
      }, onConflict: 'chat_id');

      // 3. Notifica ambos os tutores
      final chatRes = await _supabase
          .from('love_chats')
          .select('pet_a:pet_a_id(name, user_id), pet_b:pet_b_id(name, user_id)')
          .eq('id', chatId)
          .single();

      final petAData = chatRes['pet_a'];
      final petBData = chatRes['pet_b'];
      final petAName = petAData?['name'] ?? 'Seu pet';
      final petBName = petBData?['name'] ?? 'Seu pet';
      final petAUserId = petAData?['user_id'] as String?;
      final petBUserId = petBData?['user_id'] as String?;

      for (final uid in [petAUserId, petBUserId]) {
        if (uid != null) {
          await SupabaseNotificationService().sendNotification(
            receiverUserId: uid,
            senderPetId: null,
            type: NotificationType.system,
            title: '🎉 Encontro Realizado!',
            content: '$petAName e $petBName se encontraram! O momento foi registrado na Linha do Tempo 💕',
            data: {'type': 'love_meet_completed', 'chat_id': chatId},
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao marcar encontro como realizado: $e');
      return false;
    }
  }

  /// Retorna os detalhes de agendamento e status do encontro
  Future<Map<String, dynamic>?> getMeetingDetails(String chatId) async {
    try {
      final res = await _supabase
          .from('love_chats')
          .select('status, meeting_proposed_by, meeting_date, meeting_location, meeting_notes')
          .eq('id', chatId)
          .maybeSingle();
      return res != null ? Map<String, dynamic>.from(res) : null;
    } catch (e) {
      debugPrint('Erro ao buscar detalhes do encontro: $e');
      return null;
    }
  }

  /// Retorna o status atual do chat (compatibilidade)
  Future<Map<String, dynamic>?> getMeetStatus(String chatId) async {
    return getMeetingDetails(chatId);
  }

  /// Retorna a lista de encontros confirmados em que o pet participou (como pet_a ou pet_b).
  Future<List<Map<String, dynamic>>> getConfirmedMeetsForPet(String petId) async {
    try {
      final res = await _supabase
          .from('love_meets')
          .select('''
            id,
            chat_id,
            pet_a_id,
            pet_b_id,
            confirmed_at,
            photo_url,
            notes,
            pet_a:pet_a_id(id, name, breed, species, photo_url),
            pet_b:pet_b_id(id, name, breed, species, photo_url)
          ''')
          .or('pet_a_id.eq.$petId,pet_b_id.eq.$petId')
          .order('confirmed_at', ascending: true);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Erro ao buscar encontros confirmados do pet: $e');
      return [];
    }
  }
}
