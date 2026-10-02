import '../../../../main.dart'; // Para acesso ao supabase global

class UserDatabaseService {
  /// Atualiza o token FCM do usuário no banco de dados
  Future<void> updateFCMToken(String userId, String token) async {
    try {
      await supabase.from('users').update({
        'fcm_token': token,
        'fcm_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      // Log silencioso ou rethrow dependendo da estratégia de erro
      throw Exception('Erro ao atualizar FCM Token: $e');
    }
  }

  /// Updates the preferred notification sound key for the user (for Push Notifications)
  Future<void> updateNotificationSound(String userId, String soundKey) async {
    try {
      await supabase.from('users').update({
        'notification_sound_key': soundKey,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Erro ao atualizar Som de Notificação: $e');
    }
  }

  /// Limpa o token FCM (usar no Logout)
  Future<void> clearFCMToken(String userId) async {
    try {
      await supabase.from('users').update({
        'fcm_token': null,
        'fcm_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Erro ao limpar FCM Token: $e');
    }
  }
}
