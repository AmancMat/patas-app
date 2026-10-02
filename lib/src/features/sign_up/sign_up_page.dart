import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/routes.dart';
import '../../utils/uppercase_text_formatter.dart';
import '../../common_widgets/validator.dart';
import '../../common_widgets/custom_circular_progress_indicator.dart';
import '../../utils/password_form_field.dart';
import '../../external_services/secure_storage.dart';
import '../auth/models/user_model.dart';
import 'package:patas_web_app/src/features/sign_up/sign_up_controller.dart';
import 'package:patas_web_app/src/features/sign_up/sign_up_state.dart';
import 'package:patas_web_app/src/features/legal/legal_bottom_sheet.dart';
import 'package:patas_web_app/src/features/legal/legal_page.dart';
import '../../localization/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../common_widgets/multi_text_button.dart';
import '../../common_widgets/particles_background.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../ui/components/atoms/custom_text_form_field.dart';
import '../../utils/custom_bottom_sheet.dart';
import '../../utils/auth_error_translator.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  final _controller = locator.get<SignUpController>();
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _isLoadingDialogShowing = false;
  bool _acceptedTerms = false;
  bool _isNavigating = false;

  @override
  void dispose() {
    _controller.removeListener(_handleControllerState);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  void _closeLoadingDialog() {
    if (_isLoadingDialogShowing && mounted) {
      _isLoadingDialogShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void initState() {
    super.initState();

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) async {
          final AuthChangeEvent event = data.event;
          if (event == AuthChangeEvent.signedIn) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('LAST_LOGIN_MODE', 'tutor');
            final session = data.session;
            if (session != null) {
              final user = session.user;
              final userModel = UserModel(
                id: user.id,
                email: user.email,
                name: user.userMetadata?['name'],
              );
              await locator.get<SecureStorage>().write(
                key: "CURRENT_USER",
                value: userModel.toJson(),
              );
            }
            if (!_isNavigating) {
              _isNavigating = true;
              _closeLoadingDialog();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  NamedRoute.firstProfile,
                  (route) => false,
                );
              }
            }
          }
        });

    _controller.addListener(_handleControllerState);
  }

  void _handleControllerState() {
    if (!mounted) return;

    if (_controller.state is SignUpStateLoading) {
      _isLoadingDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    }
    if (_controller.state is SignUpStateSuccess) {
      _closeLoadingDialog();
      if (!_isNavigating) {
        _isNavigating = true;
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.firstProfile,
            (route) => false,
          );
        }
      }
    }
    if (_controller.state is SignUpStateError) {
      final error = _controller.state as SignUpStateError;
      _closeLoadingDialog();
      if (mounted) {
        customModalBottomSheet(
          context,
          content: AuthErrorTranslator.translate(error.message),
          buttonText: "Tentar novamente",
        );
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 36,
                            ),
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
                                children: [
                                  // Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/patas.svg',
                                        height: 36,
                                        width: 36,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Criar Conta',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Junte-se à família Patas',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.65),
                                      fontFamily: 'Roboto_flex',
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Campos
                                  _buildField(
                                    controller: _nameController,
                                    icon: Icons.face_retouching_natural,
                                    label: 'Primeiro nome',
                                    hint: 'Seu nome aqui',
                                    textInputAction: TextInputAction.next,
                                    formatters: [UpperCaseTextInputFormatter()],
                                    validator: Validator.validateName,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _emailController,
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    hint: 'Seu email aqui',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: Validator.validateEmail,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildPasswordField(
                                    controller: _passwordController,
                                    label: 'Escolha sua senha',
                                    hint: '**********',
                                    icon: Icons.lock_outline,
                                    textInputAction: TextInputAction.next,
                                    validator: Validator.validatePassword,
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Mínimo 8 caracteres, uma maiúscula e um número.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildPasswordField(
                                    label: 'Confirmar senha',
                                    hint: '**********',
                                    icon: Icons.lock_outline,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) =>
                                        Validator.validateConfirmPassword(
                                          _passwordController.text,
                                          value,
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _referralController,
                                    icon: Icons.card_giftcard_rounded,
                                    label: 'Código de Convite (Opcional)',
                                    hint: 'Ex: 123A456B',
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _doSignUp(),
                                    formatters: [UpperCaseTextInputFormatter()],
                                  ),
                                  const SizedBox(height: 16),

                                  // Checkbox de Aceite dos Termos & Privacidade
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _acceptedTerms,
                                          activeColor: AppColors.patasColor,
                                          side: const BorderSide(
                                            color: Colors.white70,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              _acceptedTerms = val ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _acceptedTerms = !_acceptedTerms;
                                            });
                                          },
                                          child: RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                                height: 1.4,
                                              ),
                                              children: [
                                                const TextSpan(
                                                    text: 'Li e concordo com os '),
                                                TextSpan(
                                                  text: 'Termos de Uso',
                                                  style: const TextStyle(
                                                    color: AppColors.patasColor,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      LegalBottomSheet.show(
                                                        context,
                                                        LegalDocumentType.terms,
                                                      );
                                                    },
                                                ),
                                                const TextSpan(text: ' e a '),
                                                TextSpan(
                                                  text: 'Política de Privacidade',
                                                  style: const TextStyle(
                                                    color: AppColors.patasColor,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      LegalBottomSheet.show(
                                                        context,
                                                        LegalDocumentType.privacy,
                                                      );
                                                    },
                                                ),
                                                const TextSpan(text: ' do Patas.'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Botão Registrar
                                  SizedBox(
                                    height: 52,
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: _doSignUp,
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(
                                          AppColors.patasColor,
                                        ),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(32),
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Registrar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Fredoka',
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'ou entre com',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.55),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withValues(alpha: 0.25),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Social buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildSocialButton(
                                        asset: 'assets/face_icon.svg',
                                        semanticLabel: 'Registrar com Facebook',
                                        onPressed: () =>
                                            _controller.signInWithFacebook(),
                                      ),
                                      const SizedBox(width: 16),
                                      _buildSocialButton(
                                        asset: 'assets/apple_logo.svg',
                                        semanticLabel: 'Registrar com Apple',
                                        showSoonBadge: true,
                                        onPressed: () {},
                                      ),
                                      const SizedBox(width: 16),
                                      _buildSocialButton(
                                        asset: 'assets/google_icon.svg',
                                        semanticLabel: 'Registrar com Google',
                                        onPressed: () =>
                                            _controller.signInWithGoogle(),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),
                                  MultiTextButton(
                                    onPressed: () => Navigator.popAndPushNamed(
                                      context,
                                      NamedRoute.signIn,
                                    ),
                                    children: [
                                      Text(
                                        'Já tem uma conta? ',
                                        style: AppTextStyles.smallText.copyWith(
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const Text(
                                        'Entrar',
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          color: AppColors.patasColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
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

  void _doSignUp() {
    if (!_acceptedTerms) {
      customModalBottomSheet(
        context,
        content:
            'Para criar uma conta, é necessário ler e aceitar os Termos de Uso e a Política de Privacidade do Patas.',
        buttonText: 'Compreendi',
      );
      return;
    }
    final valid =
        _formKey.currentState != null && _formKey.currentState!.validate();
    if (valid) {
      _controller.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        referralCode: _referralController.text.trim(),
      );
    } else {
      log("erro ao registrar");
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    List<TextInputFormatter> formatters = const [],
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return CustomTextFormField(
      controller: controller,
      prefixIcon: Icon(icon, color: AppColors.patasColor, size: 20),
      labelText: label,
      hintText: hint,
      inputFormatters: formatters,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _buildPasswordField({
    TextEditingController? controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return PasswordFormField(
      controller: controller,
      prefixIcon: Icon(icon, color: AppColors.patasColor, size: 20),
      labelText: label,
      hintText: hint,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
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
