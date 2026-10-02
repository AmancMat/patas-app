import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';

class OngService {
  // Upload de imagem de perfil da ONG
  Future<String> uploadOngImage(File imageFile, String userId) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = 'public/ong_avatars/$userId/$fileName';

    if (kIsWeb) {
      final bytes = await XFile(imageFile.path).readAsBytes();
      await supabase.storage.from('pet_avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    } else {
      await supabase.storage.from('pet_avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    }

    final String publicUrl =
        supabase.storage.from('pet_avatars').getPublicUrl(filePath);

    return publicUrl;
  }

  // Upload de imagem de capa da ONG via File
  Future<String> uploadOngCover(File imageFile, String userId) async {
    final bytes = await XFile(imageFile.path).readAsBytes();
    return uploadOngCoverBytes(bytes, userId);
  }

  // Upload de imagem de capa da ONG via Bytes (suporta recorte/enquadramento direto)
  Future<String> uploadOngCoverBytes(Uint8List bytes, String userId) async {
    final String fileName =
        'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = 'public/ong_covers/$userId/$fileName';

    await supabase.storage.from('pet_avatars').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            cacheControl: '3600',
            upsert: true,
          ),
        );

    final String publicUrl =
        supabase.storage.from('pet_avatars').getPublicUrl(filePath);

    return publicUrl;
  }

  // Criar perfil de ONG
  Future<void> createOngProfile(OngProfile ong) async {
    final data = ong.toJson();
    data.remove('id'); // Remove o ID pois será gerado pelo Supabase

    await supabase.from('ong_profiles').insert(data);
  }

  // Buscar perfis de ONG do usuário
  Future<List<OngProfile>> getUserOngProfiles(String userId) async {
    final response = await supabase
        .from('ong_profiles')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => OngProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Buscar perfil de ONG por ID
  Future<OngProfile?> getOngProfileById(String id) async {
    final response =
        await supabase.from('ong_profiles').select().eq('id', id).maybeSingle();

    if (response == null) return null;

    return OngProfile.fromJson(response);
  }

  // Atualizar perfil de ONG
  Future<void> updateOngProfile(OngProfile ong) async {
    await supabase.from('ong_profiles').update(ong.toJson()).eq('id', ong.id);
  }

  // Deletar perfil de ONG
  Future<void> deleteOngProfile(String id) async {
    await supabase.from('ong_profiles').delete().eq('id', id);
  }
}
