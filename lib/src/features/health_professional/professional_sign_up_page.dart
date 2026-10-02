import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app.dart';
import '../../common_widgets/particles_background.dart';
import '../../constants/app_colors.dart';
import '../../constants/routes.dart';
import '../health/services/patas_saude_service.dart';

class ProfessionalSignUpPage extends StatefulWidget {
  const ProfessionalSignUpPage({super.key});

  @override
  State<ProfessionalSignUpPage> createState() => _ProfessionalSignUpPageState();
}

class _ProfessionalSignUpPageState extends State<ProfessionalSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _crmvController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedUf = 'SP';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  final List<String> _ufs = [
    'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR', 'RJ', 'RN',
    'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _crmvController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('LAST_LOGIN_MODE', 'vet');

      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // 1. Criar conta de usuário no Supabase Auth com tag de tipo profissional
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': _nameController.text.trim(),
          'account_type': 'professional',
        },
      );

      final user = res.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw 'Não foi possível concluir o cadastro. Tente novamente.';
      }

      // 2. Criar perfil profissional inicial em vet_profiles
      final saudeService = PatasSaudeService();
      final created = await saudeService.createOrUpdateVetProfile(
        type: 'vet',
        crmvNumber: _crmvController.text.trim(),
        crmvUf: _selectedUf,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        clinicName: 'Consultório Dr(a). ${_nameController.text.trim()}',
        specialties: ['Clínica Geral'],
        acceptsHomeVisit: false,
        acceptsClinicVisit: true,
        consultationPrice: 150.0,
      );

      if (!created) {
        debugPrint('Aviso: Falha ao salvar vet_profile inicial, mas o usuário foi criado.');
      }

      if (mounted) {
        // Redireciona diretamente para o painel veterinário B2B
        Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.saudeVet,
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao realizar cadastro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<DarkMode>(context);

    return Scaffold(
      body: ParticlesBackground(
        particleColor: AppColors.patasColor,
        backgroundColor: const Color(0xFF1C1C3A),
        backgroundColorEnd: const Color(0xFF2D1B00),
        particleCount: 60,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight - 80,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.patasColor.withValues(alpha: 0.18),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/patas.svg',
                                        height: 40,
                                        width: 40,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Patas Vet',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Fredoka',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 26,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  const Text(
                                    'Cadastro de Médico Veterinário',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Fredoka',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Crie sua conta profissional e tenha 14 dias de teste grátis no Patas Vet',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),

                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.redAccent),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Nome Completo
                                  TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration('Nome Completo (ou Clínica)', Icons.person_outline),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome completo' : null,
                                  ),
                                  const SizedBox(height: 14),

                                  // CRMV + UF (Row)
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: _crmvController,
                                          style: const TextStyle(color: Colors.white),
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration('Nº CRMV', Icons.badge_outlined),
                                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o CRMV' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 1,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedUf,
                                          dropdownColor: const Color(0xFF1C1C3A),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: _inputDecoration('UF', Icons.map_outlined),
                                          items: _ufs.map((uf) => DropdownMenuItem(value: uf, child: Text(uf))).toList(),
                                          onChanged: (val) {
                                            if (val != null) setState(() => _selectedUf = val);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Telefone / WhatsApp
                                  TextFormField(
                                    controller: _phoneController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.phone,
                                    decoration: _inputDecoration('Telefone / WhatsApp', Icons.phone_outlined),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu telefone de contato' : null,
                                  ),
                                  const SizedBox(height: 14),

                                  // E-mail
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration('E-mail Profissional', Icons.email_outlined),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                                      if (!v.contains('@')) return 'E-mail inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Senha
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration('Senha', Icons.lock_outline).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Confirmar Senha
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    style: const TextStyle(color: Colors.white),
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!_isLoading) _handleSignUp();
                                    },
                                    decoration: _inputDecoration('Confirmar Senha', Icons.lock_outline).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v != _passwordController.text) return 'As senhas não coincidem';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Botão Cadastrar
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleSignUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.patasColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                            )
                                          : const Text(
                                              'Criar Conta Profissional',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Link para Login Profissional
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, NamedRoute.professionalLogin);
                                    },
                                    child: const Text(
                                      'Já tem uma conta profissional? Faça Login',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.patasColor),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.patasColor, width: 2),
      ),
    );
  }
}
