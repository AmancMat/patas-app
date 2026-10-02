class VetPlan {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String billingCycle; // 'monthly', 'annual'
  final bool isActive;

  VetPlan({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.billingCycle = 'monthly',
    this.isActive = true,
  });

  factory VetPlan.fromMap(Map<String, dynamic> map) {
    return VetPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      billingCycle: map['billing_cycle'] ?? 'monthly',
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'billing_cycle': billingCycle,
      'is_active': isActive,
    };
  }
}

class VetSubscription {
  final String id;
  final String vetId;
  final String userId;
  final String planId;
  final String status; // 'trial', 'active', 'grace_period', 'past_due', 'canceled'
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEndsAt;
  final String? asaasCustomerId;
  final String? asaasSubscriptionId;
  final DateTime? createdAt;

  VetSubscription({
    required this.id,
    required this.vetId,
    required this.userId,
    required this.planId,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialEndsAt,
    this.asaasCustomerId,
    this.asaasSubscriptionId,
    this.createdAt,
  });

  bool get isAdimplente =>
      status == 'trial' || status == 'active' || status == 'grace_period';

  bool get isTrial => status == 'trial';
  bool get isPastDue => status == 'past_due';

  int get remainingTrialDays {
    if (trialEndsAt == null) return 0;
    final diff = trialEndsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory VetSubscription.fromMap(Map<String, dynamic> map) {
    return VetSubscription(
      id: map['id'] ?? '',
      vetId: map['vet_id'] ?? '',
      userId: map['user_id'] ?? '',
      planId: map['plan_id'] ?? '',
      status: map['status'] ?? 'trial',
      currentPeriodStart: map['current_period_start'] != null
          ? DateTime.tryParse(map['current_period_start'])
          : null,
      currentPeriodEnd: map['current_period_end'] != null
          ? DateTime.tryParse(map['current_period_end'])
          : null,
      trialEndsAt: map['trial_ends_at'] != null
          ? DateTime.tryParse(map['trial_ends_at'])
          : null,
      asaasCustomerId: map['asaas_customer_id'],
      asaasSubscriptionId: map['asaas_subscription_id'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }
}

class VetInvoice {
  final String id;
  final String subscriptionId;
  final String vetId;
  final String userId;
  final double amount;
  final String status; // 'pending', 'paid', 'overdue', 'canceled'
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? pixQrCode;
  final String? pixCopyPaste;
  final String? asaasPaymentId;
  final String? pdfUrl;
  final DateTime? createdAt;

  VetInvoice({
    required this.id,
    required this.subscriptionId,
    required this.vetId,
    required this.userId,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.pixQrCode,
    this.pixCopyPaste,
    this.asaasPaymentId,
    this.pdfUrl,
    this.createdAt,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';

  factory VetInvoice.fromMap(Map<String, dynamic> map) {
    return VetInvoice(
      id: map['id'] ?? '',
      subscriptionId: map['subscription_id'] ?? '',
      vetId: map['vet_id'] ?? '',
      userId: map['user_id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date']) : null,
      paidAt: map['paid_at'] != null ? DateTime.tryParse(map['paid_at']) : null,
      pixQrCode: map['pix_qr_code'],
      pixCopyPaste: map['pix_copy_paste'],
      asaasPaymentId: map['asaas_payment_id'],
      pdfUrl: map['pdf_url'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }
}
