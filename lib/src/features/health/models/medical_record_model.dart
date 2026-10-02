import 'vet_profile_model.dart';

class MedicalRecord {
  final String id;
  final String? appointmentId;
  final String petId;
  final String vetId;
  final String? anamnesisSubjective; // S: Anamnese e queixas
  final Map<String, dynamic>
  vitalSignsObjective; // O: Temp, FC, FR, TPC, Peso kg
  final String? diagnosisAssessment; // A: Diagnósticos
  final String? treatmentPlan; // P: Orientações e conduta
  final DateTime createdAt;

  final VetProfile? vet;
  final List<Prescription>? prescriptions;
  final List<ExamRequest>? examRequests;

  MedicalRecord({
    required this.id,
    this.appointmentId,
    required this.petId,
    required this.vetId,
    this.anamnesisSubjective,
    required this.vitalSignsObjective,
    this.diagnosisAssessment,
    this.treatmentPlan,
    required this.createdAt,
    this.vet,
    this.prescriptions,
    this.examRequests,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    VetProfile? vetObj;
    if (json['vet_profiles'] != null && json['vet_profiles'] is Map) {
      vetObj = VetProfile.fromJson(
        Map<String, dynamic>.from(json['vet_profiles']),
      );
    }

    List<Prescription> prescs = [];
    if (json['prescriptions'] != null && json['prescriptions'] is List) {
      prescs = (json['prescriptions'] as List)
          .map((p) => Prescription.fromJson(Map<String, dynamic>.from(p)))
          .toList();
    }

    List<ExamRequest> exams = [];
    if (json['exam_requests'] != null && json['exam_requests'] is List) {
      exams = (json['exam_requests'] as List)
          .map((e) => ExamRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return MedicalRecord(
      id: json['id'],
      appointmentId: json['appointment_id'],
      petId: json['pet_id'] ?? '',
      vetId: json['vet_id'] ?? '',
      anamnesisSubjective: json['anamnesis_subjective'],
      vitalSignsObjective: json['vital_signs_objective'] != null
          ? Map<String, dynamic>.from(json['vital_signs_objective'])
          : {},
      diagnosisAssessment: json['diagnosis_assessment'],
      treatmentPlan: json['treatment_plan'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      vet: vetObj,
      prescriptions: prescs,
      examRequests: exams,
    );
  }
  double? get weight {
    final val = vitalSignsObjective['weight'] ?? vitalSignsObjective['peso'];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  String? get vetName => vet?.fullName ?? vet?.clinicName;
  String? get subjective => anamnesisSubjective;
  String? get objective => vitalSignsObjective.isNotEmpty
      ? vitalSignsObjective.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ')
      : null;
  String? get assessment => diagnosisAssessment;
  String? get plan => treatmentPlan;
}

class Prescription {
  final String id;
  final String medicalRecordId;
  final String petId;
  final String vetId;
  final List<MedicationItem> medications;
  final String? generalInstructions;
  final String? qrCodeHash;
  final String? pdfUrl;
  final DateTime createdAt;

  final VetProfile? vet;

  String get vetName =>
      vet?.fullName ?? vet?.clinicName ?? 'Veterinário Registrado';
  String get content => medications.isNotEmpty
      ? medications
            .map(
              (m) =>
                  '${m.name} ${m.dosageMg > 0 ? "${m.dosageMg}mg" : ""} — ${m.frequency} (${m.durationDays} dias). ${m.instructions}',
            )
            .join('\n')
      : (generalInstructions ?? 'Sem instruções adicionais');

  Prescription({
    required this.id,
    required this.medicalRecordId,
    required this.petId,
    required this.vetId,
    required this.medications,
    this.generalInstructions,
    this.qrCodeHash,
    this.pdfUrl,
    required this.createdAt,
    this.vet,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    List<MedicationItem> meds = [];
    if (json['medications'] != null && json['medications'] is List) {
      meds = (json['medications'] as List)
          .map((m) => MedicationItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    VetProfile? vetObj;
    if (json['vet_profiles'] != null && json['vet_profiles'] is Map) {
      vetObj = VetProfile.fromJson(
        Map<String, dynamic>.from(json['vet_profiles']),
      );
    }

    return Prescription(
      id: json['id'],
      medicalRecordId: json['medical_record_id'] ?? '',
      petId: json['pet_id'] ?? '',
      vetId: json['vet_id'] ?? '',
      medications: meds,
      generalInstructions: json['general_instructions'],
      qrCodeHash: json['qr_code_hash'],
      pdfUrl: json['pdf_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      vet: vetObj,
    );
  }
}

class MedicationItem {
  final String name;
  final double dosageMg;
  final String frequency; // Ex: 'De 12 em 12 horas'
  final int durationDays;
  final String instructions;

  MedicationItem({
    required this.name,
    required this.dosageMg,
    required this.frequency,
    required this.durationDays,
    required this.instructions,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      name: json['name'] ?? '',
      dosageMg: (json['dosage_mg'] as num? ?? 0).toDouble(),
      frequency: json['frequency'] ?? '',
      durationDays: json['duration_days'] ?? 1,
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage_mg': dosageMg,
      'frequency': frequency,
      'duration_days': durationDays,
      'instructions': instructions,
    };
  }
}

class ExamRequest {
  final String id;
  final String medicalRecordId;
  final String petId;
  final String vetId;
  final String examType;
  final String? observations;
  final String status; // 'requested', 'completed'
  final String? reportPdfUrl;
  final DateTime createdAt;
  final VetProfile? vet;

  ExamRequest({
    required this.id,
    required this.medicalRecordId,
    required this.petId,
    required this.vetId,
    required this.examType,
    this.observations,
    required this.status,
    this.reportPdfUrl,
    required this.createdAt,
    this.vet,
  });

  factory ExamRequest.fromJson(Map<String, dynamic> json) {
    VetProfile? vetObj;
    if (json['vet_profiles'] != null && json['vet_profiles'] is Map) {
      vetObj = VetProfile.fromJson(
        Map<String, dynamic>.from(json['vet_profiles']),
      );
    }

    return ExamRequest(
      id: json['id'] ?? '',
      medicalRecordId: json['medical_record_id'] ?? '',
      petId: json['pet_id'] ?? '',
      vetId: json['vet_id'] ?? '',
      examType: json['exam_type'] ?? '',
      observations: json['observations'],
      status: json['status'] ?? 'requested',
      reportPdfUrl: json['report_pdf_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      vet: vetObj,
    );
  }
}
