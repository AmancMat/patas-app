import 'package:flutter/material.dart';
import 'shelter_animal_model.dart';

class TemporaryHome {
  final String id;
  final String ongId;
  final String? volunteerUserId;
  final String? createdBy;
  final String name;
  final String phone;
  final String? email;
  final String? city;
  final String? neighborhood;
  final String? address;
  final String housingType; // 'casa', 'apartamento', 'sitio'
  final bool hasYard;
  final bool hasOtherPets;
  final String? otherPetsDetails;
  final String allowedSpecies; // 'canino', 'felino', 'ambos'
  final List<String> allowedSizes; // 'pequeno', 'medio', 'grande'
  final bool canAdministerMedication;
  final int maxCapacity;
  final String status; // 'disponivel', 'ocupado', 'pausado', 'candidatura_pendente'
  final bool isCommunityVolunteer;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Animais acolhidos atualmente alocados neste lar
  final List<ShelterAnimal> currentAnimals;

  TemporaryHome({
    required this.id,
    required this.ongId,
    this.volunteerUserId,
    this.createdBy,
    required this.name,
    required this.phone,
    this.email,
    this.city,
    this.neighborhood,
    this.address,
    this.housingType = 'casa',
    this.hasYard = true,
    this.hasOtherPets = false,
    this.otherPetsDetails,
    this.allowedSpecies = 'ambos',
    this.allowedSizes = const ['pequeno', 'medio'],
    this.canAdministerMedication = false,
    this.maxCapacity = 1,
    this.status = 'disponivel',
    this.isCommunityVolunteer = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.currentAnimals = const [],
  });

  factory TemporaryHome.fromJson(
    Map<String, dynamic> json, {
    List<ShelterAnimal> animals = const [],
  }) {
    List<String> sizes = [];
    if (json['allowed_sizes'] != null) {
      if (json['allowed_sizes'] is List) {
        sizes = (json['allowed_sizes'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return TemporaryHome(
      id: json['id'] as String,
      ongId: json['ong_id'] as String,
      volunteerUserId: json['volunteer_user_id'] as String?,
      createdBy: json['created_by'] as String?,
      name: json['name'] as String? ?? 'Voluntário',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      city: json['city'] as String?,
      neighborhood: json['neighborhood'] as String?,
      address: json['address'] as String?,
      housingType: json['housing_type'] as String? ?? 'casa',
      hasYard: json['has_yard'] as bool? ?? true,
      hasOtherPets: json['has_other_pets'] as bool? ?? false,
      otherPetsDetails: json['other_pets_details'] as String?,
      allowedSpecies: json['allowed_species'] as String? ?? 'ambos',
      allowedSizes: sizes.isNotEmpty ? sizes : const ['pequeno', 'medio'],
      canAdministerMedication:
          json['can_administer_medication'] as bool? ?? false,
      maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'disponivel',
      isCommunityVolunteer:
          json['is_community_volunteer'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      currentAnimals: animals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'ong_id': ongId,
      if (volunteerUserId != null) 'volunteer_user_id': volunteerUserId,
      if (createdBy != null) 'created_by': createdBy,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (city != null) 'city': city,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (address != null) 'address': address,
      'housing_type': housingType,
      'has_yard': hasYard,
      'has_other_pets': hasOtherPets,
      if (otherPetsDetails != null) 'other_pets_details': otherPetsDetails,
      'allowed_species': allowedSpecies,
      'allowed_sizes': allowedSizes,
      'can_administer_medication': canAdministerMedication,
      'max_capacity': maxCapacity,
      'status': status,
      'is_community_volunteer': isCommunityVolunteer,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get occupiedSpots => currentAnimals.length;
  int get freeSpots => (maxCapacity - currentAnimals.length).clamp(0, 99);
  bool get isFull => currentAnimals.length >= maxCapacity;

  String get speciesLabel {
    switch (allowedSpecies) {
      case 'canino':
        return 'Só Cães';
      case 'felino':
        return 'Só Gatos';
      case 'ambos':
      default:
        return 'Cães & Gatos';
    }
  }

  String get housingLabel {
    switch (housingType) {
      case 'apartamento':
        return 'Apartamento';
      case 'sitio':
        return 'Sítio / Chácara';
      case 'casa':
      default:
        return hasYard ? 'Casa c/ quintal' : 'Casa';
    }
  }

  Color get statusColor {
    if (status == 'candidatura_pendente') return Colors.amber;
    if (status == 'pausado') return Colors.grey;
    if (isFull) return Colors.orange;
    return Colors.green;
  }

  String get statusLabel {
    if (status == 'candidatura_pendente') return 'Candidatura';
    if (status == 'pausado') return 'Pausado';
    if (isFull) return 'Lotado ($occupiedSpots/$maxCapacity)';
    return 'Disponível ($freeSpots ${freeSpots == 1 ? 'vaga' : 'vagas'})';
  }

  TemporaryHome copyWith({
    String? id,
    String? ongId,
    String? volunteerUserId,
    String? createdBy,
    String? name,
    String? phone,
    String? email,
    String? city,
    String? neighborhood,
    String? address,
    String? housingType,
    bool? hasYard,
    bool? hasOtherPets,
    String? otherPetsDetails,
    String? allowedSpecies,
    List<String>? allowedSizes,
    bool? canAdministerMedication,
    int? maxCapacity,
    String? status,
    bool? isCommunityVolunteer,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ShelterAnimal>? currentAnimals,
  }) {
    return TemporaryHome(
      id: id ?? this.id,
      ongId: ongId ?? this.ongId,
      volunteerUserId: volunteerUserId ?? this.volunteerUserId,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      address: address ?? this.address,
      housingType: housingType ?? this.housingType,
      hasYard: hasYard ?? this.hasYard,
      hasOtherPets: hasOtherPets ?? this.hasOtherPets,
      otherPetsDetails: otherPetsDetails ?? this.otherPetsDetails,
      allowedSpecies: allowedSpecies ?? this.allowedSpecies,
      allowedSizes: allowedSizes ?? this.allowedSizes,
      canAdministerMedication:
          canAdministerMedication ?? this.canAdministerMedication,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      status: status ?? this.status,
      isCommunityVolunteer: isCommunityVolunteer ?? this.isCommunityVolunteer,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentAnimals: currentAnimals ?? this.currentAnimals,
    );
  }
}
