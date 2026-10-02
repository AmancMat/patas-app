import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/features/encontra/services/encontra_service.dart';
import 'package:patas_web_app/src/features/encontra/screens/subscription_plans_page.dart';
import 'package:patas_web_app/src/features/encontra/screens/pix_payment_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionDashboardPage extends StatefulWidget {
  final String petId;
  const SubscriptionDashboardPage({super.key, required this.petId});

  @override
  State<SubscriptionDashboardPage> createState() => _SubscriptionDashboardPageState();
}

class _SubscriptionDashboardPageState extends State<SubscriptionDashboardPage> {
  final _encontraService = EncontraService();
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _subscription;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final sub = await _encontraService.getMySubscription(petId: widget.petId);
      List<Map<String, dynamic>> invoices = [];
      if (sub != null) {
        invoices = await _encontraService.getMyInvoices(subscriptionId: sub['id']);
      }
      if (mounted) {
        setState(() {
          _subscription = sub;
          _invoices = invoices;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do dashboard financeiro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Gera a lista de faturamentos projetados para os próximos 6 meses
  List<Map<String, dynamic>> _generateProjections(Map<String, dynamic> sub) {
    final List<Map<String, dynamic>> projections = [];
    DateTime referenceDate = DateTime.now();

    if (sub['status'] == 'trial') {
      referenceDate = DateTime.parse(sub['trial_ends_at']);
    } else if (sub['current_period_end'] != null) {
      referenceDate = DateTime.parse(sub['current_period_end']);
    } else {
      referenceDate = DateTime.now().add(const Duration(days: 14));
    }

    final plan = sub['subscription_plans'];
    final planName = plan != null ? plan['name'] : 'Plano Mensal';
    final priceInCents = plan != null ? plan['price_in_cents'] : 990;
    final price = priceInCents / 100;

    for (int i = 1; i <= 6; i++) {
      final nextDate = DateTime(
        referenceDate.year,
        referenceDate.month + i,
        referenceDate.day,
      );
      projections.add({
        'date': nextDate,
        'value': price,
        'name': planName,
      });
    }

    return projections;
  }

  Future<void> _handlePaymentAction() async {
    // Se não há assinatura, ou se ela está bloqueada/inativa, envia para os planos
    if (_subscription == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => SubscriptionPlansPage(petId: widget.petId)),
      ).then((_) => _loadDashboardData());
      return;
    }

    // Procura por alguma fatura pendente
    final pendingInvoice = _invoices.firstWhere(
      (inv) => inv['status'] == 'pending',
      orElse: () => {},
    );

    if (pendingInvoice.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PixPaymentPage(invoice: pendingInvoice),
        ),
      ).then((_) => _loadDashboardData());
    } else {
      // Se não há fatura pendente, redireciona para a contratação de planos para reativar/mudar
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => SubscriptionPlansPage(petId: widget.petId)),
      ).then((_) => _loadDashboardData());
    }
  }

  Widget _buildStatusCard(Map<String, dynamic> sub, bool isDark) {
    final status = sub['status'] ?? 'inactive';
    final hasPendingInvoice = _invoices.any((inv) => inv['status'] == 'pending');
    Color statusColor = Colors.grey;
    String statusTitle = 'Inativa';
    String statusDesc = 'O serviço de localização das tags está suspenso.';
    IconData statusIcon = Icons.error_outline;

    if (status == 'trial') {
      statusColor = Colors.green.shade600;
      statusTitle = 'Período de Testes (Trial)';
      final trialEnds = DateTime.parse(sub['trial_ends_at']);
      final daysLeft = trialEnds.difference(DateTime.now()).inDays;
      statusDesc = 'Você possui $daysLeft dias restantes de teste grátis.';
      statusIcon = Icons.timer_outlined;
    } else if (status == 'active') {
      statusColor = AppColors.patasColor;
      statusTitle = 'Assinatura Ativa';
      final currentEnd = DateTime.parse(sub['current_period_end']);
      final formattedDate = DateFormat('dd/MM/yyyy').format(currentEnd);
      statusDesc = 'Serviço ativo. Próxima renovação prevista para $formattedDate.';
      statusIcon = Icons.verified_user_outlined;
    } else if (status == 'grace_period') {
      statusColor = Colors.orange;
      statusTitle = 'Período de Tolerância';
      final graceEnds = DateTime.parse(sub['grace_period_ends_at']);
      final daysLeft = graceEnds.difference(DateTime.now()).inDays;
      statusDesc = 'Pagamento pendente. O monitoramento será bloqueado em $daysLeft dias.';
      statusIcon = Icons.warning_amber_outlined;
    } else if (status == 'past_due') {
      statusColor = Colors.red;
      statusTitle = 'Serviço Suspenso';
      statusDesc = 'O serviço de avistamentos geolocalizados está bloqueado por atraso.';
      statusIcon = Icons.block_outlined;
    }

    return Card(
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDesc,
                        style: TextStyle(
                          fontFamily: 'Roboto_flex',
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status == 'past_due' || status == 'grace_period' || status == 'inactive' || status == 'trial') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handlePaymentAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  status == 'past_due'
                      ? 'Reativar Proteção'
                      : hasPendingInvoice
                          ? 'Pagar Fatura Pendente'
                          : status == 'trial'
                              ? 'Ver Planos de Assinatura'
                              : 'Regularizar Pagamento',
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySubscriptionCard(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sem Proteção Ativa',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você ainda não possui assinatura. Ative um plano para acompanhar o último avistamento de suas tags inteligentes.',
              style: TextStyle(
                fontFamily: 'Roboto_flex',
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handlePaymentAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Conhecer Planos',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesHistory(bool isDark) {
    if (_invoices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Nenhum pagamento registrado no histórico.',
          style: TextStyle(
            fontFamily: 'Roboto_flex',
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final amount = (inv['amount_in_cents'] ?? 0) / 100;
        final isPaid = inv['status'] == 'paid';
        
        String periodText = 'Período não definido';
        if (inv['period_start'] != null && inv['period_end'] != null) {
          final start = DateFormat('dd/MM/yyyy').format(DateTime.parse(inv['period_start']));
          final end = DateFormat('dd/MM/yyyy').format(DateTime.parse(inv['period_end']));
          periodText = '$start a $end';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
                color: isPaid ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'R\$ ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cobertura: $periodText',
                      style: TextStyle(
                        fontFamily: 'Roboto_flex',
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPaid ? 'PAGO' : 'PENDENTE',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectionsList(Map<String, dynamic> sub, bool isDark) {
    final projections = _generateProjections(sub);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projections.length,
      itemBuilder: (context, index) {
        final proj = projections[index];
        final formattedDate = DateFormat('dd/MM/yyyy').format(proj['date']);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.01) : const Color(0xFFFAFBFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previsão: $formattedDate',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
                    ),
                  ),
                  Text(
                    proj['name'],
                    style: TextStyle(
                      fontFamily: 'Roboto_flex',
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              Text(
                'R\$ ${proj['value'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    // Coluna 1: Status e Histórico de Pagamentos (Lado Esquerdo no Desktop)
    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_subscription != null)
          _buildStatusCard(_subscription!, isDark)
        else
          _buildEmptySubscriptionCard(isDark),
        const SizedBox(height: 28),
        Text(
          'Histórico de Pagamentos e Cobertura',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
          ),
        ),
        const SizedBox(height: 12),
        _buildInvoicesHistory(isDark),
      ],
    );

    // Coluna 2: Previsões e Painel de Testes (Lado Direito no Desktop)
    final sideColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_subscription != null) ...[
          Text(
            'Previsão de Cobranças Futuras (Próximos 6 meses)',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apenas para fins informativos e planejamento financeiro.',
            style: TextStyle(
              fontFamily: 'Roboto_flex',
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          _buildProjectionsList(_subscription!, isDark),
          const SizedBox(height: 28),
        ],
        // Seção de Simulação Local (Mocks)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Controle de Testes Locais (Mocks)',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Use os botões abaixo para simular os diferentes estados visuais e lógicos do ciclo de cobrança de forma instantânea:',
                style: TextStyle(
                  fontFamily: 'Roboto_flex',
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _generateTrialMock,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                    child: const Text('Simular Trial (10 dias restantes)', style: TextStyle(fontSize: 11, color: Colors.orange, fontFamily: 'Fredoka')),
                  ),
                  OutlinedButton(
                    onPressed: _generateActiveMock,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                    child: const Text('Simular Assinatura Ativa (Histórico)', style: TextStyle(fontSize: 11, color: Colors.orange, fontFamily: 'Fredoka')),
                  ),
                  OutlinedButton(
                    onPressed: _generateGracePeriodMock,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                    child: const Text('Simular Tolerância (5 dias restantes)', style: TextStyle(fontSize: 11, color: Colors.orange, fontFamily: 'Fredoka')),
                  ),
                  OutlinedButton(
                    onPressed: _resetMock,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    child: const Text('Limpar Dados (Reset)', style: TextStyle(fontSize: 11, color: Colors.red, fontFamily: 'Fredoka')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: 'Minha Assinatura',
        subtitle: 'Status, faturas e renovações do pet',
        showBackButton: true,
        leadingIcon: const Icon(
          Icons.card_membership_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.patasColor),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.patasColor)))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.patasColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 140.0),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Lado Esquerdo: Status do plano e histórico
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 40.0),
                                  child: mainColumn,
                                ),
                              ),
                              // Lado Direito: Projeção de cobranças futuras e Mocks de simulação
                              Expanded(
                                flex: 4,
                                child: sideColumn,
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              mainColumn,
                              const SizedBox(height: 32),
                              sideColumn,
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _generateTrialMock() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Limpa dados anteriores do pet específico
      final existingSub = await _client.from('subscriptions').select().eq('pet_id', widget.petId).maybeSingle();
      if (existingSub != null) {
        await _client.from('invoices').delete().eq('subscription_id', existingSub['id']);
        await _client.from('subscriptions').delete().eq('id', existingSub['id']);
      }

      // Garante plano
      final planDb = await _client.from('subscription_plans').select().eq('id', 'plan-mensal-patas-encontra').maybeSingle();
      if (planDb == null) {
        await _client.from('subscription_plans').insert({
          'id': 'plan-mensal-patas-encontra',
          'name': 'Mensal',
          'description': 'Cobrado mensalmente',
          'price_in_cents': 599,
          'billing_interval': 'month',
          'is_active': true,
        });
      }

      // Cria assinatura de trial vinculada ao pet
      final now = DateTime.now();
      await _client.from('subscriptions').insert({
        'user_id': user.id,
        'pet_id': widget.petId,
        'plan_id': 'plan-mensal-patas-encontra',
        'status': 'trial',
        'trial_started_at': now.toIso8601String(),
        'trial_ends_at': now.add(const Duration(days: 10)).toIso8601String(),
      });

      await _loadDashboardData();
    } catch (e) {
      debugPrint('Erro mock trial: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateActiveMock() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Limpa dados anteriores do pet específico
      final existingSub = await _client.from('subscriptions').select().eq('pet_id', widget.petId).maybeSingle();
      if (existingSub != null) {
        await _client.from('invoices').delete().eq('subscription_id', existingSub['id']);
        await _client.from('subscriptions').delete().eq('id', existingSub['id']);
      }

      // Garante plano
      final planDb = await _client.from('subscription_plans').select().eq('id', 'plan-mensal-patas-encontra').maybeSingle();
      if (planDb == null) {
        await _client.from('subscription_plans').insert({
          'id': 'plan-mensal-patas-encontra',
          'name': 'Mensal',
          'description': 'Cobrado mensalmente',
          'price_in_cents': 599,
          'billing_interval': 'month',
          'is_active': true,
        });
      }

      // Cria assinatura ativa vinculada ao pet
      final now = DateTime.now();
      final sub = await _client.from('subscriptions').insert({
        'user_id': user.id,
        'pet_id': widget.petId,
        'plan_id': 'plan-mensal-patas-encontra',
        'status': 'active',
        'current_period_start': now.subtract(const Duration(days: 15)).toIso8601String(),
        'current_period_end': now.add(const Duration(days: 15)).toIso8601String(),
        'grace_period_ends_at': now.add(const Duration(days: 22)).toIso8601String(),
      }).select().single();

      // Cria histórico de 3 faturas pagas (invoices)
      // Fatura 1: há 75 dias
      await _client.from('invoices').insert({
        'subscription_id': sub['id'],
        'user_id': user.id,
        'amount_in_cents': 599,
        'status': 'paid',
        'pix_txid': 'tx-mock-1',
        'due_date': now.subtract(const Duration(days: 75)).toIso8601String(),
        'paid_at': now.subtract(const Duration(days: 75)).toIso8601String(),
        'period_start': now.subtract(const Duration(days: 75)).toIso8601String(),
        'period_end': now.subtract(const Duration(days: 45)).toIso8601String(),
      });

      // Fatura 2: há 45 dias
      await _client.from('invoices').insert({
        'subscription_id': sub['id'],
        'user_id': user.id,
        'amount_in_cents': 599,
        'status': 'paid',
        'pix_txid': 'tx-mock-2',
        'due_date': now.subtract(const Duration(days: 45)).toIso8601String(),
        'paid_at': now.subtract(const Duration(days: 45)).toIso8601String(),
        'period_start': now.subtract(const Duration(days: 45)).toIso8601String(),
        'period_end': now.subtract(const Duration(days: 15)).toIso8601String(),
      });

      // Fatura 3: há 15 dias (atual período ativo)
      await _client.from('invoices').insert({
        'subscription_id': sub['id'],
        'user_id': user.id,
        'amount_in_cents': 599,
        'status': 'paid',
        'pix_txid': 'tx-mock-3',
        'due_date': now.subtract(const Duration(days: 15)).toIso8601String(),
        'paid_at': now.subtract(const Duration(days: 15)).toIso8601String(),
        'period_start': now.subtract(const Duration(days: 15)).toIso8601String(),
        'period_end': now.add(const Duration(days: 15)).toIso8601String(),
      });

      await _loadDashboardData();
    } catch (e) {
      debugPrint('Erro mock ativo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateGracePeriodMock() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Busca assinatura existente ou garante
      var sub = await _client.from('subscriptions').select().eq('pet_id', widget.petId).maybeSingle();
      if (sub == null) {
        await _generateActiveMock();
        sub = await _client.from('subscriptions').select().eq('pet_id', widget.petId).single();
      }

      final now = DateTime.now();
      
      // Atualiza status da assinatura para grace_period
      await _client.from('subscriptions').update({
        'status': 'grace_period',
        'current_period_end': now.subtract(const Duration(days: 2)).toIso8601String(),
        'grace_period_ends_at': now.add(const Duration(days: 5)).toIso8601String(),
      }).eq('id', sub['id']);

      // Insere uma fatura pendente (atrasada)
      await _client.from('invoices').insert({
        'subscription_id': sub['id'],
        'user_id': user.id,
        'amount_in_cents': 599,
        'status': 'pending',
        'pix_copia_cola': '00020101021226870014br.gov.bcb.pix2565api.asaas.com/v1/charge/pix/patas-mock-grace-key',
        'pix_qr_code_url': 'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=patas-payment-grace-mock',
        'pix_txid': 'tx-mock-grace',
        'due_date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'period_start': now.subtract(const Duration(days: 2)).toIso8601String(),
        'period_end': now.add(const Duration(days: 28)).toIso8601String(),
      });

      await _loadDashboardData();
    } catch (e) {
      debugPrint('Erro mock grace_period: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetMock() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Limpa dados anteriores do pet específico
      final existingSub = await _client.from('subscriptions').select().eq('pet_id', widget.petId).maybeSingle();
      if (existingSub != null) {
        await _client.from('invoices').delete().eq('subscription_id', existingSub['id']);
        await _client.from('subscriptions').delete().eq('id', existingSub['id']);
      }

      await _loadDashboardData();
    } catch (e) {
      debugPrint('Erro reset: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
