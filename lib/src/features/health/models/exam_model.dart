class PetExam {
  final String id;
  final String petId;
  final String userId;
  final DateTime date;
  final String type; // Sangue, Imagem, Urina, etc.
  final String name; // Ex: Hemograma
  final String? observations;
  final String? fileUrl;
  final DateTime? createdAt;

  PetExam({
    required this.id,
    required this.petId,
    required this.userId,
    required this.date,
    required this.type,
    required this.name,
    this.observations,
    this.fileUrl,
    this.createdAt,
  });

  factory PetExam.fromJson(Map<String, dynamic> json) {
    return PetExam(
      id: json['id'],
      petId: json['pet_id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      name: json['name'],
      observations: json['observations'],
      fileUrl: json['file_url'],
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
      'type': type,
      'name': name,
      'observations': observations,
      'file_url': fileUrl,
    };
  }
}
