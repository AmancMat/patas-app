class PetVaccine {
  final String id;
  final String petId;
  final String name;
  final DateTime applicationDate;
  final DateTime? createdAt;

  PetVaccine({
    required this.id,
    required this.petId,
    required this.name,
    required this.applicationDate,
    this.createdAt,
  });

  factory PetVaccine.fromJson(Map<String, dynamic> json) {
    return PetVaccine(
      id: json['id'],
      petId: json['pet_id'],
      name: json['name'],
      applicationDate: DateTime.parse(json['application_date']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'pet_id': petId,
      'name': name,
      'application_date': applicationDate.toIso8601String().split('T')[0],
    };
  }
}
