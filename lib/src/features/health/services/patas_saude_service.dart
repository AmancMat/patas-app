import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vet_profile_model.dart';
import '../models/appointment_model.dart';
import '../models/medical_record_model.dart';

class PatasSaudeService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Retorna todos os veterinários e clínicas ativos cadastrados (filtrando inadimplentes)
  Future<List<VetProfile>> getVetsAndClinics({String? search, String? typeFilter}) async {
    try {
      var query = _client.from('vet_profiles').select('*, vet_subscriptions(status)').eq('validation_status', 'approved');
      if (typeFilter != null && typeFilter.isNotEmpty && typeFilter != 'all') {
        query = query.eq('type', typeFilter);
      }
      final response = await query.order('full_name', ascending: true);

      final list = (response as List).where((json) {
        final subs = json['vet_subscriptions'];
        if (subs != null && subs is List && subs.isNotEmpty) {
          final status = subs.first['status'];
          if (status == 'past_due' || status == 'canceled') {
            return false; // Oculta perfis inadimplentes da busca dos tutores
          }
        }
        return true;
      }).map((json) => VetProfile.fromJson(json)).toList();

      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim().toLowerCase();
        return list.where((v) =>
          v.fullName.toLowerCase().contains(term) ||
          (v.clinicName != null && v.clinicName!.toLowerCase().contains(term)) ||
          v.specialties.any((s) => s.toLowerCase().contains(term)) ||
          (v.address != null && v.address!.toLowerCase().contains(term))
        ).toList();
      }
      return list;
    } catch (e) {
      debugPrint('PatasSaudeService.getVetsAndClinics (Erro): $e');
      return [];
    }
  }

  /// Retorna o perfil profissional do usuário logado se ele for veterinário/clínica
  Future<VetProfile?> getVetProfileForCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('vet_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        return VetProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('PatasSaudeService.getVetProfileForCurrentUser (Erro): $e');
      return null;
    }
  }

  /// Cadastra ou atualiza o perfil profissional de um veterinário/clínica
  Future<bool> createOrUpdateVetProfile({
    required String crmvNumber,
    required String crmvUf,
    String? clinicName,
    required String fullName,
    required String type,
    String? bio,
    required List<String> specialties,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? photoUrl,
    required bool acceptsHomeVisit,
    required bool acceptsClinicVisit,
    required double consultationPrice,
    int? consultationDurationMinutes,
    int? maxAppointmentsPerSlot,
    int? cancellationLimitHours,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existing = await getVetProfileForCurrentUser();

      final payload = {
        'user_id': user.id,
        'crmv_number': crmvNumber,
        'crmv_uf': crmvUf,
        'clinic_name': clinicName,
        'full_name': fullName,
        'type': type,
        'bio': bio,
        'specialties': specialties,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
        'accepts_home_visit': acceptsHomeVisit,
        'accepts_clinic_visit': acceptsClinicVisit,
        'consultation_price': consultationPrice,
        'consultation_duration_minutes': consultationDurationMinutes ?? 30,
        'max_appointments_per_slot': maxAppointmentsPerSlot ?? 1,
        'cancellation_limit_hours': cancellationLimitHours ?? 24,
        'validation_status': 'approved',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        await _client.from('vet_profiles').update(payload).eq('id', existing.id);
      } else {
        payload['created_at'] = DateTime.now().toIso8601String();
        await _client.from('vet_profiles').insert(payload);
      }
      return true;
    } catch (e) {
      debugPrint('PatasSaudeService.createOrUpdateVetProfile (Erro): $e');
      return false;
    }
  }

  /// Tutor realiza o agendamento de uma consulta
  Future<bool> bookAppointment({
    required String petId,
    required String vetId,
    required String appointmentDate,
    required String appointmentTime,
    required String modality,
    String? notes,
    required double totalPrice,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('health_appointments').insert({
        'tutor_id': user.id,
        'pet_id': petId,
        'vet_id': vetId,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'modality': modality,
        'status': 'confirmed',
        'notes': notes,
        'total_price': totalPrice,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Notificar o veterinário (Conta A) via In-App e Push FCM v1
      try {
        final vetData = await _client
            .from('vet_profiles')
            .select('user_id, full_name')
            .eq('id', vetId)
            .maybeSingle();

        final petData = await _client
            .from('pets')
            .select('name')
            .eq('id', petId)
            .maybeSingle();

        final petName = petData != null ? petData['name'] : 'Pet';
        final vetUserId = vetData != null ? vetData['user_id'] as String? : null;

        if (vetUserId != null && vetUserId != user.id) {
          final parts = appointmentDate.split('-');
          final dateFormatted = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : appointmentDate;

          final title = '📅 Novo Agendamento de Consulta!';
          final content = 'O pet "$petName" agendou uma consulta para $dateFormatted às $appointmentTime.';

          // In-App Notification (Dispara a Trigger/Webhook do banco de dados que envia o Push FCM v1 automaticamente)
          await _client.from('notifications').insert({
            'user_id': vetUserId,
            'sender_pet_id': petId,
            'type': 'appointment',
            'title': title,
            'content': content,
            'data': {
              'pet_id': petId,
              'vet_id': vetId,
              'appointment_date': appointmentDate,
              'appointment_time': appointmentTime,
            },
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (notifErr) {
        debugPrint('PatasSaudeService.bookAppointment (Erro ao enviar notificação): $notifErr');
      }

      return true;
    } catch (e) {
      debugPrint('PatasSaudeService.bookAppointment (Erro): $e');
      return false;
    }
  }

  /// Retorna o número de agendamentos ativos confirmados em uma data para um veterinário
  Future<Map<String, int>> getOccupiedSlotsCount(String vetId, String dateStr) async {
    try {
      final response = await _client
          .from('health_appointments')
          .select('appointment_time')
          .eq('vet_id', vetId)
          .eq('appointment_date', dateStr)
          .inFilter('status', ['confirmed', 'pending', 'in_progress', 'completed']);

      final Map<String, int> counts = {};
      for (var row in response) {
        final rawTime = row['appointment_time'] as String?;
        if (rawTime != null && rawTime.length >= 5) {
          final time = rawTime.substring(0, 5); // ex: '09:30:00' -> '09:30'
          counts[time] = (counts[time] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      debugPrint('PatasSaudeService.getOccupiedSlotsCount (Erro): $e');
      return {};
    }
  }

  /// Cancela um agendamento (altera o status para 'cancelled')
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final user = _client.auth.currentUser;

      // Buscar dados do agendamento antes de atualizar para notificar a pessoa certa
      final apptData = await _client
          .from('health_appointments')
          .select('*, pets(name), vet_profiles(user_id, full_name)')
          .eq('id', appointmentId)
          .maybeSingle();

      await _client
          .from('health_appointments')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);

      if (apptData != null) {
        final tutorId = apptData['tutor_id'] as String?;
        final petName = apptData['pets'] != null ? apptData['pets']['name'] : 'Pet';
        final vetUserId = apptData['vet_profiles'] != null ? apptData['vet_profiles']['user_id'] as String? : null;
        final vetName = apptData['vet_profiles'] != null ? apptData['vet_profiles']['full_name'] : 'Veterinário';
        final apptDate = apptData['appointment_date'] as String? ?? '';
        final apptTime = apptData['appointment_time'] as String? ?? '';

        final parts = apptDate.split('-');
        final dateFormatted = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : apptDate;

        String? recipientUserId;
        String title;
        String content;

        if (user != null && user.id == vetUserId) {
          // Cancelado pelo Veterinário -> Notificar o Tutor
          recipientUserId = tutorId;
          title = '⚠️ Consulta Cancelada pelo Veterinário';
          content = 'Sua consulta para o pet "$petName" com Dr(a). $vetName em $dateFormatted às $apptTime foi cancelada.';
        } else {
          // Cancelado pelo Tutor -> Notificar o Veterinário
          recipientUserId = vetUserId;
          title = '⚠️ Consulta Cancelada pelo Tutor';
          content = 'A consulta do pet "$petName" agendada para $dateFormatted às $apptTime foi cancelada pelo tutor.';
        }

        if (recipientUserId != null && recipientUserId.isNotEmpty) {
          // Inserir na tabela notifications (dispara a Trigger de Push FCM v1 automaticamente)
          await _client.from('notifications').insert({
            'user_id': recipientUserId,
            'sender_pet_id': apptData['pet_id'],
            'type': 'appointment_cancelled',
            'title': title,
            'content': content,
            'data': {
              'appointment_id': appointmentId,
              'pet_id': apptData['pet_id'],
              'vet_id': apptData['vet_id'],
            },
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('PatasSaudeService.cancelAppointment (Erro): $e');
      return false;
    }
  }

  /// Reagenda uma consulta (atualiza data e horário)
  Future<bool> rescheduleAppointment({
    required String appointmentId,
    required String newDate,
    required String newTime,
  }) async {
    try {
      final user = _client.auth.currentUser;

      final apptData = await _client
          .from('health_appointments')
          .select('*, pets(name), vet_profiles(user_id, full_name)')
          .eq('id', appointmentId)
          .maybeSingle();

      await _client
          .from('health_appointments')
          .update({
            'appointment_date': newDate,
            'appointment_time': newTime,
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);

      if (apptData != null) {
        final tutorId = apptData['tutor_id'] as String?;
        final petName = apptData['pets'] != null ? apptData['pets']['name'] : 'Pet';
        final vetUserId = apptData['vet_profiles'] != null ? apptData['vet_profiles']['user_id'] as String? : null;
        final vetName = apptData['vet_profiles'] != null ? apptData['vet_profiles']['full_name'] : 'Veterinário';

        final parts = newDate.split('-');
        final dateFormatted = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : newDate;

        String? recipientUserId;
        String title;
        String content;

        if (user != null && user.id == vetUserId) {
          // Reagendado pelo Veterinário -> Notificar o Tutor
          recipientUserId = tutorId;
          title = '📅 Consulta Reagendada';
          content = 'Sua consulta para o pet "$petName" com Dr(a). $vetName foi alterada para $dateFormatted às $newTime.';
        } else {
          // Reagendado pelo Tutor -> Notificar o Veterinário
          recipientUserId = vetUserId;
          title = '📅 Consulta Reagendada pelo Tutor';
          content = 'A consulta do pet "$petName" foi alterada para $dateFormatted às $newTime.';
        }

        if (recipientUserId != null && recipientUserId.isNotEmpty) {
          await _client.from('notifications').insert({
            'user_id': recipientUserId,
            'sender_pet_id': apptData['pet_id'],
            'type': 'appointment_rescheduled',
            'title': title,
            'content': content,
            'data': {
              'appointment_id': appointmentId,
              'pet_id': apptData['pet_id'],
              'vet_id': apptData['vet_id'],
              'new_date': newDate,
              'new_time': newTime,
            },
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('PatasSaudeService.rescheduleAppointment (Erro): $e');
      return false;
    }
  }

  /// Retorna as consultas do Tutor para um Pet específico
  Future<List<HealthAppointment>> getTutorAppointments(String petId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('health_appointments')
          .select('*, vet_profiles(*), pets(name, photo_url)')
          .eq('tutor_id', user.id)
          .eq('pet_id', petId)
          .order('appointment_date', ascending: false);

      return (response as List)
          .map((json) => HealthAppointment.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('PatasSaudeService.getTutorAppointments (Erro): $e');
      return [];
    }
  }

  /// Retorna as consultas do Veterinário / Clínica
  Future<List<HealthAppointment>> getVetAppointments(String vetId) async {
    try {
      final response = await _client
          .from('health_appointments')
          .select('*, vet_profiles(*), pets(name, photo_url)')
          .eq('vet_id', vetId)
          .order('appointment_date', ascending: false);

      return (response as List)
          .map((json) => HealthAppointment.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('PatasSaudeService.getVetAppointments (Erro): $e');
      return [];
    }
  }

  /// Atualiza o status de uma consulta ('confirmed', 'completed', 'cancelled')
  Future<bool> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _client
          .from('health_appointments')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      debugPrint('PatasSaudeService.updateAppointmentStatus (Erro): $e');
      return false;
    }
  }

  /// Cria um Prontuário Eletrônico SOAP (e opcionalmente Receita e Pedidos de Exames)
  Future<bool> createMedicalRecord({
    String? appointmentId,
    required String petId,
    required String vetId,
    String? anamnesisSubjective,
    required Map<String, dynamic> vitalSignsObjective,
    String? diagnosisAssessment,
    String? treatmentPlan,
    List<MedicationItem>? medications,
    String? generalInstructions,
    List<String>? requestedExams,
  }) async {
    try {
      final recordResponse = await _client.from('medical_records').insert({
        'appointment_id': appointmentId,
        'pet_id': petId,
        'vet_id': vetId,
        'anamnesis_subjective': anamnesisSubjective,
        'vital_signs_objective': vitalSignsObjective,
        'diagnosis_assessment': diagnosisAssessment,
        'treatment_plan': treatmentPlan,
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final recordId = recordResponse['id'] as String;

      // Se houver medicamentos prescritos, insere na tabela prescriptions
      if (medications != null && medications.isNotEmpty) {
        final qrHash = 'PATAS-RX-${recordId.substring(0, 8).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        await _client.from('prescriptions').insert({
          'medical_record_id': recordId,
          'pet_id': petId,
          'vet_id': vetId,
          'medications': medications.map((m) => m.toJson()).toList(),
          'general_instructions': generalInstructions,
          'qr_code_hash': qrHash,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Se houver solicitações de exames
      if (requestedExams != null && requestedExams.isNotEmpty) {
        for (var examName in requestedExams) {
          await _client.from('exam_requests').insert({
            'medical_record_id': recordId,
            'pet_id': petId,
            'vet_id': vetId,
            'exam_type': examName,
            'status': 'requested',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // Se veio de um agendamento, marca a consulta como concluída
      if (appointmentId != null) {
        await updateAppointmentStatus(appointmentId, 'completed');
      }

      return true;
    } catch (e) {
      debugPrint('PatasSaudeService.createMedicalRecord (Erro): $e');
      return false;
    }
  }

  /// Retorna o histórico de Prontuários Médicos do Pet
  Future<List<MedicalRecord>> getPetMedicalRecords(String petId) async {
    try {
      final response = await _client
          .from('medical_records')
          .select('*, vet_profiles(*), prescriptions(*), exam_requests(*)')
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MedicalRecord.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('PatasSaudeService.getPetMedicalRecords (Erro): $e');
      return [];
    }
  }

  /// Retorna todas as receitas digitais do Pet
  Future<List<Prescription>> getPetPrescriptions(String petId) async {
    try {
      final response = await _client
          .from('prescriptions')
          .select('*, vet_profiles(*)')
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Prescription.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('PatasSaudeService.getPetPrescriptions (Erro): $e');
      return [];
    }
  }

  /// Retorna todos os pedidos de exames solicitados por veterinários para o Pet
  Future<List<ExamRequest>> getPetExamRequests(String petId) async {
    try {
      final response = await _client
          .from('exam_requests')
          .select('*, vet_profiles(*)')
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ExamRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('PatasSaudeService.getPetExamRequests (Erro): $e');
      return [];
    }
  }
}
