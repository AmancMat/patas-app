class ShelterDonationReceiptModel {
  final String id;
  final String campaignId;
  final String? donorUserId;
  final String? donorPetId;
  final String? donorName;
  final String? donorPhoto;
  final double amount;
  final String currency;
  final double? originalAmount;
  final String tokenSymbol;
  final String paymentMethod;
  final String? txSignature;
  final String status;
  final DateTime createdAt;

  const ShelterDonationReceiptModel({
    required this.id,
    required this.campaignId,
    this.donorUserId,
    this.donorPetId,
    this.donorName,
    this.donorPhoto,
    required this.amount,
    this.currency = 'BRL',
    this.originalAmount,
    this.tokenSymbol = 'BRL',
    required this.paymentMethod,
    this.txSignature,
    this.status = 'confirmed',
    required this.createdAt,
  });

  factory ShelterDonationReceiptModel.fromJson(Map<String, dynamic> json) {
    return ShelterDonationReceiptModel(
      id: json['id'] as String? ?? '',
      campaignId: json['campaign_id'] as String? ?? '',
      donorUserId: json['donor_user_id'] as String?,
      donorPetId: json['donor_pet_id'] as String?,
      donorName: json['donor_name'] as String?,
      donorPhoto: json['donor_photo'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'BRL',
      originalAmount: (json['original_amount'] as num?)?.toDouble(),
      tokenSymbol: json['token_symbol'] as String? ?? 'BRL',
      paymentMethod: json['payment_method'] as String? ?? 'pix',
      txSignature: json['tx_signature'] as String?,
      status: json['status'] as String? ?? 'confirmed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaign_id': campaignId,
      'donor_user_id': donorUserId,
      'donor_pet_id': donorPetId,
      'donor_name': donorName,
      'donor_photo': donorPhoto,
      'amount': amount,
      'currency': currency,
      'original_amount': originalAmount,
      'token_symbol': tokenSymbol,
      'payment_method': paymentMethod,
      'tx_signature': txSignature,
      'status': status,
    };
  }

  /// Retorna o rótulo amigável do método de pagamento
  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'solana_pay':
        return 'Solana Pay (Web3)';
      case 'pix':
        return 'PIX Direto';
      case 'cartao':
        return 'Cartão de Crédito';
      default:
        return paymentMethod.toUpperCase();
    }
  }
}
