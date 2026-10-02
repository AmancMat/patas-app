import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/health/models/consultation_model.dart';
import 'package:patas_web_app/src/features/health/models/exam_model.dart';
import 'package:patas_web_app/src/features/health/models/vaccine_model.dart';
import 'package:patas_web_app/src/models/notification_model.dart';
import 'package:patas_web_app/src/services/supabase_notification_service.dart';
import '../../../../main.dart'; // Importando o cliente Supabase globalmente

class HealthService {
  Future<List<PetVaccine>> getVaccines(String petId) async {
    try {
      final List<dynamic> response = await supabase
          .from('pet_vaccines')
          .select()
          .eq('pet_id', petId)
          .order('application_date', ascending: false);

      return response.map((json) => PetVaccine.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar vacinas: $e');
      rethrow;
    }
  }

  Future<void> addVaccine(PetVaccine vaccine) async {
    try {
      await supabase.from('pet_vaccines').insert(vaccine.toJson());

      // Enviar notificação para o usuário (lembrete de que foi cadastrada)
      final user = supabase.auth.currentUser;
      if (user != null) {
        await SupabaseNotificationService().sendNotification(
          receiverUserId: user.id,
          senderPetId: vaccine.petId,
          type: NotificationType.vaccine,
          title: 'Vacina cadastrada!',
          content:
              'A vacina "${vaccine.name}" foi registrada com sucesso para seu pet.',
          data: {
            'pet_id': vaccine.petId,
            'vaccine_id': vaccine.id,
          },
        );
      }
    } catch (e) {
      debugPrint('Erro ao adicionar vacina: $e');
      rethrow;
    }
  }

  Future<void> deleteVaccine(String id) async {
    try {
      await supabase.from('pet_vaccines').delete().eq('id', id);
    } catch (e) {
      debugPrint('Erro ao deletar vacina: $e');
      rethrow;
    }
  }

  // --- CONSULTAS ---

  Future<List<PetConsultation>> getConsultations(String petId) async {
    try {
      final List<dynamic> response = await supabase
          .from('consultations')
          .select()
          .eq('pet_id', petId)
          .order('date', ascending: false);

      return response.map((json) => PetConsultation.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar consultas: $e');
      rethrow;
    }
  }

  Future<void> addConsultation(PetConsultation consultation) async {
    try {
      await supabase.from('consultations').insert(consultation.toJson());

      final user = supabase.auth.currentUser;
      if (user != null) {
        await SupabaseNotificationService().sendNotification(
          receiverUserId: user.id,
          senderPetId: consultation.petId,
          type: NotificationType.vaccine,
          title: '🩺 Consulta Agendada!',
          content: 'Sua consulta de saúde foi registrada com sucesso.',
          data: {
            'pet_id': consultation.petId,
            'consultation_id': consultation.id,
          },
        );
      }
    } catch (e) {
      debugPrint('Erro ao adicionar consulta: $e');
      rethrow;
    }
  }

  Future<void> deleteConsultation(String id) async {
    try {
      await supabase.from('consultations').delete().eq('id', id);
    } catch (e) {
      debugPrint('Erro ao deletar consulta: $e');
      rethrow;
    }
  }

  Future<void> cancelConsultation(String id) async {
    try {
      await supabase
          .from('consultations')
          .update({'status': 'cancelada'})
          .eq('id', id)
          .select();

      final user = supabase.auth.currentUser;
      if (user != null) {
        await SupabaseNotificationService().sendNotification(
          receiverUserId: user.id,
          type: NotificationType.system,
          title: '⚠️ Consulta Cancelada',
          content: 'A consulta agendada foi marcada como cancelada.',
          data: {
            'consultation_id': id,
          },
        );
      }
    } catch (e) {
      debugPrint('Erro ao cancelar consulta: $e');
      rethrow;
    }
  }

  // --- EXAMES ---

  Future<List<PetExam>> getExams(String petId) async {
    try {
      final List<dynamic> response = await supabase
          .from('exams')
          .select()
          .eq('pet_id', petId)
          .order('date', ascending: false);

      return response.map((json) => PetExam.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar exames: $e');
      rethrow;
    }
  }

  Future<void> addExam(PetExam exam) async {
    try {
      await supabase.from('exams').insert(exam.toJson());
    } catch (e) {
      debugPrint('Erro ao adicionar exame: $e');
      rethrow;
    }
  }

  Future<void> deleteExam(String id) async {
    try {
      await supabase.from('exams').delete().eq('id', id);
    } catch (e) {
      debugPrint('Erro ao deletar exame: $e');
      rethrow;
    }
  }
}
