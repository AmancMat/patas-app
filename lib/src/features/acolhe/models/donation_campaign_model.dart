class DonationCampaign {
  final String id;
  final String ongId;
  final String? ongName;
  final String? ongPhotoUrl;
  final String title;
  final String? description;
  final String? imageUrl;
  final String category; // 'Ração & Alimento', 'Saúde & Cirurgia', 'Reforma & Abrigo', 'Geral'
  final String goalType; // 'money' ou 'items'
  final double targetAmount;
  final double currentAmount;
  final String unitLabel; // 'R$', 'kg', 'sacos', etc.
  final String? pixKey;
  final String? pixKeyType; // 'cnpj', 'email', 'telefone', 'aleatoria'
  final String? solanaWallet; // Endereço público Solana da ONG
  final String? beneficiaryPetName;
  final String? beneficiaryPetPhoto;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? endsAt;

  DonationCampaign({
    required this.id,
    required this.ongId,
    this.ongName,
    this.ongPhotoUrl,
    required this.title,
    this.description,
    this.imageUrl,
    this.category = 'Ração & Alimento',
    this.goalType = 'money',
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.unitLabel = 'R\$',
    this.pixKey,
    this.pixKeyType = 'cnpj',
    this.solanaWallet,
    this.beneficiaryPetName,
    this.beneficiaryPetPhoto,
    this.isActive = true,
    required this.createdAt,
    this.endsAt,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final ratio = currentAmount / targetAmount;
    return ratio.clamp(0.0, 1.0);
  }

  /// Razão real sem clamp (ex: 1.25 para 125%)
  double get rawProgressRatio {
    if (targetAmount <= 0) return 0.0;
    return currentAmount / targetAmount;
  }

  /// Porcentagem inteira real (ex: 45, 100, 125)
  int get progressPercentInt {
    return (rawProgressRatio * 100).round();
  }

  /// Indica se a meta foi atingida ou ultrapassada
  bool get isGoalReached => currentAmount >= targetAmount && targetAmount > 0;

  /// Indica se a meta foi estritamente ultrapassada (> 100%)
  bool get isGoalExceeded => currentAmount > targetAmount && targetAmount > 0;

  /// Percentual que passou além da meta (ex: 25% se atingiu 125%)
  int get exceededPercentInt =>
      progressPercentInt > 100 ? (progressPercentInt - 100) : 0;

  /// Rótulo descritivo do status da meta
  String get goalStatusBadgeText {
    if (isGoalExceeded) {
      return '🚀 Meta Superada em $exceededPercentInt%! ($progressPercentInt%)';
    } else if (isGoalReached) {
      return '🎉 Meta 100% Batida!';
    } else {
      return '$progressPercentInt% da meta';
    }
  }

  String get formattedCurrent {
    if (goalType == 'money') {
      return 'R\$ ${currentAmount.toStringAsFixed(2).replaceAll('.', ',')}';
    }
    return '${currentAmount.toStringAsFixed(0)} $unitLabel';
  }

  String get formattedTarget {
    if (goalType == 'money') {
      return 'R\$ ${targetAmount.toStringAsFixed(2).replaceAll('.', ',')}';
    }
    return '${targetAmount.toStringAsFixed(0)} $unitLabel';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ong_id': ongId,
      'ong_name': ongName,
      'ong_photo_url': ongPhotoUrl,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'goal_type': goalType,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'unit_label': unitLabel,
      'pix_key': pixKey,
      'pix_key_type': pixKeyType,
      'solana_wallet': solanaWallet,
      'beneficiary_pet_name': beneficiaryPetName,
      'beneficiary_pet_photo': beneficiaryPetPhoto,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
    };
  }

  factory DonationCampaign.fromJson(Map<String, dynamic> json) {
    return DonationCampaign(
      id: json['id'] as String,
      ongId: json['ong_id'] as String,
      ongName: json['ong_name'] as String?,
      ongPhotoUrl: json['ong_photo_url'] as String?,
      title: json['title'] as String? ?? 'Campanha de Doação',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String? ?? 'Ração & Alimento',
      goalType: json['goal_type'] as String? ?? 'money',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 1000.0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      unitLabel: json['unit_label'] as String? ?? 'R\$',
      pixKey: json['pix_key'] as String?,
      pixKeyType: json['pix_key_type'] as String? ?? 'cnpj',
      solanaWallet: json['solana_wallet'] as String?,
      beneficiaryPetName: json['beneficiary_pet_name'] as String?,
      beneficiaryPetPhoto: json['beneficiary_pet_photo'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'] as String)
          : null,
    );
  }

  DonationCampaign copyWith({
    String? id,
    String? ongId,
    String? ongName,
    String? ongPhotoUrl,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    String? goalType,
    double? targetAmount,
    double? currentAmount,
    String? unitLabel,
    String? pixKey,
    String? pixKeyType,
    String? solanaWallet,
    String? beneficiaryPetName,
    String? beneficiaryPetPhoto,
    bool? isActive,
    DateTime? createdAt,
    DateTime? endsAt,
  }) {
    return DonationCampaign(
      id: id ?? this.id,
      ongId: ongId ?? this.ongId,
      ongName: ongName ?? this.ongName,
      ongPhotoUrl: ongPhotoUrl ?? this.ongPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      goalType: goalType ?? this.goalType,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      unitLabel: unitLabel ?? this.unitLabel,
      pixKey: pixKey ?? this.pixKey,
      pixKeyType: pixKeyType ?? this.pixKeyType,
      solanaWallet: solanaWallet ?? this.solanaWallet,
      beneficiaryPetName: beneficiaryPetName ?? this.beneficiaryPetName,
      beneficiaryPetPhoto: beneficiaryPetPhoto ?? this.beneficiaryPetPhoto,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      endsAt: endsAt ?? this.endsAt,
    );
  }
}
