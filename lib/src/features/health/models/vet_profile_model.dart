class VetProfile {
  final String id;
  final String? userId;
  final String crmvNumber;
  final String crmvUf;
  final String? clinicName;
  final String fullName;
  final String type; // 'veterinarian', 'clinic', 'hospital_24h'
  final String? bio;
  final List<String> specialties;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final bool acceptsHomeVisit;
  final bool acceptsClinicVisit;
  final double consultationPrice;
  final String validationStatus; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final int consultationDurationMinutes;
  final int maxAppointmentsPerSlot;
  final int cancellationLimitHours;

  VetProfile({
    required this.id,
    this.userId,
    required this.crmvNumber,
    required this.crmvUf,
    this.clinicName,
    required this.fullName,
    required this.type,
    this.bio,
    required this.specialties,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.photoUrl,
    required this.acceptsHomeVisit,
    required this.acceptsClinicVisit,
    required this.consultationPrice,
    required this.validationStatus,
    required this.createdAt,
    required this.consultationDurationMinutes,
    required this.maxAppointmentsPerSlot,
    required this.cancellationLimitHours,
  });

  factory VetProfile.fromJson(Map<String, dynamic> json) {
    return VetProfile(
      id: json['id'],
      userId: json['user_id'],
      crmvNumber: json['crmv_number'] ?? '',
      crmvUf: json['crmv_uf'] ?? 'SP',
      clinicName: json['clinic_name'],
      fullName: json['full_name'] ?? 'Dr. Veterinário',
      type: json['type'] ?? 'veterinarian',
      bio: json['bio'],
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : [],
      phone: json['phone'],
      address: json['address'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      photoUrl: json['photo_url'],
      acceptsHomeVisit: json['accepts_home_visit'] ?? false,
      acceptsClinicVisit: json['accepts_clinic_visit'] ?? true,
      consultationPrice: json['consultation_price'] != null
          ? (json['consultation_price'] as num).toDouble()
          : 0.0,
      validationStatus: json['validation_status'] ?? 'approved',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      consultationDurationMinutes: json['consultation_duration_minutes'] ?? 30,
      maxAppointmentsPerSlot: json['max_appointments_per_slot'] ?? 1,
      cancellationLimitHours: json['cancellation_limit_hours'] ?? 24,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
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
      'validation_status': validationStatus,
      'created_at': createdAt.toIso8601String(),
      'consultation_duration_minutes': consultationDurationMinutes,
      'max_appointments_per_slot': maxAppointmentsPerSlot,
      'cancellation_limit_hours': cancellationLimitHours,
    };
  }
}
