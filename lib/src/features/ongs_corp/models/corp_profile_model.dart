class CorpProfile {
  final String id;
  final String userId;
  final String name;
  final String cnpj;
  final String category; // Pet Shop, Clínica Veterinária, Hotel, etc.
  final String address;
  final String phone;
  final String email;
  final String? website;
  final String? openingHours;
  final String? workingDays;
  final List<String>? servicesOffered;
  final List<String>? paymentMethods;
  final String? photoUrl;
  final String? coverUrl;
  final String? about;
  final DateTime createdAt;

  CorpProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.cnpj,
    required this.category,
    required this.address,
    required this.phone,
    required this.email,
    this.website,
    this.openingHours,
    this.workingDays,
    this.servicesOffered,
    this.paymentMethods,
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
      'category': category,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'opening_hours': openingHours,
      'working_days': workingDays,
      'services_offered': servicesOffered,
      'payment_methods': paymentMethods,
      'photo_url': photoUrl,
      'cover_url': coverUrl,
      'about': about,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CorpProfile.fromJson(Map<String, dynamic> json) {
    return CorpProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      cnpj: json['cnpj'] as String,
      category: json['category'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      website: json['website'] as String?,
      openingHours: json['opening_hours'] as String?,
      workingDays: json['working_days'] as String?,
      servicesOffered: json['services_offered'] != null
          ? List<String>.from(json['services_offered'] as List)
          : null,
      paymentMethods: json['payment_methods'] != null
          ? List<String>.from(json['payment_methods'] as List)
          : null,
      photoUrl: json['photo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      about: json['about'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  CorpProfile copyWith({
    String? name,
    String? cnpj,
    String? category,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? openingHours,
    String? workingDays,
    List<String>? servicesOffered,
    List<String>? paymentMethods,
    String? photoUrl,
    String? coverUrl,
    String? about,
  }) {
    return CorpProfile(
      id: id,
      userId: userId,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      workingDays: workingDays ?? this.workingDays,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      photoUrl: photoUrl ?? this.photoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      about: about ?? this.about,
      createdAt: createdAt,
    );
  }
}
