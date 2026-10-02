class Pet {
  final String id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final DateTime? birthDate;
  final String? photoUrl;
  final DateTime createdAt;
  final String? gender;
  final String? size;
  final String? color;
  final String? birthPlace;
  final String? currentCity;
  final String? coverUrl;
  final String? bloodType;
  final double? weight;
  final bool isLoveActive;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.photoUrl,
    required this.createdAt,
    this.gender,
    this.size,
    this.color,
    this.birthPlace,
    this.currentCity,
    this.coverUrl,
    this.bloodType,
    this.weight,
    this.isLoveActive = false,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      species: json['species'],
      breed: json['breed'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date']).toLocal()
          : null,
      photoUrl: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      gender: json['gender'],
      size: json['size'],
      color: json['color'],
      birthPlace: json['birth_place'],
      currentCity: json['current_city'],
      coverUrl: json['cover_url'],
      bloodType: json['blood_type'],
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      isLoveActive: json['is_love_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'birth_date': birthDate != null
          ? '${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'gender': gender,
      'size': size,
      'color': color,
      'birth_place': birthPlace,
      'current_city': currentCity,
      'cover_url': coverUrl,
      'blood_type': bloodType,
      'weight': weight,
      'is_love_active': isLoveActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
