import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/core/localization/localizations_ext.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/features/encontra/screens/pix_payment_page.dart';
import 'package:patas_web_app/src/features/encontra/screens/credit_card_checkout_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionPlansPage extends StatefulWidget {
  final String petId;
  const SubscriptionPlansPage({super.key, required this.petId});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  final _client = Supabase.instance.client;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'plan-mensal-patas-encontra',
      'name': 'Mensal',
      'price': 5.99,
      'billing': 'Cobrado mensalmente',
      'discount': null,
      'isPopular': true,
      'months': 1,
    },
    {
      'id': 'plan-anual-patas-encontra',
      'name': 'Anual',
      'price': 64.69,
      'billing': 'Cobrado anualmente',
      'discount': 'Economize 10%',
      'isPopular': false,
      'months': 12,
    }
  ];

  String _selectedPlanId = 'plan-mensal-patas-encontra';
  String _selectedPaymentMethod = 'PIX'; // 'PIX' ou 'CARD'

  void _navigateToCardCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreditCardCheckoutPage(
          petId: widget.petId,
          planId: _selectedPlanId,
          price: _plans.firstWhere((p) => p['id'] == _selectedPlanId)['price'],
          planName: _plans.firstWhere((p) => p['id'] == _selectedPlanId)['name'],
        ),
      ),
    ).then((paid) {
      if (paid == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _collectCpfAndCreateSubscription() async {
    final cpfController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('encontra.confirm_payment_dialog_title'),
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('encontra.pix_cpf_prompt'),
                style: TextStyle(fontFamily: 'Roboto_flex', fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: cpfController,
                keyboardType: TextInputType.number,
                maxLength: 14,
                decoration: InputDecoration(
                  labelText: 'CPF',
                  hintText: '000.000.000-00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o CPF';
                  final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length != 11) return 'CPF inválido (11 dígitos)';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('common_cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patasColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(context.tr('encontra.generate_pix_btn'), style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cpf = cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      await _createSubscription(cpf: cpf);
    }
  }

  Future<void> _createSubscription({required String cpf}) async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('encontra.auth_required_err'))),
        );
        return;
      }

      // Chamada segura para a Edge Function nativa do Supabase
      final response = await _client.functions.invoke(
        'create-payment',
        body: {
          'plan_id': _selectedPlanId,
          'cpf': cpf,
          'pet_id': widget.petId,
        },
      );

      if (response.status != 200) {
        throw Exception('Falha ao processar pagamento com o gateway: ${response.data}');
      }

      final invoice = response.data as Map<String, dynamic>;

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PixPaymentPage(invoice: invoice),
          ),
        ).then((paid) {
          if (paid == true && mounted) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao criar assinatura: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('encontra.sub_error', {'error': '$e'}))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    // Componente de Benefícios (Lado Esquerdo no Desktop)
    final benefitsWidget = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('encontra.keep_pet_safe_title'),
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: isDesktop ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
          ),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('encontra.keep_pet_safe_desc'),
          style: TextStyle(
            fontFamily: 'Roboto_flex',
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Benefícios do Plano
        Card(
          elevation: 0,
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildBenefitItem(
                  icon: Icons.location_on_outlined,
                  title: context.tr('encontra.benefit1_title'),
                  subtitle: context.tr('encontra.benefit1_desc'),
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _buildBenefitItem(
                  icon: Icons.notifications_active_outlined,
                  title: context.tr('encontra.benefit2_title'),
                  subtitle: context.tr('encontra.benefit2_desc'),
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _buildBenefitItem(
                  icon: Icons.qr_code_scanner,
                  title: context.tr('encontra.benefit3_title'),
                  subtitle: context.tr('encontra.benefit3_desc'),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    // Componente de Seleção de Planos e Checkout (Lado Direito no Desktop)
    final checkoutWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop) ...[
          Text(
            context.tr('encontra.choose_plan_title'),
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Seleção de Planos
        ..._plans.map((plan) {
          final isSelected = plan['id'] == _selectedPlanId;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPlanId = plan['id'];
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.patasColor.withValues(alpha: 0.08)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.patasColor
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan['id'] == 'plan-mensal-patas-encontra'
                                    ? context.tr('encontra.monthly_plan')
                                    : context.tr('encontra.annual_plan'),
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
                                ),
                              ),
                              if (plan['discount'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    context.tr('encontra.save_discount'),
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan['id'] == 'plan-mensal-patas-encontra' ? context.tr('encontra.billed_monthly') : context.tr('encontra.billed_annually'),
                            style: TextStyle(
                              fontFamily: 'Roboto_flex',
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ ${plan['price'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.patasColor,
                          ),
                        ),
                        Text(
                          context.tr('encontra.per_period'),
                          style: TextStyle(
                            fontFamily: 'Roboto_flex',
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        Text(
          context.tr('encontra.payment_method_title'),
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Opção PIX
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = 'PIX';
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'PIX'
                        ? AppColors.patasColor.withValues(alpha: 0.08)
                        : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedPaymentMethod == 'PIX'
                          ? AppColors.patasColor
                          : (isDark ? Colors.white10 : Colors.grey.shade200),
                      width: _selectedPaymentMethod == 'PIX' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code,
                        color: _selectedPaymentMethod == 'PIX'
                            ? AppColors.patasColor
                            : (isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PIX',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedPaymentMethod == 'PIX'
                              ? AppColors.patasColor
                              : (isDark ? Colors.white70 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Opção Cartão de Crédito
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = 'CARD';
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'CARD'
                        ? AppColors.patasColor.withValues(alpha: 0.08)
                        : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedPaymentMethod == 'CARD'
                          ? AppColors.patasColor
                          : (isDark ? Colors.white10 : Colors.grey.shade200),
                      width: _selectedPaymentMethod == 'CARD' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: _selectedPaymentMethod == 'CARD'
                            ? AppColors.patasColor
                            : (isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('encontra.card_option'),
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedPaymentMethod == 'CARD'
                              ? AppColors.patasColor
                              : (isDark ? Colors.white70 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Botão de Confirmação
        ElevatedButton(
          onPressed: _isLoading 
              ? null 
              : (_selectedPaymentMethod == 'PIX' 
                  ? _collectCpfAndCreateSubscription 
                  : _navigateToCardCheckout),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.patasColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _selectedPaymentMethod == 'PIX' ? context.tr('encontra.subscribe_pix_btn') : context.tr('encontra.advance_card_btn'),
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          _selectedPaymentMethod == 'PIX'
              ? context.tr('encontra.pix_info_desc')
              : context.tr('encontra.card_info_desc'),
          style: TextStyle(
            fontFamily: 'Roboto_flex',
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 100), // Espaço de segurança para BottomNavigationBar
      ],
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('encontra.plans_title'),
        subtitle: context.tr('encontra.plans_subtitle'),
        showBackButton: true,
        leadingIcon: Icon(
          Icons.workspace_premium_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1050),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lado Esquerdo: Benefícios
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48.0),
                          child: benefitsWidget,
                        ),
                      ),
                      // Lado Direito: Planos e Botão de Confirmação
                      Expanded(
                        flex: 5,
                        child: checkoutWidget,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      benefitsWidget,
                      const SizedBox(height: 24),
                      checkoutWidget,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.patasColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.patasColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Roboto_flex',
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
