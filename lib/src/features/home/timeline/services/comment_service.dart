import 'package:flutter/foundation.dart';
import 'package:patas_web_app/src/features/home/timeline/models/comment_model.dart';
import 'package:patas_web_app/src/models/notification_model.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../main.dart';

class CommentService {
  Future<List<Comment>> getComments(String postId, {bool isStory = false}) async {
    try {
      final response = await supabase
          .from('comments')
          .select(
              '*, tutor_profiles(name, photo_url), pets(name, photo_url)')
          .eq(isStory ? 'story_id' : 'post_id', postId)
          .order('created_at', ascending: true);

      final List<Comment> comments =
          (response as List).map((item) => Comment.fromJson(item)).toList();

      return comments;
    } catch (e) {
      debugPrint('CommentService: Erro ao buscar comentários: $e');
      return [];
    }
  }

  Future<Comment?> addComment(String postId, String content, String? petId,
      {bool isStory = false}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final response = await supabase
          .from('comments')
          .insert({
            'user_id': user.id,
            'pet_id': petId, // Opcional, pode ser nulo se não tiver pet ativo
            isStory ? 'story_id' : 'post_id': postId,
            'content': content,
          })
          .select('*, tutor_profiles(name, photo_url), pets(name, photo_url)')
          .single();

      final comment = Comment.fromJson(response);

      // Enviar notificação para o dono do post
      try {
        final String table = isStory ? 'stories' : 'posts';
        final postResponse = await supabase
            .from(table)
            .select('user_id')
            .eq('id', postId)
            .single();

        final postOwnerId = postResponse['user_id'];

        if (postOwnerId != null) {
          final notificationService = SupabaseNotificationService();
          final senderName = comment.senderName ?? 'Alguém';

          await notificationService.sendNotification(
            receiverUserId: postOwnerId,
            senderPetId: petId,
            type: NotificationType.comment,
            title: 'Novo comentário!',
            content: '$senderName comentou na sua publicação: "$content"',
            data: {
              isStory ? 'story_id' : 'post_id': postId,
              'comment_id': comment.id,
            },
          );
        }
      } catch (e) {
        debugPrint('CommentService: Erro ao enviar notificação: $e');
      }

      // [PATAS REWARDS] Pontos de gamificação para comentário são concedidos
      // automaticamente pela trigger 'handle_gamification' no banco de dados.

      return comment;
    } catch (e) {
      debugPrint('CommentService: Erro ao adicionar comentário: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await supabase.from('comments').delete().eq('id', commentId);

      // [PATAS REWARDS] Remoção de pontos ao deletar comentário é gerenciada
      // pela trigger 'handle_gamification_delete' no banco de dados.
    } catch (e) {
      debugPrint('CommentService: Erro ao deletar comentário: $e');
      rethrow;
    }
  }

  Future<int> getCommentCount(String postId, {bool isStory = false}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 0; // Evita requisição ao banco se o usuário estiver deslogado (onboarding)

      final response = await supabase
          .from('comments')
          .count(CountOption.exact)
          .eq(isStory ? 'story_id' : 'post_id', postId);
      return response;
    } catch (e) {
      debugPrint('CommentService: Erro ao contar comentários: $e');
      return 0;
    }
  }
}
