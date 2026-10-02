import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../../models/vet_profile_model.dart';
import '../../models/vet_subscription_model.dart';
import '../../services/vet_subscription_service.dart';
import 'vet_pix_payment_page.dart';

class VetCheckoutPage extends StatefulWidget {
  final VetProfile vetProfile;

  const VetCheckoutPage({super.key, required this.vetProfile});

  @override
  State<VetCheckoutPage> createState() => _VetCheckoutPageState();
}

class _VetCheckoutPageState extends State<VetCheckoutPage> {
  final _subscriptionService = VetSubscriptionService();
  final _formKey = GlobalKey<FormState>();

  List<VetPlan> _plans = [];
  VetPlan? _selectedPlan;
  String _paymentMethod = 'PIX'; // 'PIX' ou 'CREDIT_CARD'
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _showCardBack = false;

  // Controllers para formulário de pagamento
  final _cpfController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  // FocusNodes
  final _cvvFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPlans();

    _cvvFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showCardBack = _cvvFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final plans = await _subscriptionService.getPlans();
    if (mounted) {
      setState(() {
        _plans = plans;
        if (plans.isNotEmpty) {
          _selectedPlan = plans.firstWhere(
            (p) => p.billingCycle == 'monthly',
            orElse: () => plans.first,
          );
        }
        _isLoading = false;
      });
    }
  }

  // Detectar bandeira do cartão com base no número
  String _detectCardBrand(String number) {
    final clean = number.replaceAll(RegExp(r'\s+'), '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.startsWith(RegExp(r'^5[1-5]')) ||
        clean.startsWith(RegExp(r'^222[1-9]'))) {
      return 'Mastercard';
    }
    if (clean.startsWith(RegExp(r'^3[47]'))) return 'Amex';
    if (clean.startsWith(RegExp(r'^6(?:011|5)')) ||
        clean.startsWith(RegExp(r'^5067'))) {
      return 'Elo';
    }
    return 'Generic';
  }

  // Validar cartão de crédito usando algoritmo de Luhn
  bool _validateCardNumberLuhn(String number) {
    final clean = number.replaceAll(RegExp(r'\s+'), '');
    if (clean.length < 13 || clean.length > 19) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = clean.length - 1; i >= 0; i--) {
      int n = int.parse(clean[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  Future<void> _handleConfirmPayment() async {
    if (_selectedPlan == null) return;
    if (_paymentMethod == 'CREDIT_CARD' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    Map<String, dynamic>? creditCard;
    Map<String, dynamic>? creditCardHolderInfo;

    if (_paymentMethod == 'CREDIT_CARD') {
      final expiryParts = _cardExpiryController.text.split('/');
      final month = expiryParts.isNotEmpty ? expiryParts[0].trim() : '01';
      final rawYear = expiryParts.length > 1 ? expiryParts[1].trim() : '30';
      final year = rawYear.length == 2 ? '20$rawYear' : rawYear;

      creditCard = {
        'number': _cardNumberController.text.replaceAll(' ', ''),
        'holderName': _cardHolderController.text.trim(),
        'expiryMonth': month,
        'expiryYear': year,
        'ccv': _cardCvvController.text.trim(),
      };

      creditCardHolderInfo = {
        'name': _cardHolderController.text.trim(),
        'email': Supabase.instance.client.auth.currentUser?.email ?? '',
        'cpfCnpj': _cpfController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        'postalCode': '01001000',
        'addressNumber': '100',
        'phone': widget.vetProfile.phone ?? '11999999999',
      };
    }

    final invoice = await _subscriptionService.createPaymentForVet(
      vetId: widget.vetProfile.id,
      plan: _selectedPlan!,
      paymentType: _paymentMethod,
      cpf: _cpfController.text.trim().isNotEmpty ? _cpfController.text.trim() : null,
      creditCard: creditCard,
      creditCardHolderInfo: creditCardHolderInfo,
    );

    if (mounted) {
      setState(() => _isProcessing = false);

      if (invoice != null) {
        if (_paymentMethod == 'PIX') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VetPixPaymentPage(
                invoice: invoice,
                vetProfile: widget.vetProfile,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assinatura ativada com sucesso via Cartão de Crédito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao processar assinatura. Tente novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = context.isDesktop;
    final scaffoldBg = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(color: AppColors.patasColor));
    } else {
      content = Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Profissional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.patasColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.patasColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.patasColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vetProfile.fullName,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        Text(
                          'CRMV ${widget.vetProfile.crmvUf} ${widget.vetProfile.crmvNumber}',
                          style: const TextStyle(fontSize: 12, color: AppColors.patasColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Seleção de Planos
            Text(
              'Escolha seu Plano Profissional *',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 12),

            Column(
              children: _plans.map((plan) {
                final isSelected = _selectedPlan?.id == plan.id;
                final isAnnual = plan.billingCycle == 'annual';

                return GestureDetector(
                  onTap: () => setState(() => _selectedPlan = plan),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.patasColor : (isDark ? Colors.white12 : Colors.black12),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.patasColor.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.patasColor : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    plan.name,
                                    style: TextStyle(
                                      fontFamily: 'Fredoka',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.darkBG,
                                    ),
                                  ),
                                  if (isAnnual) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                      ),
                                      child: const Text(
                                        '2 meses grátis 🔥',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (plan.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  plan.description!,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'R\$ ${plan.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.patasColor,
                              ),
                            ),
                            Text(
                              isAnnual ? '/ano' : '/mês',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Método de Pagamento
            Text(
              'Forma de Pagamento *',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.darkBG,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.pix_rounded, size: 18),
                    label: const Text('PIX (Instantâneo)', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: _paymentMethod == 'PIX',
                    selectedColor: AppColors.patasColor,
                    labelStyle: TextStyle(color: _paymentMethod == 'PIX' ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (val) {
                      if (val) setState(() => _paymentMethod = 'PIX');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.credit_card_rounded, size: 18),
                    label: const Text('Cartão de Crédito', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: _paymentMethod == 'CREDIT_CARD',
                    selectedColor: AppColors.patasColor,
                    labelStyle: TextStyle(color: _paymentMethod == 'CREDIT_CARD' ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (val) {
                      if (val) setState(() => _paymentMethod = 'CREDIT_CARD');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Formulário de Cartão de Crédito (se selecionado)
            if (_paymentMethod == 'CREDIT_CARD') ...[
              // 1. Cartão 3D Animado com Emulação de Chip, Bandeira e Giro no CVV
              _buildAnimatedCard(isDark),
              const SizedBox(height: 24),

              Text(
                'Dados do Cartão & Titular',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
              const SizedBox(height: 12),

              // Número do Cartão
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  CardNumberInputFormatter(),
                ],
                onChanged: (v) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o número do cartão';
                  if (!_validateCardNumberLuhn(v)) return 'Número de cartão inválido';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Número do Cartão *',
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              // Nome Impresso no Cartão
              TextFormField(
                controller: _cardHolderController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                onChanged: (v) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o nome do titular';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Nome Impresso no Cartão *',
                  hintText: 'COMO ESTÁ NO CARTÃO',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Validade (MM/AA)
                  Expanded(
                    child: TextFormField(
                      controller: _cardExpiryController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        CardDateInputFormatter(),
                      ],
                      onChanged: (v) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Validade';
                        if (!v.contains('/') || v.length < 5) return 'Inválido';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Validade (MM/AA) *',
                        hintText: '12/28',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // CVV
                  Expanded(
                    child: TextFormField(
                      controller: _cardCvvController,
                      focusNode: _cvvFocusNode,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (v) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'CVV';
                        if (v.length < 3) return 'Inválido';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'CVV *',
                        hintText: '123',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // CPF do Titular
              TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  CpfInputFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o CPF do titular';
                  final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                  if (clean.length != 11) return 'CPF deve conter 11 dígitos';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'CPF do Titular *',
                  hintText: '000.000.000-00',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Botão Confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: Text(
                  _isProcessing
                      ? 'Processando...'
                      : (_paymentMethod == 'PIX' ? 'Gerar QR Code PIX' : 'Confirmar Assinatura'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isProcessing ? null : _handleConfirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      );

      if (isDesktop) {
        content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Card(
                elevation: 0,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: content,
                ),
              ),
            ),
          ),
        );
      }
    }

    final mainScaffold = Scaffold(
      backgroundColor: scaffoldBg,
      appBar: const PatasEssencialAppBar(
        title: 'Assinatura Profissional',
        subtitle: 'Ativação de planos e recursos B2B para clínicas e vets',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 20,
          vertical: 10,
        ).copyWith(bottom: 100),
        child: content,
      ),
    );

    return mainScaffold;
  }

  // Widget de Cartão 3D Animado
  Widget _buildAnimatedCard(bool isDark) {
    final rawNumber = _cardNumberController.text.replaceAll(RegExp(r'\s+'), '');
    final brand = _detectCardBrand(rawNumber);
    final numberToShow = _cardNumberController.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _cardNumberController.text;
    final nameToShow = _cardHolderController.text.isEmpty
        ? 'NOME DO TITULAR'
        : _cardHolderController.text.toUpperCase();
    final expiryToShow = _cardExpiryController.text.isEmpty
        ? 'MM/AA'
        : _cardExpiryController.text;
    final cvvToShow = _cardCvvController.text.isEmpty
        ? '•••'
        : _cardCvvController.text.replaceAll(RegExp(r'.'), '•');

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _showCardBack ? pi : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, val, child) {
        return Transform(
          transform: Matrix4.identity()..rotateY(val),
          alignment: Alignment.center,
          child: val < pi / 2
              ? _buildCardFront(
                  isDark,
                  brand,
                  numberToShow,
                  nameToShow,
                  expiryToShow,
                )
              : Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _buildCardBack(cvvToShow),
                ),
        );
      },
    );
  }

  Widget _buildCardFront(
    bool isDark,
    String brand,
    String number,
    String name,
    String expiry,
  ) {
    return Container(
      width: double.infinity,
      height: 220,
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.patasColor.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            AppColors.patasColor.withValues(alpha: 0.95),
            const Color(0xFF1E293B).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pets, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Patas Saúde PRO',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _getBrandLogo(brand),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 42,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'VALIDADE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(String cvv) {
    return Container(
      width: double.infinity,
      height: 220,
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withValues(alpha: 0.95),
            const Color(0xFF0F172A).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, height: 40, color: Colors.black),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 12),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Patas Vet Secure',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cvv,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Uso exclusivo no ecossistema Patas Saúde. Processamento seguro via Asaas.',
              style: TextStyle(color: Colors.white24, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBrandLogo(String brand) {
    switch (brand) {
      case 'Visa':
        return const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontStyle: FontStyle.italic,
          ),
        );
      case 'Mastercard':
        return Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
            Transform.translate(
              offset: const Offset(-6, 0),
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              ),
            ),
          ],
        );
      case 'Amex':
        return const Text(
          'AMEX',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        );
      case 'Elo':
        return const Text(
          'ELO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        );
      default:
        return const Icon(Icons.credit_card, color: Colors.white, size: 24);
    }
  }
}

// ============================================================
// FORMATADORES DE INPUT (TEXT INPUT FORMATTERS)
// ============================================================

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CardDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 3 || nonZeroIndex == 6) {
        if (nonZeroIndex != text.length) {
          buffer.write('.');
        }
      } else if (nonZeroIndex == 9) {
        if (nonZeroIndex != text.length) {
          buffer.write('-');
        }
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
