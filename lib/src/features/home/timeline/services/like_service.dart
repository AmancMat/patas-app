import 'package:flutter/foundation.dart';
import 'package:patas_web_app/src/models/notification_model.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../main.dart';

class LikeService {
  /// Toggle like status for a post or story. Returns true if liked, false if unliked.
  Future<bool> toggleLike(String contentId,
      {String? senderPetId, bool isStory = false}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Check if already liked
      final liked = await isLiked(contentId, isStory: isStory);

      if (liked) {
        // Unlike
        await supabase
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq(isStory ? 'story_id' : 'post_id', contentId);

        return false;
      } else {
        // Like
        await supabase.from('likes').insert({
          'user_id': user.id,
          isStory ? 'story_id' : 'post_id': contentId,
        });

        // Enviar notificação para o dono
        _sendLikeNotification(contentId, senderPetId, isStory: isStory);

        // [PATAS REWARDS] Pontos de gamificação para like são concedidos
        // automaticamente pela trigger 'handle_gamification' no banco de dados.

        return true;
      }
    } catch (e) {
      debugPrint('LikeService: Erro ao alternar like: $e');
      rethrow;
    }
  }

  /// Check if the current user has liked a post or story
  Future<bool> isLiked(String contentId, {bool isStory = false}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final response = await supabase
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq(isStory ? 'story_id' : 'post_id', contentId)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('LikeService: Erro ao verificar like: $e');
      return false;
    }
  }

  /// Get total likes for a post or story
  Future<int> getLikeCount(String contentId, {bool isStory = false}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 0; // Evita requisição ao banco se o usuário estiver deslogado (onboarding)

      final response = await supabase
          .from('likes')
          .count(CountOption.exact)
          .eq(isStory ? 'story_id' : 'post_id', contentId);

      return response;
    } catch (e) {
      debugPrint('LikeService: Erro ao contar likes: $e');
      return 0;
    }
  }

  /// Método privado para enviar notificação de like
  Future<void> _sendLikeNotification(String contentId, String? senderPetId,
      {bool isStory = false}) async {
    try {
      final String table = isStory ? 'stories' : 'posts';

      final contentResponse = await supabase
          .from(table)
          .select('user_id')
          .eq('id', contentId)
          .maybeSingle();

      if (contentResponse == null) return;

      final postOwnerId = contentResponse['user_id'];
      if (postOwnerId == null) return;

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Busca o nome do autor (pet ou usuário)
      String senderName = 'Alguém';
      if (senderPetId != null) {
        final petRes = await supabase
            .from('pets')
            .select('name')
            .eq('id', senderPetId)
            .single();
        senderName = petRes['name'] ?? 'Alguém';
      } else {
        // Fallback: busca o nome do usuário atual (ou o primeiro pet dele)
        final userRes = await supabase
            .from('tutor_profiles')
            .select('name')
            .eq('id', currentUser.id)
            .single();
        senderName = userRes['name'] ?? 'Alguém';
      }

      await SupabaseNotificationService().sendNotification(
        receiverUserId: postOwnerId,
        senderPetId: senderPetId,
        type: NotificationType.like,
        title: 'Novo like!',
        content: '$senderName curtiu sua publicação.',
        data: {
          isStory ? 'story_id' : 'post_id': contentId,
        },
      );
    } catch (e) {
      debugPrint('LikeService: Erro ao enviar notificação: $e');
    }
  }
}
