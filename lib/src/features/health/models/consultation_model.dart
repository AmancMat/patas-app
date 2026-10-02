class PetConsultation {
  final String id;
  final String petId;
  final String userId;
  final DateTime date;
  final double? weight;
  final double? temperature;
  final int? heartRate;
  final int? respiratoryRate;
  final String? tpc;
  final String? symptoms;
  final String? diagnosis;
  final String? treatment;
  final String status;
  final String? clinicId;
  final String? clinicName;
  final DateTime? createdAt;

  PetConsultation({
    required this.id,
    required this.petId,
    required this.userId,
    required this.date,
    this.weight,
    this.temperature,
    this.heartRate,
    this.respiratoryRate,
    this.tpc,
    this.symptoms,
    this.diagnosis,
    this.treatment,
    required this.status,
    this.clinicId,
    this.clinicName,
    this.createdAt,
  });

  factory PetConsultation.fromJson(Map<String, dynamic> json) {
    return PetConsultation(
      id: json['id'],
      petId: json['pet_id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      temperature: json['temperature'] != null
          ? (json['temperature'] as num).toDouble()
          : null,
      heartRate: json['heart_rate'],
      respiratoryRate: json['respiratory_rate'],
      tpc: json['tpc'],
      symptoms: json['symptoms'],
      diagnosis: json['diagnosis'],
      treatment: json['treatment'],
      status: json['status'] ?? 'aguardando',
      clinicId: json['clinic_id'],
      clinicName: json['clinic_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'pet_id': petId,
      'user_id': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'temperature': temperature,
      'heart_rate': heartRate,
      'respiratory_rate': respiratoryRate,
      'tpc': tpc,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'status': status,
      'clinic_id': clinicId,
      'clinic_name': clinicName,
    };
  }
}
