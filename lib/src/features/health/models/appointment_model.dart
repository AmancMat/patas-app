import 'vet_profile_model.dart';

class HealthAppointment {
  final String id;
  final String tutorId;
  final String petId;
  final String vetId;
  final String appointmentDate; // 'YYYY-MM-DD'
  final String appointmentTime; // 'HH:MM'
  final String modality; // 'clinic', 'home'
  final String status; // 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  final String? notes;
  final double totalPrice;
  final DateTime createdAt;

  // Joined fields
  final VetProfile? vet;
  final String? petName;
  final String? petPhotoUrl;

  HealthAppointment({
    required this.id,
    required this.tutorId,
    required this.petId,
    required this.vetId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.modality,
    required this.status,
    this.notes,
    required this.totalPrice,
    required this.createdAt,
    this.vet,
    this.petName,
    this.petPhotoUrl,
  });

  factory HealthAppointment.fromJson(Map<String, dynamic> json) {
    VetProfile? vetObj;
    if (json['vet_profiles'] != null && json['vet_profiles'] is Map) {
      vetObj = VetProfile.fromJson(Map<String, dynamic>.from(json['vet_profiles']));
    }

    String? petN;
    String? petP;
    if (json['pets'] != null && json['pets'] is Map) {
      petN = json['pets']['name'];
      petP = json['pets']['photo_url'];
    }

    return HealthAppointment(
      id: json['id'],
      tutorId: json['tutor_id'] ?? '',
      petId: json['pet_id'] ?? '',
      vetId: json['vet_id'] ?? '',
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      modality: json['modality'] ?? 'clinic',
      status: json['status'] ?? 'confirmed',
      notes: json['notes'],
      totalPrice: json['total_price'] != null
          ? (json['total_price'] as num).toDouble()
          : 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      vet: vetObj,
      petName: petN,
      petPhotoUrl: petP,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tutor_id': tutorId,
      'pet_id': petId,
      'vet_id': vetId,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'modality': modality,
      'status': status,
      'notes': notes,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
