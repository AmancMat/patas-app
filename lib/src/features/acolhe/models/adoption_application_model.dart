import 'shelter_animal_model.dart';

class AdoptionApplication {
  final String id;
  final String animalId;
  final String ongId;
  final String applicantUserId;
  final String applicantName;
  final String applicantPhone;
  final String? applicantEmail;
  final String housingType; // 'casa', 'apartamento', 'sitio'
  final bool hasYard;
  final bool hasOtherPets;
  final String? otherPetsDetails;
  final bool householdAgreement;
  final String? adoptionReason;
  final String status; // 'pendente', 'em_analise', 'entrevista', 'aprovado', 'recusado'
  final String? notesOng;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Animal embutido se join for realizado
  final ShelterAnimal? animal;

  AdoptionApplication({
    required this.id,
    required this.animalId,
    required this.ongId,
    required this.applicantUserId,
    required this.applicantName,
    required this.applicantPhone,
    this.applicantEmail,
    this.housingType = 'casa',
    this.hasYard = true,
    this.hasOtherPets = false,
    this.otherPetsDetails,
    this.householdAgreement = true,
    this.adoptionReason,
    this.status = 'pendente',
    this.notesOng,
    required this.createdAt,
    required this.updatedAt,
    this.animal,
  });

  factory AdoptionApplication.fromJson(Map<String, dynamic> json) {
    ShelterAnimal? parsedAnimal;
    if (json['shelter_animals'] is Map) {
      parsedAnimal = ShelterAnimal.fromJson(
        json['shelter_animals'] as Map<String, dynamic>,
      );
    }

    return AdoptionApplication(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      ongId: json['ong_id'] as String,
      applicantUserId: json['applicant_user_id'] as String,
      applicantName: json['applicant_name'] as String? ?? 'Anônimo',
      applicantPhone: json['applicant_phone'] as String? ?? '',
      applicantEmail: json['applicant_email'] as String?,
      housingType: json['housing_type'] as String? ?? 'casa',
      hasYard: json['has_yard'] as bool? ?? true,
      hasOtherPets: json['has_other_pets'] as bool? ?? false,
      otherPetsDetails: json['other_pets_details'] as String?,
      householdAgreement: json['household_agreement'] as bool? ?? true,
      adoptionReason: json['adoption_reason'] as String?,
      status: json['status'] as String? ?? 'pendente',
      notesOng: json['notes_ong'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      animal: parsedAnimal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'ong_id': ongId,
      'applicant_user_id': applicantUserId,
      'applicant_name': applicantName,
      'applicant_phone': applicantPhone,
      'applicant_email': applicantEmail,
      'housing_type': housingType,
      'has_yard': hasYard,
      'has_other_pets': hasOtherPets,
      'other_pets_details': otherPetsDetails,
      'household_agreement': householdAgreement,
      'adoption_reason': adoptionReason,
      'status': status,
      'notes_ong': notesOng,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
