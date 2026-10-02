import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/app.dart';

class CreditCardCheckoutPage extends StatefulWidget {
  final String petId;
  final String planId;
  final double price;
  final String planName;

  const CreditCardCheckoutPage({
    super.key,
    required this.petId,
    required this.planId,
    required this.price,
    required this.planName,
  });

  @override
  State<CreditCardCheckoutPage> createState() => _CreditCardCheckoutPageState();
}

class _CreditCardCheckoutPageState extends State<CreditCardCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _client = Supabase.instance.client;

  // Controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  final _holderCpfController = TextEditingController();
  final _holderEmailController = TextEditingController();
  final _holderPhoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _complementController = TextEditingController();

  // FocusNodes
  final _cvvFocusNode = FocusNode();

  // States
  bool _isLoading = false;
  bool _isCepLoading = false;
  bool _autoRenew = true;
  bool _showCardBack = false;

  @override
  void initState() {
    super.initState();
    // Monitorar o foco no CVV para rotacionar o cartão 3D
    _cvvFocusNode.addListener(() {
      setState(() {
        _showCardBack = _cvvFocusNode.hasFocus;
      });
    });

    // Auto-preencher email do tutor se logado
    final user = _client.auth.currentUser;
    if (user != null && user.email != null) {
      _holderEmailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _holderCpfController.dispose();
    _holderEmailController.dispose();
    _holderPhoneController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _complementController.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  // Buscar CEP via API do ViaCEP
  Future<void> _searchCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    setState(() => _isCepLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] != true) {
          setState(() {
            _streetController.text = data['logradouro'] ?? '';
            _neighborhoodController.text = data['bairro'] ?? '';
            _cityController.text = data['localidade'] ?? '';
            _stateController.text = data['uf'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar CEP: $e');
    } finally {
      setState(() => _isCepLoading = false);
    }
  }

  // Detectar bandeira do cartão com base no número
  String _detectCardBrand(String number) {
    final clean = number.replaceAll(RegExp(r'\s+'), '');
    if (clean.startsWith('4')) return 'Visa';
    if (clean.startsWith(RegExp(r'^5[1-5]')) ||
        clean.startsWith(RegExp(r'^222[1-9]')))
      return 'Mastercard';
    if (clean.startsWith(RegExp(r'^3[47]'))) return 'Amex';
    if (clean.startsWith(RegExp(r'^6(?:011|5)')) ||
        clean.startsWith(RegExp(r'^5067')))
      return 'Elo';
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

  // Enviar pagamento para a Edge Function
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cleanCardNumber = _cardNumberController.text.replaceAll(
        RegExp(r'\s+'),
        '',
      );
      final expiryParts = _cardExpiryController.text.split('/');
      if (expiryParts.length != 2)
        throw Exception('Data de validade inválida.');

      final month = expiryParts[0].trim();
      final year = '20${expiryParts[1].trim()}'; // Ex: "28" -> "2028"

      final cleanCpf = _holderCpfController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final cleanCep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanPhone = _holderPhoneController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Você precisa estar autenticado.');

      // Montar objeto de requisição
      final body = {
        'plan_id': widget.planId,
        'cpf': cleanCpf,
        'pet_id': widget.petId,
        'billing_type': 'CREDIT_CARD',
        'auto_renew': _autoRenew,
        'creditCard': {
          'holderName': _cardHolderController.text.trim(),
          'number': cleanCardNumber,
          'expiryMonth': month,
          'expiryYear': year,
          'ccv': _cardCvvController.text.trim(),
        },
        'creditCardHolderInfo': {
          'name': _cardHolderController.text.trim(),
          'email': _holderEmailController.text.trim(),
          'cpfCnpj': cleanCpf,
          'postalCode': cleanCep,
          'addressNumber': _numberController.text.trim(),
          'addressComplement': _complementController.text.trim(),
          'phone': cleanPhone,
        },
      };

      // Invocação segura da Edge Function no Supabase
      final response = await _client.functions.invoke(
        'create-payment',
        body: body,
      );

      if (response.status != 200) {
        final errorMsg = response.data is Map && response.data['error'] != null
            ? response.data['error']
            : 'Erro ao processar pagamento.';
        throw Exception(errorMsg);
      }

      if (mounted) {
        // Exibir mensagem de sucesso
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    'Sucesso!',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Sua assinatura de proteção foi ativada com sucesso! A tag do seu pet agora está monitorada.',
              style: TextStyle(fontFamily: 'Roboto_flex'),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Fecha dialog
                  Navigator.of(
                    context,
                  ).pop(true); // Retorna true para atualizar dashboard
                },
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro no checkout de cartão: $e');
      if (mounted) {
        final errorText = e.toString().replaceAll('Exception:', '').trim();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    'Pagamento Recusado',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              errorText.isNotEmpty
                  ? errorText
                  : 'Não foi possível aprovar a transação com a operadora. Verifique os dados ou tente outro cartão.',
              style: const TextStyle(fontFamily: 'Roboto_flex'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.patasColor,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: const PatasEssencialAppBar(
        title: 'Pagamento com Cartão',
        subtitle: 'Assinatura segura via Asaas',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  // 1. Cartão 3D Animado
                  _buildAnimatedCard(isDark),
                  const SizedBox(height: 32),

                  // 2. Formulários
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Seção 1: Dados do Cartão
                            _buildSectionHeader('Dados do Cartão', isDark),
                            const SizedBox(height: 16),
                            _buildCardFields(isDark),
                            const SizedBox(height: 32),

                            // Seção 2: Dados do Titular
                            _buildSectionHeader(
                              'Dados do Titular & Cobrança',
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildHolderFields(isDark),
                            const SizedBox(height: 24),

                            // Renovação Automática Switch
                            _buildAutoRenewSwitch(isDark),
                            const SizedBox(height: 32),

                            // Botão de Pagamento
                            ElevatedButton(
                              onPressed: _isLoading ? null : _processPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.patasColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Pagar R\$ ${widget.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.patasColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Processando pagamento...',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Isso pode levar alguns segundos.',
                          style: TextStyle(
                            fontFamily: 'Roboto_flex',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Cabeçalho de Seção
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
      ),
    );
  }

  // Switch de Renovação Automática
  Widget _buildAutoRenewSwitch(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renovação Automática',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.bodyAbsoluteBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cobrar automaticamente nas próximas faturas. Você pode desativar a qualquer momento.',
                  style: TextStyle(
                    fontFamily: 'Roboto_flex',
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _autoRenew,
            activeColor: AppColors.patasColor,
            onChanged: (val) {
              setState(() {
                _autoRenew = val;
              });
            },
          ),
        ],
      ),
    );
  }

  // Campos do Cartão de Crédito
  Widget _buildCardFields(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número do Cartão',
                hintText: '0000 0000 0000 0000',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                CardNumberInputFormatter(),
              ],
              onChanged: (v) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Informe o número do cartão';
                if (!_validateCardNumberLuhn(v))
                  return 'Número de cartão inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardHolderController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nome Impresso no Cartão',
                hintText: 'COMO ESTÁ NO CARTÃO',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (v) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Informe o nome do titular';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cardExpiryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Validade',
                      hintText: 'MM/AA',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      CardDateInputFormatter(),
                    ],
                    onChanged: (v) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Informe a validade';
                      if (v.length != 5) return 'Data inválida';

                      final parts = v.split('/');
                      final m = int.tryParse(parts[0]) ?? 0;
                      final y = int.tryParse(parts[1]) ?? 0;

                      if (m < 1 || m > 12) return 'Mês inválido';

                      final now = DateTime.now();
                      final currentYear = now.year % 100;
                      final currentMonth = now.month;

                      if (y < currentYear ||
                          (y == currentYear && m < currentMonth)) {
                        return 'Vencido';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cardCvvController,
                    focusNode: _cvvFocusNode,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (v) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Exigido';
                      if (v.length < 3 || v.length > 4) return 'Inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Campos do Titular do Cartão (Cobrança)
  Widget _buildHolderFields(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              controller: _holderCpfController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CPF do Titular',
                hintText: '000.000.000-00',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                CpfInputFormatter(),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Informe o CPF do titular';
                final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (clean.length != 11) return 'CPF deve conter 11 dígitos';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _holderEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail para Recibo',
                hintText: 'email@exemplo.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(v.trim())) {
                  return 'E-mail inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _holderPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Celular / WhatsApp',
                hintText: '(00) 90000-0000',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                PhoneInputFormatter(),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o celular';
                final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (clean.length < 10 || clean.length > 11)
                  return 'Número incompleto';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Endereço de Cobrança',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cepController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'CEP',
                      hintText: '00000-000',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: _isCepLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.patasColor,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      CepInputFormatter(),
                    ],
                    onChanged: (v) {
                      if (v.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                        _searchCep(v);
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe o CEP';
                      if (v.replaceAll(RegExp(r'[^0-9]'), '').length != 8)
                        return 'CEP inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      hintText: '123',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Exigido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Rua / Logradouro',
                hintText: 'Av. Paulista',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe a rua';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _neighborhoodController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Bairro',
                      hintText: 'Centro',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Informe o bairro';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _complementController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Complemento',
                      hintText: 'Apto 10',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cityController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      hintText: 'São Paulo',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Informe a cidade';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _stateController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [LengthLimitingTextInputFormatter(2)],
                    decoration: const InputDecoration(
                      labelText: 'UF',
                      hintText: 'SP',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Exigido';
                      if (v.length != 2) return 'Inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Cartão de Crédito 3D Animado
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
        : _cardCvvController.text.replaceAll(RegExp(r'.'), '•'); // Ocultar CVV

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _showCardBack ? pi : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, val, child) {
        return Transform(
          transform: Matrix4.identity()
            // ..setEntry(3, 2, 0.001) // Comentado para evitar instabilidades gráficas/crashes em emuladores
            ..rotateY(val),
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

  // Frente do Cartão de Crédito
  Widget _buildCardFront(
    bool isDark,
    String brand,
    String number,
    String name,
    String expiry,
  ) {
    return Container(
      width: double.infinity,
      height: 240,
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.patasColor.withValues(alpha: 0.15),
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
          // Logo e Bandeira
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pets, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Patas',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _getBrandLogo(brand),
            ],
          ),
          const SizedBox(height: 28),
          // Chip Dourado Simulado
          Container(
            width: 42,
            height: 32,
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
          const SizedBox(height: 20),
          // Número do Cartão
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          // Nome e Validade
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
                    fontSize: 13,
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
                      fontSize: 13,
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

  // Verso do Cartão de Crédito
  Widget _buildCardBack(String cvv) {
    return Container(
      width: double.infinity,
      height: 240,
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faixa Magnética Preta
          Container(width: double.infinity, height: 40, color: Colors.black),
          const SizedBox(height: 24),
          // Painel de Assinatura e CVV
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
                      'Patas Rewards Secure',
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
          const SizedBox(height: 24),
          // Informações Legais do Verso
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Este cartão é de uso exclusivo no ecossistema Patas. Em caso de perda, bloqueie imediatamente.',
              style: TextStyle(color: Colors.white24, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Renderizar o logo de bandeira
  Widget _getBrandLogo(String brand) {
    IconData iconData = Icons.credit_card;

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
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            Transform.translate(
              offset: const Offset(-6, 0),
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      case 'Amex':
        return const Text(
          'AMEX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        );
      case 'Elo':
        return const Text(
          'ELO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        );
      default:
        return Icon(iconData, color: Colors.white, size: 24);
    }
  }
}

// FORMATADORES DE INPUT (TEXT INPUT FORMATTERS)

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' '); // Adiciona espaço a cada 4 dígitos
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

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/'); // Adiciona barra após o mês (MM)
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

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

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

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 5 && nonZeroIndex != text.length) {
        buffer.write('-');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2) {
        buffer.write(') ');
      } else if (nonZeroIndex == 7) {
        buffer.write('-');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
