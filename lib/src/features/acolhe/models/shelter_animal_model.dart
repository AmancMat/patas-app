class ShelterAnimal {
  final String id;
  final String ongId;
  final String? createdBy;
  final String name;
  final String species; // 'canino', 'felino', 'outro'
  final String breed;
  final String gender; // 'macho', 'femea'
  final String size; // 'pequeno', 'medio', 'grande'
  final String? ageEstimate;
  final String? rescueStory;
  final String? behaviorNotes;
  final String? photoUrl;
  final List<String> galleryPhotos;
  final bool isCastrated;
  final bool isVaccinated;
  final bool isDewormed;
  final String? specialNeeds;
  final String? temporaryHomeId;
  final String status; // 'disponivel', 'em_tratamento', 'adotado', 'lar_temporario'
  final bool isPublicAdoption;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Dados da ONG injetados via join quando carregado na visão pública
  final String? ongName;
  final String? ongCity;
  final String? ongState;
  final String? ongPhone;

  ShelterAnimal({
    required this.id,
    required this.ongId,
    this.createdBy,
    required this.name,
    this.species = 'canino',
    this.breed = 'SRD (Sem Raça Definida)',
    this.gender = 'macho',
    this.size = 'medio',
    this.ageEstimate,
    this.rescueStory,
    this.behaviorNotes,
    this.photoUrl,
    this.galleryPhotos = const [],
    this.isCastrated = false,
    this.isVaccinated = false,
    this.isDewormed = false,
    this.specialNeeds,
    this.temporaryHomeId,
    this.status = 'disponivel',
    this.isPublicAdoption = true,
    required this.createdAt,
    required this.updatedAt,
    this.ongName,
    this.ongCity,
    this.ongState,
    this.ongPhone,
  });

  factory ShelterAnimal.fromJson(Map<String, dynamic> json) {
    // Tratamento de fotos da galeria
    List<String> photos = [];
    if (json['gallery_photos'] != null) {
      if (json['gallery_photos'] is List) {
        photos = (json['gallery_photos'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Tratamento de dados da ONG se houver join
    Map<String, dynamic>? ongData;
    if (json['ong_profiles'] is Map) {
      ongData = json['ong_profiles'] as Map<String, dynamic>;
    }

    return ShelterAnimal(
      id: json['id'] as String,
      ongId: json['ong_id'] as String,
      createdBy: json['created_by'] as String?,
      name: json['name'] as String? ?? 'Sem Nome',
      species: json['species'] as String? ?? 'canino',
      breed: json['breed'] as String? ?? 'SRD',
      gender: json['gender'] as String? ?? 'macho',
      size: json['size'] as String? ?? 'medio',
      ageEstimate: json['age_estimate'] as String?,
      rescueStory: json['rescue_story'] as String?,
      behaviorNotes: json['behavior_notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      galleryPhotos: photos,
      isCastrated: json['is_castrated'] as bool? ?? false,
      isVaccinated: json['is_vaccinated'] as bool? ?? false,
      isDewormed: json['is_dewormed'] as bool? ?? false,
      specialNeeds: json['special_needs'] as String?,
      temporaryHomeId: json['temporary_home_id'] as String?,
      status: json['status'] as String? ?? 'disponivel',
      isPublicAdoption: json['is_public_adoption'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      ongName: ongData?['name'] as String?,
      ongCity: ongData?['address'] as String?,
      ongPhone: ongData?['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ong_id': ongId,
      if (createdBy != null) 'created_by': createdBy,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'size': size,
      'age_estimate': ageEstimate,
      'rescue_story': rescueStory,
      'behavior_notes': behaviorNotes,
      'photo_url': photoUrl,
      'gallery_photos': galleryPhotos,
      'is_castrated': isCastrated,
      'is_vaccinated': isVaccinated,
      'is_dewormed': isDewormed,
      'special_needs': specialNeeds,
      if (temporaryHomeId != null) 'temporary_home_id': temporaryHomeId,
      'status': status,
      'is_public_adoption': isPublicAdoption,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  ShelterAnimal copyWith({
    String? id,
    String? ongId,
    String? createdBy,
    String? name,
    String? species,
    String? breed,
    String? gender,
    String? size,
    String? ageEstimate,
    String? rescueStory,
    String? behaviorNotes,
    String? photoUrl,
    List<String>? galleryPhotos,
    bool? isCastrated,
    bool? isVaccinated,
    bool? isDewormed,
    String? specialNeeds,
    String? temporaryHomeId,
    String? status,
    bool? isPublicAdoption,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShelterAnimal(
      id: id ?? this.id,
      ongId: ongId ?? this.ongId,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      size: size ?? this.size,
      ageEstimate: ageEstimate ?? this.ageEstimate,
      rescueStory: rescueStory ?? this.rescueStory,
      behaviorNotes: behaviorNotes ?? this.behaviorNotes,
      photoUrl: photoUrl ?? this.photoUrl,
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
      isCastrated: isCastrated ?? this.isCastrated,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      isDewormed: isDewormed ?? this.isDewormed,
      specialNeeds: specialNeeds ?? this.specialNeeds,
      temporaryHomeId: temporaryHomeId ?? this.temporaryHomeId,
      status: status ?? this.status,
      isPublicAdoption: isPublicAdoption ?? this.isPublicAdoption,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ongName: ongName,
      ongCity: ongCity,
      ongState: ongState,
      ongPhone: ongPhone,
    );
  }
}
