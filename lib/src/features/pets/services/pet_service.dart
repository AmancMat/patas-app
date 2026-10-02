import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/home/rewards/services/gamification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart'; // Importando o cliente Supabase globalmente

class PetService {
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
          'PetService: Tentativa $attempts falhou. Tentando novamente...',
        );
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  Future<String> uploadPetImage(File image) async {
    return _retry(() async {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('Usuário não autenticado');


        final String extension = kIsWeb ? 'jpg' : image.path.split('.').last;
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
        final String path = 'public/pet_avatars/${user.id}/$fileName';

        if (kIsWeb) {
          final bytes = await XFile(image.path).readAsBytes();
          await supabase.storage.from('pet_avatars').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );
        } else {
          await supabase.storage.from('pet_avatars').upload(
                path,
                image,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );
        }

        final String publicUrl =
            supabase.storage.from('pet_avatars').getPublicUrl(path);
        return publicUrl;
      } catch (e) {
        debugPrint('Erro no upload da imagem: $e');
        rethrow;
      }
    });
  }

  Future<String> uploadPetCover(File image) async {
    return _retry(() async {
      try {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('Usuário não autenticado');


        final String extension = kIsWeb ? 'jpg' : image.path.split('.').last;
        final String fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final String path = 'public/pet_avatars/${user.id}/covers/$fileName';

        if (kIsWeb) {
          final bytes = await XFile(image.path).readAsBytes();
          await supabase.storage.from('pet_avatars').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );
        } else {
          await supabase.storage.from('pet_avatars').upload(
                path,
                image,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );
        }

        final String publicUrl =
            supabase.storage.from('pet_avatars').getPublicUrl(path);
        return publicUrl;
      } catch (e) {
        debugPrint('Erro no upload da capa: $e');
        rethrow;
      }
    });
  }

  Future<void> createPet(Pet pet) async {
    return _retry(() async {
      try {
        // Excluindo 'id' e 'created_at' do JSON, pois são gerados pelo Supabase
        final Map<String, dynamic> petData = pet.toJson()
          ..remove('id')
          ..remove('created_at');

        await supabase.from('pets').insert(petData);
      } on PostgrestException catch (e) {
        debugPrint('PetService: Erro Postgrest: ${e.message}');
        rethrow;
      } catch (e) {
        debugPrint('PetService: Erro ao criar pet: $e');
        rethrow;
      }
    });
  }

  Future<List<Pet>> getPetsByUserId(String userId) async {
    try {
      final response = await supabase
          .from('pets')
          .select()
          .eq('user_id', userId);

      final List<Pet> pets = (response as List)
          .map((petData) => Pet.fromJson(petData))
          .toList();

      return pets;
    } on PostgrestException catch (e) {
      debugPrint('PetService: PostgrestException: ${e.message}');
      rethrow;
    } on SocketException catch (e) {
      debugPrint('PetService: Erro de conexão (SocketException): $e');
      throw 'Sem conexão com o servidor. Verifique sua internet.';
    } catch (e) {
      if (e.toString().contains('ClientException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('AuthRetryableFetchException')) {
        debugPrint('PetService: Erro de rede detectado: $e');
        throw 'Erro de rede. Verifique sua conexão.';
      }
      debugPrint('PetService: Erro inesperado: $e');
      rethrow;
    }
  }

  Future<Pet?> getPetById(String petId) async {
    try {
      final response = await supabase
          .from('pets')
          .select()
          .eq('id', petId)
          .maybeSingle();
      if (response == null) return null;
      return Pet.fromJson(response);
    } catch (e) {
      debugPrint('PetService: Erro ao buscar pet por ID: $e');
      return null;
    }
  }

  Future<void> updatePet(Pet pet) async {
    return _retry(() async {
      try {
        final Map<String, dynamic> petData = pet.toJson()
          ..remove('id')
          ..remove('created_at'); // Não atualizamos a data de criação

        await supabase.from('pets').update(petData).eq('id', pet.id);

        // [PATAS REWARDS] Verifica se o perfil atingiu o status de 100% Completo
        // Regra de Ouro (Dados que geram valor para a rede): Nascimento, Raça, Sangue, Peso e Capa.
        if (pet.birthDate != null &&
            pet.breed != null && pet.breed!.trim().isNotEmpty &&
            pet.bloodType != null && pet.bloodType!.trim().isNotEmpty &&
            pet.weight != null &&
            pet.coverUrl != null && pet.coverUrl!.trim().isNotEmpty) {
          
          GamificationService().awardOneTimePoints(
            action: 'profile_completion',
            points: 100,
          );
        }

      } on PostgrestException catch (e) {
        debugPrint('Erro ao atualizar o pet: ${e.message}');
        rethrow;
      } catch (e) {
        debugPrint('Erro desconhecido ao atualizar o pet: $e');
        rethrow;
      }
    });
  }

  Future<void> deletePet(String petId) async {
    return _retry(() async {
      try {
        await supabase.from('pets').delete().eq('id', petId);
      } on PostgrestException catch (e) {
        debugPrint('Erro ao deletar o pet: ${e.message}');
        rethrow;
      } catch (e) {
        debugPrint('Erro desconhecido ao deletar o pet: $e');
        rethrow;
      }
    });
  }
}
