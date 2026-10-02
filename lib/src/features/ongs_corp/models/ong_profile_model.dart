class OngProfile {
  final String id;
  final String userId;
  final String name;
  final String? cnpj;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final List<String>? activityAreas; // Resgate, Adoção, Tratamento, etc.
  final int? animalsUnderCare;
  final String? yearsOfOperation;
  final String? donationPix;
  final String? bankDetails;
  final String? currentNeeds;
  final String? photoUrl;
  final String? coverUrl;
  final String? about;
  final DateTime createdAt;

  OngProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.cnpj,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.activityAreas,
    this.animalsUnderCare,
    this.yearsOfOperation,
    this.donationPix,
    this.bankDetails,
    this.currentNeeds,
    this.photoUrl,
    this.coverUrl,
    this.about,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'cnpj': cnpj,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'activity_areas': activityAreas,
      'animals_under_care': animalsUnderCare,
      'years_of_operation': yearsOfOperation,
      'donation_pix': donationPix,
      'bank_details': bankDetails,
      'current_needs': currentNeeds,
      'photo_url': photoUrl,
      'cover_url': coverUrl,
      'about': about,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OngProfile.fromJson(Map<String, dynamic> json) {
    return OngProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      cnpj: json['cnpj'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      activityAreas: json['activity_areas'] != null
          ? List<String>.from(json['activity_areas'] as List)
          : null,
      animalsUnderCare: json['animals_under_care'] as int?,
      yearsOfOperation: json['years_of_operation'] as String?,
      donationPix: json['donation_pix'] as String?,
      bankDetails: json['bank_details'] as String?,
      currentNeeds: json['current_needs'] as String?,
      photoUrl: json['photo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      about: json['about'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  OngProfile copyWith({
    String? name,
    String? cnpj,
    String? address,
    String? phone,
    String? email,
    String? website,
    List<String>? activityAreas,
    int? animalsUnderCare,
    String? yearsOfOperation,
    String? donationPix,
    String? bankDetails,
    String? currentNeeds,
    String? photoUrl,
    String? coverUrl,
    String? about,
  }) {
    return OngProfile(
      id: id,
      userId: userId,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      activityAreas: activityAreas ?? this.activityAreas,
      animalsUnderCare: animalsUnderCare ?? this.animalsUnderCare,
      yearsOfOperation: yearsOfOperation ?? this.yearsOfOperation,
      donationPix: donationPix ?? this.donationPix,
      bankDetails: bankDetails ?? this.bankDetails,
      currentNeeds: currentNeeds ?? this.currentNeeds,
      photoUrl: photoUrl ?? this.photoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      about: about ?? this.about,
      createdAt: createdAt,
    );
  }
}
