import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../main.dart';

class GamificationService {
  /// Registra pontos no livro-razão (gamification_ledger) caso o limite diário não tenha sido atingido.
  /// Retorna [true] se os pontos foram creditados, [false] se atingiu o limite ou erro.
  Future<bool> awardEngagementPoints({
    required String action,
    required int points,
    required int maxDaily,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // 1. Verificar quantas ações deste tipo o usuário já fez hoje
      final todayStart = DateTime.now()
          .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)
          .toUtc()
          .toIso8601String();
      final todayEnd = DateTime.now()
          .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999)
          .toUtc()
          .toIso8601String();

      final countResponse = await supabase
          .from('gamification_ledger')
          .count(CountOption.exact)
          .eq('user_id', user.id)
          .eq('action_type', action)
          .gte('created_at', todayStart)
          .lte('created_at', todayEnd);

      final currentCount = countResponse;

      if (currentCount >= maxDaily) {
        debugPrint(
            'GamificationService: Limite diário de $maxDaily atingido para a ação $action.');
        return false;
      }

      // 2. Gravar os pontos no Ledger
      await supabase.from('gamification_ledger').insert({
        'user_id': user.id,
        'action_type': action,
        'points': points,
      });

      debugPrint(
          'GamificationService: $points pontos computados para $action! (${currentCount + 1}/$maxDaily)');
      return true;
    } catch (e) {
      debugPrint('GamificationService: Erro ao registrar pontos: $e');
      return false;
    }
  }

  /// Remove o registro de pontos mais recente do usuário para uma determinada ação.
  /// Usado ao desfazer ações como "unlike" ou deletar comentários.
  Future<bool> removeEngagementPoints({
    required String action,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // 1. Busca o registro mais recente desse tipo de ação para o usuário
      final response = await supabase
          .from('gamification_ledger')
          .select('id')
          .eq('user_id', user.id)
          .eq('action_type', action)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint(
            'GamificationService: Nenhum registro de pontos encontrado para remover para a ação $action.');
        return false;
      }

      final recordId = response['id'];

      // 2. Deleta o registro pelo ID
      await supabase
          .from('gamification_ledger')
          .delete()
          .eq('id', recordId);

      debugPrint(
          'GamificationService: Registro de pontos ($recordId) removido para a ação $action.');
      return true;
    } catch (e) {
      debugPrint('GamificationService: Erro ao remover pontos: $e');
      return false;
    }
  }

  /// Registra pontos únicos (One Time Only), como "Perfil Completo".
  Future<bool> awardOneTimePoints({
    required String action,
    required int points,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // Verifica se a ação já foi realizada alguma vez na vida do usuário
      final response = await supabase
          .from('gamification_ledger')
          .select('id')
          .eq('user_id', user.id)
          .eq('action_type', action)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        debugPrint(
            'GamificationService: Ação única \$action já computada anteriormente.');
        return false; // Já fez, não ganha de novo
      }

      // 2. Gravar os pontos no Ledger
      await supabase.from('gamification_ledger').insert({
        'user_id': user.id,
        'action_type': action,
        'points': points,
      });

      debugPrint(
          'GamificationService: \$points pontos únicos computados para \$action!');
      return true;
    } catch (e) {
      debugPrint('GamificationService: Erro ao registrar pontos únicos: \$e');
      return false;
    }
  }

  /// Processa o código de convite (referral) após o sucesso do cadastro
  Future<bool> processReferral({
    required String newUserId,
    required String referralCode,
  }) async {
    try {
      if (referralCode.trim().isEmpty) return false;

      // 1. Encontra quem é o dono desse código (buscando pelo início do ID)
      // O ilike faz uma busca case-insensitive no ID convertido para texto.
      final inviterResponse = await supabase
          .from('tutor_profiles')
          .select('id')
          .ilike('id::text', '\${referralCode.trim()}%')
          .limit(1)
          .maybeSingle();

      if (inviterResponse == null) {
        debugPrint('GamificationService: Código de convite \$referralCode não encontrado.');
        return false;
      }

      final inviterId = inviterResponse['id'] as String;

      // Segurança básica: não pode convidar a si mesmo
      if (inviterId == newUserId) return false;

      // 2. Registra o vínculo na tabela 'referrals'
      try {
        await supabase.from('referrals').insert({
          'inviter_id': inviterId,
          'invited_id': newUserId,
        });
      } catch (e) {
        debugPrint('GamificationService: Referral já existe ou erro ao inserir: \$e');
        return false;
      }

      // 3. Deposita 500 pontos (prêmio alto) para o dono do código
      await supabase.from('gamification_ledger').insert({
        'user_id': inviterId,
        'action_type': 'referral_success',
        'points': 500,
      });

      debugPrint('GamificationService: Sucesso! 500 pontos dados para o inviter \$inviterId');
      return true;
    } catch (e) {
      debugPrint('GamificationService: Erro crítico ao processar referral: \$e');
      return false;
    }
  }

  /// Busca o saldo total e a posição no ranking do usuário logado
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Consulta a view do Supabase que já calcula os pontos e o rank
      final response = await supabase
          .from('leaderboard_view')
          .select('total_points, rank')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return {
          'points': int.tryParse(response['total_points'].toString()) ?? 0,
          'rank': int.tryParse(response['rank'].toString()) ?? 0,
        };
      }
      
      // Fallback seguro: se a view retornar null para o usuário ativo (ex: view vazia),
      // faz a soma manual da tabela ledger para que o usuário não fique zerado na UI.
      return await _getUserStatsFallback(userId);
    } catch (e) {
      debugPrint('GamificationService: Erro ao buscar stats na view: $e');
      return await _getUserStatsFallback(userId);
    }
  }

  /// Método privado para calcular a soma dos pontos manualmente na tabela ledger
  Future<Map<String, dynamic>> _getUserStatsFallback(String userId) async {
    try {
      final sumResponse = await supabase
          .from('gamification_ledger')
          .select('points')
          .eq('user_id', userId);
      
      int total = 0;
      for (var row in sumResponse) {
        total += int.tryParse(row['points'].toString()) ?? 0;
      }
      return {'points': total, 'rank': 0};
    } catch (fallbackError) {
      debugPrint('GamificationService: Erro no fallback: $fallbackError');
      return {'points': 0, 'rank': 0};
    }
  }

  /// Busca os 15 melhores colocados no ranking a partir de leaderboard_view
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await supabase
          .from('leaderboard_view')
          .select('user_id, total_points, rank, pet_name, pet_photo_url')
          .order('rank', ascending: true)
          .limit(15);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GamificationService: Erro ao buscar leaderboard: $e');
      return [];
    }
  }

  /// Busca todos os patrocinadores/prêmios ativos no momento
  Future<List<Map<String, dynamic>>> getSponsors() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await supabase
          .from('sponsors')
          .select('id, name, logo_url, prize_title, prize_description, prize_rules, target_link')
          .eq('is_active', true)
          .gt('ends_at', now)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GamificationService: Erro ao buscar patrocinadores: $e');
      
      // Fallback estático para que o app nunca fique em branco ou quebre
      return [
        {
          'id': 'fallback-1',
          'name': 'Patas Oficial',
          'logo_url': null,
          'prize_title': 'Voucher de Viagem Pet Friendly! ✈️',
          'prize_description': 'Ganhe uma viagem de fim de semana com tudo pago para você e seu pet em um dos melhores chalés Pet Friendly cadastrados no nosso guia!',
          'prize_rules': '1. O prêmio é intransferível e tem validade de 6 meses.\n2. Válido para o tutor e até 2 pets de qualquer porte.\n3. O resgate deve ser combinado com a administração do app.',
          'target_link': 'https://patas.online',
        }
      ];
    }
  }
}
