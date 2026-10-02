import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/features/family/models/family_member_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart'; // Importando o cliente Supabase globalmente

class FamilyService {

  // Upload da imagem para o bucket family_avatars
  Future<String> uploadFamilyMemberImage(File image, String userId) async {
    try {
      final String extension = kIsWeb ? 'jpg' : image.path.split('.').last;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String path = 'public/family_avatars/$userId/$fileName';

      if (kIsWeb) {
        final bytes = await XFile(image.path).readAsBytes();
        await supabase.storage.from('family_avatars').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );
      } else {
        await supabase.storage.from('family_avatars').upload(
              path,
              image,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );
      }

      final String publicUrl = supabase.storage.from('family_avatars').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Erro no upload da imagem do membro da família: $e');
      rethrow;
    }
  }

  // Criar um novo membro da família
  Future<void> createFamilyMember(FamilyMember member) async {
    try {
      final Map<String, dynamic> memberData = member.toJson()
        ..remove('id')
        ..remove('created_at');

      await supabase.from('family_members').insert(memberData);
    } on PostgrestException catch (e) {
      debugPrint('Erro ao criar membro da família: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erro desconhecido ao criar membro da família: $e');
      rethrow;
    }
  }

  // Buscar todos os membros da família de um usuário
  Future<List<FamilyMember>> getFamilyMembers(String userId) async {
    try {
      final response = await supabase
          .from('family_members')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true); // Ordenar por data de criação

      final List<FamilyMember> members = (response as List)
          .map((data) => FamilyMember.fromJson(data))
          .toList();
          
      return members;
    } on PostgrestException catch (e) {
      debugPrint('Erro ao buscar membros da família: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erro desconhecido ao buscar membros da família: $e');
      rethrow;
    }
  }

  // Atualizar um membro da família
  Future<void> updateFamilyMember(FamilyMember member) async {
    try {
      final Map<String, dynamic> memberData = member.toJson()
        ..remove('id')
        ..remove('created_at');

      await supabase
          .from('family_members')
          .update(memberData)
          .eq('id', member.id);
          
    } on PostgrestException catch (e) {
      debugPrint('Erro ao atualizar membro da família: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erro desconhecido ao atualizar membro da família: $e');
      rethrow;
    }
  }

  // Deletar um membro da família
  Future<void> deleteFamilyMember(String memberId) async {
    try {
      await supabase
          .from('family_members')
          .delete()
          .eq('id', memberId);
          
    } on PostgrestException catch (e) {
      debugPrint('Erro ao deletar membro da família: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erro desconhecido ao deletar membro da família: $e');
      rethrow;
    }
  }
}
