import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';

class CorpService {
  // Upload de imagem de perfil da Empresa
  Future<String> uploadCorpImage(File imageFile, String userId) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = 'public/corp_avatars/$userId/$fileName';

    if (kIsWeb) {
      final bytes = await XFile(imageFile.path).readAsBytes();
      await supabase.storage
          .from('pet_avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    } else {
      await supabase.storage
          .from('pet_avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    }

    final String publicUrl = supabase.storage
        .from('pet_avatars')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  // Upload de imagem de capa da Empresa
  Future<String> uploadCorpCover(File imageFile, String userId) async {
    final String fileName =
        'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = 'public/corp_covers/$userId/$fileName';

    if (kIsWeb) {
      final bytes = await XFile(imageFile.path).readAsBytes();
      await supabase.storage.from('pet_avatars').uploadBinary(filePath, bytes);
    } else {
      await supabase.storage.from('pet_avatars').upload(filePath, imageFile);
    }

    final String publicUrl = supabase.storage
        .from('pet_avatars')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  // Criar perfil de Empresa
  Future<void> createCorpProfile(CorpProfile corp) async {
    final data = corp.toJson();
    data.remove('id'); // Remove o ID pois será gerado pelo Supabase

    await supabase.from('company_profiles').insert(data);
  }

  // Buscar perfis de Empresa do usuário
  Future<List<CorpProfile>> getUserCorpProfiles(String userId) async {
    final response = await supabase
        .from('company_profiles')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CorpProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Buscar perfil de Empresa por ID
  Future<CorpProfile?> getCorpProfileById(String id) async {
    final response = await supabase
        .from('company_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return CorpProfile.fromJson(response);
  }

  // Atualizar perfil de Empresa
  Future<void> updateCorpProfile(CorpProfile corp) async {
    await supabase
        .from('company_profiles')
        .update(corp.toJson())
        .eq('id', corp.id);
  }

  // Deletar perfil de Empresa
  Future<void> deleteCorpProfile(String id) async {
    await supabase.from('company_profiles').delete().eq('id', id);
  }
}
