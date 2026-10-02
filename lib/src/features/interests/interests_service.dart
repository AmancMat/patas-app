import 'package:flutter/foundation.dart';
import 'package:patas_web_app/main.dart';

/// Serviço responsável por salvar e recuperar os interesses do usuário
/// na tabela `users` do Supabase (campo JSONB `interests`).
class InterestsService {
  /// Salva os interesses do usuário autenticado.
  /// [interests] é um mapa do tipo:
  /// ```json
  /// {
  ///   "species": ["canino", "felino"],
  ///   "content_types": ["fotos", "saude"],
  ///   "pet_profile": ["filhote", "calmo"],
  ///   "prefer_local": true
  /// }
  /// ```
  Future<void> saveInterests(Map<String, dynamic> interests) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
          .from('users')
          .update({'interests': interests})
          .eq('id', userId);
    } catch (e) {
      debugPrint('InterestsService.saveInterests error: $e');
      rethrow;
    }
  }

  /// Recupera os interesses do usuário autenticado.
  /// Retorna `null` se não houver interesses salvos.
  Future<Map<String, dynamic>?> getInterests() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await supabase
          .from('users')
          .select('interests')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      final raw = response['interests'];
      if (raw == null || raw is! Map) return null;
      return Map<String, dynamic>.from(raw);
    } catch (e) {
      debugPrint('InterestsService.getInterests error: $e');
      return null;
    }
  }

  /// Verifica se o usuário já concluiu ou pulou o questionário de interesses.
  /// Considera "concluído" quando o campo `interests` não é nulo/vazio.
  Future<bool> hasCompletedQuestionnaire() async {
    final interests = await getInterests();
    return interests != null && interests.isNotEmpty;
  }
}
