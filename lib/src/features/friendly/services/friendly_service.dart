import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friendly_place_model.dart';
import '../models/friendly_review_model.dart';

class FriendlyService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Retorna todos os locais pet-friendly ativos cadastrados no Supabase
  Future<List<FriendlyPlace>> getFriendlyPlaces() async {
    try {
      List<dynamic> listData = [];
      try {
        final response = await _client
            .from('friendly_places')
            .select('*, tutor_profiles(name, photo_url)')
            .eq('is_active', true)
            .order('created_at', ascending: false);
        listData = response as List;
      } on PostgrestException catch (e) {
        debugPrint('FriendlyService.getFriendlyPlaces (join falhou, usando fallback): ${e.message}');
        final rawResponse = await _client
            .from('friendly_places')
            .select('*')
            .eq('is_active', true)
            .order('created_at', ascending: false);

        final rawList = List<Map<String, dynamic>>.from(rawResponse as List);
        final userIds = rawList
            .map((p) => p['user_id'] as String?)
            .where((id) => id != null && id.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        Map<String, Map<String, dynamic>> tutorsMap = {};
        if (userIds.isNotEmpty) {
          try {
            final tutorsResponse = await _client
                .from('tutor_profiles')
                .select('id, name, photo_url')
                .filter('id', 'in', userIds);
            for (var t in tutorsResponse as List) {
              tutorsMap[t['id'] as String] = Map<String, dynamic>.from(t);
            }
          } catch (te) {
            debugPrint('FriendlyService.getFriendlyPlaces (fallback tutor_profiles erro): $te');
          }
        }

        listData = rawList.map((p) {
          final uid = p['user_id'] as String?;
          if (uid != null && tutorsMap.containsKey(uid)) {
            p['tutor_profiles'] = tutorsMap[uid];
          }
          return p;
        }).toList();
      }

      return listData
          .map((json) => FriendlyPlace.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('FriendlyService.getFriendlyPlaces (Postgrest): ${e.message}');
      return [];
    } catch (e) {
      debugPrint('FriendlyService.getFriendlyPlaces (Erro geral): $e');
      return [];
    }
  }

  /// Retorna as avaliações de um local específico, incluindo o perfil público (tutor_profiles) do autor
  Future<List<FriendlyReview>> getReviewsForPlace(String placeId) async {
    try {
      final response = await _client
          .from('friendly_reviews')
          .select('*, tutor_profiles(name, photo_url)')
          .eq('place_id', placeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendlyReview.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('FriendlyService.getReviewsForPlace (Postgrest): ${e.message}');
      return [];
    } catch (e) {
      debugPrint('FriendlyService.getReviewsForPlace (Erro geral): $e');
      return [];
    }
  }

  /// Adiciona ou atualiza uma avaliação feita pelo usuário logado
  Future<Map<String, dynamic>> addReview({
    required String placeId,
    required int rating,
    required String comment,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Você precisa estar autenticado para avaliar.'};
      }

      await _client.from('friendly_reviews').upsert({
        'place_id': placeId,
        'user_id': user.id,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {'success': true, 'message': 'Avaliação registrada com sucesso!'};
    } on PostgrestException catch (e) {
      debugPrint('FriendlyService.addReview (Postgrest): ${e.message}');
      return {
        'success': false,
        'message': 'Erro ao salvar avaliação: ${e.message}',
      };
    } catch (e) {
      debugPrint('FriendlyService.addReview (Erro geral): $e');
      return {
        'success': false,
        'message': 'Ocorreu um erro ao enviar sua avaliação. Tente novamente.',
      };
    }
  }

  /// Salva as coordenadas do polígono de restrição pet na tabela friendly_places
  Future<bool> updatePlacePolygon(String placeId, List<LatLng> points) async {
    try {
      final serialized = points
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();
      
      await _client
          .from('friendly_places')
          .update({'boundary_polygon': serialized})
          .eq('id', placeId);
      
      return true;
    } catch (e) {
      debugPrint('FriendlyService.updatePlacePolygon (Erro): $e');
      return false;
    }
  }

  /// Insere uma sugestão de local pet friendly na tabela friendly_places
  Future<Map<String, dynamic>> createFriendlyPlace({
    required String name,
    required String category,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? phone,
    String? rulesDescription,
    List<LatLng>? polygonPoints,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Você precisa estar autenticado para sugerir um local.'};
      }

      List<dynamic>? polygonJson;
      if (polygonPoints != null && polygonPoints.length >= 3) {
        polygonJson = polygonPoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList();
      }

      await _client.from('friendly_places').insert({
        'user_id': user.id,
        'name': name,
        'category': category,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'phone': phone,
        'rules_description': rulesDescription,
        'boundary_polygon': polygonJson,
        'photo_urls': [],
        'is_active': true,
        'is_claimed': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {'success': true, 'message': 'Local sugerido com sucesso!'};
    } on PostgrestException catch (e) {
      debugPrint('FriendlyService.createFriendlyPlace (Postgrest): ${e.message}');
      return {'success': false, 'message': 'Erro ao cadastrar local: ${e.message}'};
    } catch (e) {
      debugPrint('FriendlyService.createFriendlyPlace (Erro geral): $e');
      return {'success': false, 'message': 'Ocorreu um erro ao cadastrar o local. Tente novamente.'};
    }
  }

  /// Exclui permanentemente um local pet friendly (Exclusivo Admin)
  Future<bool> deleteFriendlyPlace(String placeId) async {
    try {
      await _client
          .from('friendly_places')
          .delete()
          .eq('id', placeId);
      return true;
    } catch (e) {
      debugPrint('FriendlyService.deleteFriendlyPlace (Erro): $e');
      return false;
    }
  }
}
