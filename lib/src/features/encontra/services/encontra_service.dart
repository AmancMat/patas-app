import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class EncontraService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> activateTag({
    required String tagUuid,
    required String pin,
    required String petId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Usuario nao autenticado.'};
      }

      // 1. Busca pela tag usando a coluna correta 'pin_code'
      final tagResponse = await _client
          .from('tags')
          .select()
          .eq('id', tagUuid)
          .eq('pin_code', pin)
          .maybeSingle();
      if (tagResponse == null) {
        return {
          'success': false,
          'message':
              'QR Code ou PIN incorretos. Verifique os dados e tente novamente.',
        };
      }
      // Verifica se a tag já está vinculada a algum pet
      if (tagResponse['pet_id'] != null) {
        if (tagResponse['pet_id'] == petId) {
          return {
            'success': false,
            'message': 'Esta tag já está ativa e vinculada a este pet.',
          };
        } else {
          return {
            'success': false,
            'message': 'Esta tag já está vinculada a outro pet.',
          };
        }
      }
      // Verifica se já está ativa por outro tutor (segurança secundária)
      if (tagResponse['status'] == 'active' &&
          tagResponse['tutor_id'] != null &&
          tagResponse['tutor_id'] != user.id) {
        return {
          'success': false,
          'message': 'Esta tag já está vinculada a outro tutor.',
        };
      }
      // Verifica se o pet já possui outra tag ativa
      final existingTag = await _client
          .from('tags')
          .select('id')
          .eq('pet_id', petId)
          .eq('status', 'active')
          .maybeSingle();
      if (existingTag != null && existingTag['id'] != tagUuid) {
        return {
          'success': false,
          'message':
              'Este pet já possui uma tag ativa. Desative a antiga antes de ativar uma nova.',
        };
      }

      // 2. Cria a assinatura Trial de 14 dias se o pet não possuir assinatura
      var subscription = await _client
          .from('subscriptions')
          .select()
          .eq('pet_id', petId)
          .maybeSingle();

      if (subscription == null) {
        final plan = await _client
            .from('subscription_plans')
            .select()
            .eq('is_active', true)
            .limit(1)
            .maybeSingle();
        
        if (plan != null) {
          final now = DateTime.now();
          subscription = await _client
              .from('subscriptions')
              .insert({
                'user_id': user.id,
                'pet_id': petId,
                'plan_id': plan['id'],
                'status': 'trial',
                'trial_started_at': now.toIso8601String(),
                'trial_ends_at': now.add(const Duration(days: 14)).toIso8601String(),
              })
              .select()
              .single();
        }
      }

      // 3. Atualiza os dados da tag no banco de dados
      await _client
          .from('tags')
          .update({
            'tutor_id': user.id,
            'pet_id': petId,
            'activated_at': DateTime.now().toIso8601String(),
            'status': 'active',
            'is_lost': false,
          })
          .eq('id', tagUuid);
      debugPrint('EncontraService: Tag $tagUuid ativada para o pet $petId.');
      return {'success': true, 'message': 'Tag ativada com sucesso!'};
    } on PostgrestException catch (e) {
      debugPrint('EncontraService (Postgrest): ${e.message}');
      return {
        'success': false,
        'message': 'Erro no banco de dados: ${e.message}',
      };
    } catch (e) {
      debugPrint('EncontraService (Erro geral): $e');
      return {
        'success': false,
        'message': 'Ocorreu um erro inesperado. Tente novamente.',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getMyTags() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('EncontraService.getMyTags: Usuário é nulo.');
        return [];
      }
      debugPrint(
        'EncontraService.getMyTags: Buscando tags para tutor_id = ${user.id}',
      );
      final response = await _client
          .from('tags')
          .select('*, pets(name, species, photo_url, breed)')
          .eq('tutor_id', user.id)
          .not('activated_at', 'is', null)
          .order('activated_at', ascending: false);
      debugPrint('EncontraService.getMyTags: Supabase retornou: $response');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('EncontraService.getMyTags ERRO: $e');
      return [];
    }
  }

  Future<bool> toggleLostMode({
    required String tagId,
    required bool isLost,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;
      await _client
          .from('tags')
          .update({'is_lost': isLost})
          .eq('id', tagId)
          .eq('tutor_id', user.id);
      debugPrint('EncontraService: Modo perdido da tag $tagId = $isLost');
      return true;
    } catch (e) {
      debugPrint('EncontraService.toggleLostMode: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMySightings() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];
      final tagsRaw = await _client
          .from('tags')
          .select('id')
          .eq('tutor_id', user.id);
      final tags = tagsRaw as List;
      if (tags.isEmpty) return [];
      final tagIds = tags.map((t) => t['id'] as String).toList();
      final response = await _client
          .from('sightings')
          .select('*, tags(id, pets(name, photo_url))')
          .inFilter('tag_id', tagIds)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('EncontraService.getMySightings: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPublicTagInfo(String tagId) async {
    try {
      final response = await _client
          .from('tags')
          .select('is_lost, pets(name, species, photo_url, breed)')
          .eq('id', tagId)
          .not('activated_at', 'is', null)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('EncontraService.getPublicTagInfo: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getLostPets() async {
    try {
      final response = await _client
          .from('tags')
          .select('id, is_lost, pet_id, pets(id, name, species, photo_url, breed)')
          .eq('is_lost', true)
          .not('activated_at', 'is', null)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('EncontraService.getLostPets ERRO: $e');
      rethrow;
    }
  }

  /// Retorna tags que ainda não foram ativadas (para fins de simulação/teste)
  Future<List<Map<String, dynamic>>> getAvailableTags() async {
    try {
      final response = await _client
          .from('tags')
          .select('id, pin_code')
          .eq('status', 'inactive')
          .limit(20);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('EncontraService.getAvailableTags: $e');
      return [];
    }
  }

  Future<bool> saveSighting({
    required String tagId,
    required double latitude,
    required double longitude,
    String? message,
    String? finderName,
  }) async {
    try {
      debugPrint('Tentando salvar sighting para tag: $tagId');

      // Busca o endereço amigável via Nominatim (OpenStreetMap)
      String? address;
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1'
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'PatasEncontraApp/1.2.5 (contact: mateus_amancio@outlook.com)',
        });
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          address = data['display_name'] as String?;
        }
      } catch (e) {
        debugPrint('Erro ao obter endereço via Nominatim: $e');
      }

      // Faz o INSERT direto — a validação de assinatura e de tag ativa
      // é feita pelo trigger do banco de dados (check_sighting_subscription).
      // O usuário anônimo não tem permissão de SELECT em tags/subscriptions,
      // por isso toda validação de negócio deve ficar no servidor.
      await _client.from('sightings').insert({
        'tag_id': tagId,
        'latitude': latitude,
        'longitude': longitude,
        'message': message,
        'finder_name': finderName,
        'address': address,
      });

      debugPrint('✅ Avistamento salvo com sucesso para tag $tagId');
      return true;
    } catch (e) {
      debugPrint('❌ ERRO AO SALVAR SIGHTING: $e');

      if (e is PostgrestException) {
        debugPrint('Código: ${e.code}');
        debugPrint('Mensagem: ${e.message}');
      }

      return false;
    }
  }

  Future<Map<String, dynamic>?> getMySubscription({String? petId}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      
      var query = _client
          .from('subscriptions')
          .select('*, subscription_plans(name, price_in_cents)');
          
      if (petId != null) {
        query = query.eq('pet_id', petId);
      } else {
        query = query.eq('user_id', user.id);
      }
      
      final sub = await query.maybeSingle();
      return sub;
    } catch (e) {
      debugPrint('EncontraService.getMySubscription ERRO: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMySubscriptions() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];
      
      final subs = await _client
          .from('subscriptions')
          .select('*, subscription_plans(name, price_in_cents)')
          .eq('user_id', user.id);
      
      return List<Map<String, dynamic>>.from(subs as List);
    } catch (e) {
      debugPrint('EncontraService.getMySubscriptions ERRO: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMyInvoices({String? subscriptionId}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];
      
      var query = _client.from('invoices').select();
      
      if (subscriptionId != null) {
        query = query.eq('subscription_id', subscriptionId);
      } else {
        query = query.eq('user_id', user.id);
      }
      
      final invoices = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(invoices as List);
    } catch (e) {
      debugPrint('EncontraService.getMyInvoices ERRO: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> deactivateTag({
    required String tagId,
    required String petId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Usuário não autenticado.'};
      }

      // Executa a operação atômica e segura no banco de dados via RPC (ignora RLS do cliente)
      await _client.rpc(
        'deactivate_tag_safe',
        params: {
          'tag_uuid': tagId,
          'pet_uuid': petId,
        },
      );

      debugPrint('EncontraService: Tag $tagId desvinculada do pet $petId via RPC.');
      return {'success': true, 'message': 'Tag desvinculada com sucesso!'};
    } catch (e) {
      debugPrint('EncontraService.deactivateTag ERRO: $e');
      return {'success': false, 'message': 'Erro ao desvincular a tag: $e'};
    }
  }
}
