import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import '../models/friendly_place_model.dart';

class FriendlyCheckoutPage extends StatefulWidget {
  final FriendlyPlace place;

  const FriendlyCheckoutPage({super.key, required this.place});

  @override
  State<FriendlyCheckoutPage> createState() => _FriendlyCheckoutPageState();
}

class _FriendlyCheckoutPageState extends State<FriendlyCheckoutPage> {
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

  final _cvvFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isCepLoading = false;

  @override
  void initState() {
    super.initState();
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


  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cleanCardNumber = _cardNumberController.text.replaceAll(RegExp(r'\s+'), '');
      final expiryParts = _cardExpiryController.text.split('/');
      if (expiryParts.length != 2) throw Exception('Data de validade inválida.');

      final month = expiryParts[0].trim();
      final year = '20${expiryParts[1].trim()}';

      final cleanCpf = _holderCpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanCep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanPhone = _holderPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Você precisa estar autenticado.');

      final body = {
        'place_id': widget.place.id,
        'cpf': cleanCpf,
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

      final response = await _client.functions.invoke(
        'create-friendly-payment',
        body: body,
      );

      if (response.status != 200) {
        final errorMsg = response.data is Map && response.data['error'] != null
            ? response.data['error']
            : 'Erro ao processar pagamento.';
        throw Exception(errorMsg);
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text(
                  'Sucesso!',
                  style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Sua assinatura premium foi ativada e o perfil do estabelecimento foi reivindicado com sucesso!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context, true); // Returns success to reload place details
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    Widget mainContent = Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: const PatasEssencialAppBar(
        title: 'Reivindicar Local',
        subtitle: 'Assinatura e selo verificado para parceiros',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Theme(
            data: Theme.of(context).copyWith(
              brightness: isDark ? Brightness.dark : Brightness.light,
              textTheme: Theme.of(context).textTheme.copyWith(
                titleMedium: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                bodyLarge: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
              ),
              inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                prefixIconColor: isDark ? Colors.white70 : AppColors.patasColor,
              ),
            ),
            child: Form(
              key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Detalhes do Plano
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.patasColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: AppColors.patasColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Patas Friendly Premium',
                              style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Assinatura Mensal — R\$ 29,90/mês',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Formulário de Cartão de Crédito
                Text(
                  'Dados do Cartão',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 16),

                // Card Number
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Número do Cartão *',
                    prefixIcon: const Icon(Icons.credit_card_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o número do cartão.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Card Holder
                TextFormField(
                  controller: _cardHolderController,
                  decoration: InputDecoration(
                    labelText: 'Nome Impresso no Cartão *',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o nome impresso.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Expiry and CVV Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cardExpiryController,
                        decoration: InputDecoration(
                          labelText: 'Validade (MM/AA) *',
                          prefixIcon: const Icon(Icons.calendar_month_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Informe a validade.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cardCvvController,
                        focusNode: _cvvFocusNode,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'CVV *',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Informe o CVV.';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Dados de Cobrança do Titular
                Text(
                  'Dados do Titular & Cobrança',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 16),

                // CPF
                TextFormField(
                  controller: _holderCpfController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'CPF / CNPJ do Titular *',
                    prefixIcon: const Icon(Icons.assignment_ind_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o documento do titular.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _holderEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail para Recibo *',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o e-mail.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telefone
                TextFormField(
                  controller: _holderPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Telefone com DDD *',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o telefone.';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // CEP com autocompletar
                TextFormField(
                  controller: _cepController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'CEP de Cobrança *',
                    prefixIcon: const Icon(Icons.local_post_office_outlined),
                    suffixIcon: _isCepLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onChanged: (val) {
                    if (val.replaceAll(RegExp(r'[^0-9]'), '').length == 8) {
                      _searchCep(val);
                    }
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o CEP.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Endereço (Rua)
                TextFormField(
                  controller: _streetController,
                  decoration: InputDecoration(
                    labelText: 'Endereço (Rua/Avenida) *',
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o endereço.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Número e Complemento
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _numberController,
                        decoration: InputDecoration(
                          labelText: 'Número *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Informe o número.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _complementController,
                        decoration: InputDecoration(
                          labelText: 'Complemento',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bairro
                TextFormField(
                  controller: _neighborhoodController,
                  decoration: InputDecoration(
                    labelText: 'Bairro *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o bairro.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cidade e Estado Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'Cidade *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Informe a cidade.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _stateController,
                        maxLength: 2,
                        decoration: InputDecoration(
                          labelText: 'UF *',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'UF.';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Botão de Confirmação
                ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patasColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Confirmar Assinatura',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );

    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: mainContent,
            ),
          ),
        ),
      );
    }

    return mainContent;
  }
}
