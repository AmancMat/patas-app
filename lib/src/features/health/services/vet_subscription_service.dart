import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vet_subscription_model.dart';

class VetSubscriptionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Retorna os planos B2B disponíveis para veterinários
  Future<List<VetPlan>> getPlans() async {
    try {
      final data = await _client
          .from('vet_plans')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);

      if ((data as List).isNotEmpty) {
        return data.map((map) => VetPlan.fromMap(map)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar planos B2B no Supabase: $e');
    }

    // Retorno fallback padronizado
    return [
      VetPlan(
        id: 'vet-plan-mensal',
        name: 'Plano Pro Mensal',
        description: 'Perfil em destaque no mapa de busca, prontuário SOAP ilimitado e agendamento online.',
        price: 89.90,
        billingCycle: 'monthly',
      ),
      VetPlan(
        id: 'vet-plan-anual',
        name: 'Plano Pro Anual',
        description: 'Perfil em destaque no mapa de busca, prontuário SOAP ilimitado e agendamento online com 2 meses grátis.',
        price: 899.00,
        billingCycle: 'annual',
      ),
    ];
  }

  /// Retorna a assinatura ativa do veterinário
  Future<VetSubscription?> getSubscriptionForVet(String vetId) async {
    try {
      final data = await _client
          .from('vet_subscriptions')
          .select()
          .eq('vet_id', vetId)
          .maybeSingle();

      if (data != null) {
        return VetSubscription.fromMap(data);
      }
    } catch (e) {
      debugPrint('Erro ao buscar assinatura do veterinário $vetId: $e');
    }

    // Se não existir assinatura cadastrada no banco ainda, gera objeto de Trial 14 dias padrão
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      final now = DateTime.now();
      return VetSubscription(
        id: 'trial-temp-$vetId',
        vetId: vetId,
        userId: currentUser.id,
        planId: 'vet-plan-mensal',
        status: 'trial',
        currentPeriodStart: now,
        currentPeriodEnd: now.add(const Duration(days: 14)),
        trialEndsAt: now.add(const Duration(days: 14)),
        createdAt: now,
      );
    }
    return null;
  }

  /// Retorna o histórico de faturas do veterinário
  Future<List<VetInvoice>> getInvoicesForVet(String vetId) async {
    try {
      final data = await _client
          .from('vet_invoices')
          .select()
          .eq('vet_id', vetId)
          .order('created_at', ascending: false);

      if (data.isNotEmpty) {
        return (data as List).map((map) => VetInvoice.fromMap(map)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar faturas do veterinário $vetId: $e');
    }
    return [];
  }

  /// Gera cobrança B2B (PIX ou Cartão) via Edge Function com fallback local
  Future<VetInvoice?> createPaymentForVet({
    required String vetId,
    required VetPlan plan,
    required String paymentType, // 'PIX' ou 'CREDIT_CARD'
    String? cpf,
    Map<String, dynamic>? creditCard,
    Map<String, dynamic>? creditCardHolderInfo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Tenta invocar a Edge Function do Supabase (create-payment)
      final body = <String, dynamic>{
        'vet_id': vetId,
        'plan_id': plan.id,
        'billingType': paymentType,
        'amount': plan.price,
        if (cpf != null) 'cpf': cpf,
        if (creditCard != null) 'creditCard': creditCard,
        if (creditCardHolderInfo != null) 'creditCardHolderInfo': creditCardHolderInfo,
      };

      final response = await _client.functions.invoke('create-payment', body: body);

      if (response.data != null) {
        final invoiceMap = response.data['invoice'] ?? response.data;
        if (invoiceMap is Map && invoiceMap['id'] != null) {
          return VetInvoice.fromMap(Map<String, dynamic>.from(invoiceMap));
        }
      }
    } catch (e) {
      debugPrint('Aviso: Edge Function create-payment offline/dev. Gerando fatura de simulação local: $e');
    }

    // 2. Fallback de Desenvolvimento / Simulação Local
    final subId = 'sub-b2b-$vetId';
    final now = DateTime.now();
    final isAnnual = plan.billingCycle == 'annual';
    final periodDays = isAnnual ? 365 : 30;

    // Atualiza/Cria Assinatura local no Supabase se possível
    try {
      await _client.from('vet_subscriptions').upsert({
        'vet_id': vetId,
        'user_id': user.id,
        'plan_id': plan.id,
        'status': 'active',
        'current_period_start': now.toIso8601String(),
        'current_period_end': now.add(Duration(days: periodDays)).toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    } catch (_) {}

    final invoice = VetInvoice(
      id: 'inv-sim-${DateTime.now().millisecondsSinceEpoch}',
      subscriptionId: subId,
      vetId: vetId,
      userId: user.id,
      amount: plan.price,
      status: 'pending',
      dueDate: now.add(const Duration(days: 3)),
      pixQrCode: 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=00020126580014BR.GOV.BCB.PIX0136patas.saude.b2b@patas.online5204000053039865405${plan.price.toStringAsFixed(2)}5802BR5920PATAS+SAUDE+SERVICOS6009SAO+PAULO62070503***6304E2CA',
      pixCopyPaste: '00020126580014BR.GOV.BCB.PIX0136patas.saude.b2b@patas.online5204000053039865405${plan.price.toStringAsFixed(2)}5802BR5920PATAS+SAUDE+SERVICOS6009SAO+PAULO62070503***6304E2CA',
      createdAt: now,
    );

    try {
      await _client.from('vet_invoices').insert({
        'id': invoice.id,
        'subscription_id': invoice.subscriptionId,
        'vet_id': vetId,
        'user_id': user.id,
        'amount': invoice.amount,
        'status': 'pending',
        'due_date': invoice.dueDate?.toIso8601String(),
        'pix_qr_code': invoice.pixQrCode,
        'pix_copy_paste': invoice.pixCopyPaste,
        'created_at': now.toIso8601String(),
      });
    } catch (_) {}

    return invoice;
  }

  /// Verifica se o veterinário está adimplente
  Future<bool> checkVetIsAdimplente(String vetId) async {
    try {
      final res = await _client.rpc('check_vet_is_adimplente', params: {
        'p_vet_id': vetId,
      });
      if (res is bool) return res;
    } catch (_) {}

    final sub = await getSubscriptionForVet(vetId);
    return sub?.isAdimplente ?? true;
  }
}
