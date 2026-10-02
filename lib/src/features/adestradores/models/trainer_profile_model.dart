class TrainerProfile {
  final String id;
  final String userId;
  final String? companyId;
  final String fullName;
  final String? bio;
  final String? profilePhoto;
  final String? coverPhoto;
  final String? phone;
  final String? whatsapp;
  final String? instagram;
  final String? city;
  final String? state;
  final int serviceRadiusKm;
  final bool attendsHome;
  final bool attendsOnline;
  final bool attendsCenter;
  final String? trainingCenterAddress;
  final List<String> specialties;
  final List<String> certifications;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  TrainerProfile({
    required this.id,
    required this.userId,
    this.companyId,
    required this.fullName,
    this.bio,
    this.profilePhoto,
    this.coverPhoto,
    this.phone,
    this.whatsapp,
    this.instagram,
    this.city,
    this.state,
    this.serviceRadiusKm = 15,
    this.attendsHome = true,
    this.attendsOnline = false,
    this.attendsCenter = false,
    this.trainingCenterAddress,
    this.specialties = const ['Obediência Básica', 'Comportamento & Reatividade', 'Filhotes'],
    this.certifications = const [],
    this.rating = 5.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_id': companyId,
      'full_name': fullName,
      'bio': bio,
      'profile_photo': profilePhoto,
      'cover_photo': coverPhoto,
      'phone': phone,
      'whatsapp': whatsapp,
      'instagram': instagram,
      'city': city,
      'state': state,
      'service_radius_km': serviceRadiusKm,
      'attends_home': attendsHome,
      'attends_online': attendsOnline,
      'attends_center': attendsCenter,
      'training_center_address': trainingCenterAddress,
      'specialties': specialties,
      'certifications': certifications,
      'rating': rating,
      'review_count': reviewCount,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TrainerProfile.fromJson(Map<String, dynamic> json) {
    return TrainerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String?,
      fullName: json['full_name'] as String? ?? 'Adestrador Profissional',
      bio: json['bio'] as String?,
      profilePhoto: json['profile_photo'] as String?,
      coverPhoto: json['cover_photo'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      instagram: json['instagram'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toInt() ?? 15,
      attendsHome: json['attends_home'] as bool? ?? true,
      attendsOnline: json['attends_online'] as bool? ?? false,
      attendsCenter: json['attends_center'] as bool? ?? false,
      trainingCenterAddress: json['training_center_address'] as String?,
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'] as List)
          : const ['Obediência Básica', 'Comportamento & Reatividade', 'Filhotes'],
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'] as List)
          : const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
