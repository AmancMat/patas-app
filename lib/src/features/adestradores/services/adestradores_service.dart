import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trainer_profile_model.dart';
import '../models/training_models.dart';

class AdestradoresService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // 🔍 BUSCA DE ADESTRADORES
  // ─────────────────────────────────────────────

  Future<List<TrainerProfile>> getTrainers({
    String? query,
    String? specialty,
    String? city,
    bool useMockIfEmpty = false,
  }) async {
    try {
      var filter = _supabase
          .from('trainer_profiles')
          .select()
          .eq('is_active', true);

      if (query != null && query.trim().isNotEmpty) {
        filter = filter.ilike('full_name', '%${query.trim()}%');
      }

      final response = await filter
          .order('rating', ascending: false)
          .timeout(const Duration(seconds: 4));
      final list = (response as List)
          .map((json) => TrainerProfile.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filtro local de especialidade se solicitado
      if (specialty != null && specialty != 'Todos') {
        final filtered = list.where((t) {
          return t.specialties.any(
            (s) => s.toLowerCase().contains(specialty.toLowerCase()),
          );
        }).toList();

        if (filtered.isEmpty && useMockIfEmpty) {
          return _getDemoTrainers(query: query, specialty: specialty);
        }
        return filtered;
      }

      // Se o banco ainda não tiver dados e for solicitado mock expressamente:
      if (list.isEmpty && useMockIfEmpty) {
        return _getDemoTrainers(query: query, specialty: specialty);
      }

      return list;
    } catch (e) {
      debugPrint('[AdestradoresService] Erro ao buscar adestradores: $e');
      if (useMockIfEmpty) {
        return _getDemoTrainers(query: query, specialty: specialty);
      }
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // 👤 PERFIL DO ADESTRADOR (CONSULTA / CADASTRO)
  // ─────────────────────────────────────────────

  Future<TrainerProfile?> getCurrentUserTrainerProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('trainer_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response != null) {
        return TrainerProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('[AdestradoresService] Erro ao buscar perfil do adestrador logado: $e');
      return null;
    }
  }

  Future<String?> uploadTrainerPhoto(File imageFile, String userId) async {
    try {
      final String fileName = 'trainer_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'public/trainers/$userId/$fileName';

      if (kIsWeb) {
        final bytes = await XFile(imageFile.path).readAsBytes();
        await _supabase.storage.from('pet_avatars').uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } else {
        await _supabase.storage.from('pet_avatars').upload(
              filePath,
              imageFile,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }

      return _supabase.storage.from('pet_avatars').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('[AdestradoresService] Erro no upload da foto do adestrador: $e');
      return null;
    }
  }

  Future<TrainerProfile> createOrUpdateTrainerProfile({
    required String fullName,
    String? bio,
    String? profilePhoto,
    String? phone,
    String? whatsapp,
    String? instagram,
    String? city,
    String? state,
    int serviceRadiusKm = 15,
    bool attendsHome = true,
    bool attendsOnline = false,
    bool attendsCenter = false,
    String? trainingCenterAddress,
    List<String> specialties = const [],
    List<String> certifications = const [],
    List<Map<String, dynamic>> initialServices = const [],
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado no Supabase.');
    }

    final data = {
      'user_id': user.id,
      'full_name': fullName.trim(),
      'bio': bio?.trim(),
      'profile_photo': profilePhoto,
      'phone': phone?.trim(),
      'whatsapp': whatsapp?.trim(),
      'instagram': instagram?.trim(),
      'city': city?.trim(),
      'state': state?.trim().toUpperCase(),
      'service_radius_km': serviceRadiusKm,
      'attends_home': attendsHome,
      'attends_online': attendsOnline,
      'attends_center': attendsCenter,
      'training_center_address': trainingCenterAddress?.trim(),
      'specialties': specialties,
      'certifications': certifications,
      'is_active': true,
    };

    final response = await _supabase
        .from('trainer_profiles')
        .upsert(data, onConflict: 'user_id')
        .select()
        .single()
        .timeout(const Duration(seconds: 8));

    final created = TrainerProfile.fromJson(response);

    // Inserir serviços se fornecidos
    if (initialServices.isNotEmpty) {
      for (final serv in initialServices) {
        try {
          await _supabase.from('trainer_services').insert({
            'trainer_id': created.id,
            'name': serv['name'],
            'description': serv['description'],
            'price': serv['price'],
            'duration_minutes': serv['duration_minutes'] ?? 60,
            'modality': serv['modality'] ?? 'domicilio',
            'is_active': true,
          }).timeout(const Duration(seconds: 4));
        } catch (err) {
          debugPrint('[AdestradoresService] Erro ao cadastrar serviço: $err');
        }
      }
    }

    return created;
  }

  Future<TrainerProfile?> getTrainerById(String trainerId) async {
    try {
      final response = await _supabase
          .from('trainer_profiles')
          .select()
          .eq('id', trainerId)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response != null) {
        return TrainerProfile.fromJson(response);
      }
      return _getDemoTrainers().firstWhere(
        (t) => t.id == trainerId,
        orElse: () => _getDemoTrainers().first,
      );
    } catch (e) {
      debugPrint('[AdestradoresService] Erro ao buscar adestrador por ID: $e');
      return _getDemoTrainers().firstWhere(
        (t) => t.id == trainerId,
        orElse: () => _getDemoTrainers().first,
      );
    }
  }

  // ─────────────────────────────────────────────
  // 💼 SERVIÇOS & MODALIDADES DO ADESTRADOR
  // ─────────────────────────────────────────────

  Future<List<TrainerService>> getTrainerServices(String trainerId) async {
    try {
      final response = await _supabase
          .from('trainer_services')
          .select()
          .eq('trainer_id', trainerId)
          .eq('is_active', true)
          .order('price', ascending: true)
          .timeout(const Duration(seconds: 4));

      final list = (response as List)
          .map((json) => TrainerService.fromJson(json as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return _getDemoServices(trainerId);
      }

      return list;
    } catch (e) {
      debugPrint('[AdestradoresService] Erro ao buscar serviços: $e');
      return _getDemoServices(trainerId);
    }
  }

  // ─────────────────────────────────────────────
  // 📅 SOLICITAÇÕES DE TREINO (TUTOR -> ADESTRADOR)
  // ─────────────────────────────────────────────

  Future<bool> createTrainingRequest({
    required String trainerId,
    required String petId,
    String? serviceId,
    DateTime? scheduledDate,
    String? scheduledTime,
    String modality = 'domicilio',
    String? address,
    String? behavioralNotes,
    double? price,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase.from('training_requests').insert({
        'trainer_id': trainerId,
        'user_id': user.id,
        'pet_id': petId,
        'service_id': serviceId,
        'scheduled_date': scheduledDate?.toIso8601String().split('T').first,
        'scheduled_time': scheduledTime,
        'modality': modality,
        'address': address,
        'behavioral_notes': behavioralNotes,
        'price': price,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      debugPrint('[AdestradoresService] Erro ao criar training request: $e');
      return false;
    }
  }

  Future<List<TrainingRequest>> getUserTrainingRequests() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('training_requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      return (response as List)
          .map((json) => TrainingRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AdestradoresService] Erro ao buscar requests do usuário: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // 📁 DIÁRIO DE EVOLUÇÃO DO ALUNO (TRAINING LOGS)
  // ─────────────────────────────────────────────

  Future<List<TrainingLog>> getPetTrainingLogs(String petId) async {
    try {
      final response = await _supabase
          .from('training_logs')
          .select()
          .eq('pet_id', petId)
          .order('session_date', ascending: false)
          .timeout(const Duration(seconds: 4));

      return (response as List)
          .map((json) => TrainingLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AdestradoresService] Erro ao buscar logs de treino: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // ⭐ REVIEWS & AVALIAÇÕES
  // ─────────────────────────────────────────────

  Future<List<TrainerReview>> getTrainerReviews(String trainerId) async {
    try {
      final response = await _supabase
          .from('trainer_reviews')
          .select('*, users(name, photo_url)')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      final list = (response as List)
          .map((json) => TrainerReview.fromJson(json as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return _getDemoReviews(trainerId);
      }
      return list;
    } catch (e) {
      debugPrint('[AdestradoresService] Erro ao buscar reviews: $e');
      return _getDemoReviews(trainerId);
    }
  }

  // ─────────────────────────────────────────────
  // 🎨 DADOS DEMONSTRATIVOS (FALLBACK RESILIENTE)
  // ─────────────────────────────────────────────

  List<TrainerProfile> _getDemoTrainers({String? query, String? specialty}) {
    final demos = [
      TrainerProfile(
        id: 'demo-trainer-1',
        userId: 'demo-user-1',
        fullName: 'Carlos Henrique Adestrador',
        bio:
            'Especialista em comportamento canino com mais de 8 anos de experiência. Focado em reforço positivo, obediência básica e resolução de reatividade na guia.',
        profilePhoto:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
        coverPhoto:
            'https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&q=80&w=800',
        phone: '(11) 98765-4321',
        whatsapp: '11987654321',
        instagram: '@carlos.adestra',
        city: 'São Paulo',
        state: 'SP',
        serviceRadiusKm: 20,
        attendsHome: true,
        attendsOnline: true,
        attendsCenter: true,
        trainingCenterAddress: 'Av. Paulista, 1500 - Bela Vista',
        specialties: [
          'Obediência Básica',
          'Reatividade & Medo',
          'Passeio Estruturado',
          'Filhotes',
        ],
        certifications: [
          'Certificação Internacional em Comportamento Canino (CBCC-KA)',
          'Especialista em Adestramento Positivo',
        ],
        rating: 4.9,
        reviewCount: 42,
        isVerified: true,
        createdAt: DateTime.now(),
      ),
      TrainerProfile(
        id: 'demo-trainer-2',
        userId: 'demo-user-2',
        fullName: 'Juliana Paiva - Comportamento & Bem-Estar',
        bio:
            'Bióloga e adestradora comportamentalista de cães e gatos. Trabalho personalizado para ansiedade de separação, xixi fora do lugar e adaptação de novos filhotes.',
        profilePhoto:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400',
        coverPhoto:
            'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&q=80&w=800',
        phone: '(11) 97654-3210',
        whatsapp: '11976543210',
        instagram: '@ju.comportamentopet',
        city: 'São Paulo',
        state: 'SP',
        serviceRadiusKm: 15,
        attendsHome: true,
        attendsOnline: true,
        attendsCenter: false,
        specialties: [
          'Ansiedade de Separação',
          'Filhotes & Socialização',
          'Xixi e Cocô no Lugar',
          'Comportamento Felino',
        ],
        certifications: [
          'Graduação em Biologia (USP)',
          'Especialização em Etologia Aplicada',
        ],
        rating: 5.0,
        reviewCount: 28,
        isVerified: true,
        createdAt: DateTime.now(),
      ),
      TrainerProfile(
        id: 'demo-trainer-3',
        userId: 'demo-user-3',
        fullName: 'Marcos Vinícius - Treinamento Urbano',
        bio:
            'Treinador focado em cães de porte médio e grande que puxam a guia ou demonstram agitação em ambientes urbanos. Metodologia focada no vínculo entre tutor e pet.',
        profilePhoto:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=400',
        coverPhoto:
            'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?auto=format&fit=crop&q=80&w=800',
        phone: '(11) 96543-2109',
        whatsapp: '11965432109',
        instagram: '@marcos.treinapet',
        city: 'Campinas',
        state: 'SP',
        serviceRadiusKm: 25,
        attendsHome: true,
        attendsOnline: false,
        attendsCenter: true,
        specialties: [
          'Cães Grandes & Força',
          'Passeio sem Puxar',
          'Obediência Avançada',
          'Socialização em Parques',
        ],
        certifications: [
          'Treinador Canino Profissional Credenciado',
          'Seminário de Conduta e Linguagem Corporal',
        ],
        rating: 4.8,
        reviewCount: 19,
        isVerified: true,
        createdAt: DateTime.now(),
      ),
    ];

    var filtered = demos;
    if (query != null && query.trim().isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.fullName.toLowerCase().contains(query.toLowerCase().trim()))
          .toList();
    }
    if (specialty != null && specialty != 'Todos') {
      filtered = filtered
          .where((t) => t.specialties
              .any((s) => s.toLowerCase().contains(specialty.toLowerCase())))
          .toList();
    }
    return filtered;
  }

  List<TrainerService> _getDemoServices(String trainerId) {
    return [
      TrainerService(
        id: 'serv-1',
        trainerId: trainerId,
        title: 'Avaliação Comportamental & Primeira Sessão',
        description:
            'Análise detalhada do comportamento do animal na rotina da casa, identificação de gatilhos e plano de treino personalizado.',
        modality: 'presencial',
        durationMinutes: 75,
        price: 180.00,
        createdAt: DateTime.now(),
      ),
      TrainerService(
        id: 'serv-2',
        trainerId: trainerId,
        title: 'Aula Avulsa de Obediência e Passeio',
        description:
            'Sessão prática a domicílio focada em comandos essenciais (Senta, Fica, Junto, Foco) e passeio tranquilo sem puxões na guia.',
        modality: 'presencial',
        durationMinutes: 60,
        price: 150.00,
        createdAt: DateTime.now(),
      ),
      TrainerService(
        id: 'serv-3',
        trainerId: trainerId,
        title: 'Pacote Mensal - 4 Aulas Práticas',
        description:
            'Programa intensivo de 1 aula por semana com diário de evolução pós-aula e suporte contínuo via WhatsApp.',
        modality: 'presencial',
        durationMinutes: 60,
        price: 520.00,
        createdAt: DateTime.now(),
      ),
      TrainerService(
        id: 'serv-4',
        trainerId: trainerId,
        title: 'Consultoria Online de Adaptação / Filhotes',
        description:
            'Orientação completa por vídeo-chamada para preparar a casa, ensinar o banheiro no tapete e regras de convivência.',
        modality: 'online',
        durationMinutes: 50,
        price: 120.00,
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<TrainerReview> _getDemoReviews(String trainerId) {
    return [
      TrainerReview(
        id: 'rev-1',
        trainerId: trainerId,
        userId: 'u1',
        rating: 5,
        tutorName: 'Mariana & Thor 🐾',
        tutorPhoto:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200',
        comment:
            'O Thor puxava tanto no passeio que eu quase caía. Em 3 aulas ele aprendeu a andar do meu lado olhando pra mim! Excelente profissional.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TrainerReview(
        id: 'rev-2',
        trainerId: trainerId,
        userId: 'u2',
        rating: 5,
        tutorName: 'Rodrigo & Mel 🐕',
        tutorPhoto:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=200',
        comment:
            'Muito paciente e didático. Me ensinou a entender os sinais da Mel quando ela fica estressada. O diário de lição de casa ajudou muito na nossa rotina!',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];
  }
}
