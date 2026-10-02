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
import '../health/screens/vet/vet_registration_screen.dart';
import '../../utils/auth_error_translator.dart';

import 'package:patas_web_app/src/external_services/supabase_auth_service.dart';

class ProfessionalLoginPage extends StatefulWidget {
  const ProfessionalLoginPage({super.key});

  @override
  State<ProfessionalLoginPage> createState() => _ProfessionalLoginPageState();
}

class _ProfessionalLoginPageState extends State<ProfessionalLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
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

      // 1. Autenticação no Supabase Auth
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user ?? supabase.auth.currentUser;
      if (user == null) {
        throw 'Falha ao autenticar. Verifique suas credenciais.';
      }

      // 2. Verificar se o usuário possui perfil em vet_profiles
      final vetData = await supabase
          .from('vet_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (vetData != null) {
        // Profissional cadastrado -> Abre direto o Painel CRMV / Dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.saudeVet,
          (route) => false,
        );
      } else {
        // Conta criada, mas ainda sem o cadastro de CRMV concluído
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VetRegistrationScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = AuthErrorTranslator.translate(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao realizar login: $e');
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
        particleCount: 70,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight - 80,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
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
                            padding: const EdgeInsets.all(36),
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
                                  // Header com Logo do Patas
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/patas.svg',
                                        height: 44,
                                        width: 44,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Patas Vet',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Fredoka',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Ícone de Saúde
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: AppColors.patasColor.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.medical_services_outlined,
                                        color: AppColors.patasColor,
                                        size: 42,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  const Text(
                                    'Portal Patas Vet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Entre para gerenciar sua agenda, prontuários SOAP e prescrições digitais',
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

                                  // E-mail
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration('E-mail Profissional', Icons.email_outlined),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                                      if (!v.contains('@')) return 'E-mail inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Senha
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!_isLoading) _handleLogin();
                                    },
                                    decoration: _inputDecoration('Senha', Icons.lock_outline).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                                  ),
                                  const SizedBox(height: 24),

                                  // Botão Entrar
                                  SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
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
                                              'Entrar no Painel Veterinário',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Divisória "ou entre com"
                                  Row(children: [
                                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.25))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'ou entre com',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.55),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.25))),
                                  ]),
                                  const SizedBox(height: 16),

                                  // Botões sociais
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildSocialButton(
                                        asset: 'assets/face_icon.svg',
                                        semanticLabel: 'Entrar com Facebook',
                                        onPressed: () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setString('LAST_LOGIN_MODE', 'vet');
                                          try {
                                            await SupabaseAuthService().signInWithFacebook();
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erro no login social: $e'), backgroundColor: Colors.redAccent),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      _buildSocialButton(
                                        asset: 'assets/apple_logo.svg',
                                        semanticLabel: 'Entrar com Apple',
                                        showSoonBadge: true,
                                        onPressed: () {},
                                      ),
                                      const SizedBox(width: 16),
                                      _buildSocialButton(
                                        asset: 'assets/google_icon.svg',
                                        semanticLabel: 'Entrar com Google',
                                        onPressed: () async {
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setString('LAST_LOGIN_MODE', 'vet');
                                          try {
                                            await SupabaseAuthService().signInWithGoogle();
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erro no login com Google: $e'), backgroundColor: Colors.redAccent),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // Cadastrar-se como Veterinário
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, NamedRoute.professionalSignUp);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.white38),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: const Text(
                                      'Ainda não tem conta? Cadastre seu CRMV',
                                      style: TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Voltar para Login de Tutor
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        NamedRoute.signIn,
                                        (route) => false,
                                      );
                                    },
                                    child: const Text(
                                      'Voltar para Acesso de Tutor',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
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

  Widget _buildSocialButton({
    required String asset,
    required VoidCallback onPressed,
    required String semanticLabel,
    bool showSoonBadge = false,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Stack(
        children: [
          InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: SvgPicture.asset(asset, width: 32, height: 32),
            ),
          ),
          if (showSoonBadge)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.patasColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Em breve',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
