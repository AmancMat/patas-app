import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:patas_web_app/src/features/sign_in/sign_in_controller.dart';
import 'package:patas_web_app/src/features/sign_in/sign_in_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';
import '../../../main.dart';
import '../../common_widgets/custom_circular_progress_indicator.dart';
import '../../common_widgets/multi_text_button.dart';
import '../../common_widgets/particles_background.dart';
import '../../external_services/secure_storage.dart';
import '../auth/models/user_model.dart';
import '../../common_widgets/validator.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/routes.dart';
import '../../localization/locator.dart';
import '../../ui/components/atoms/custom_text_form_field.dart';
import '../../utils/custom_bottom_sheet.dart';
import '../../utils/password_form_field.dart';
import '../../utils/auth_error_translator.dart';
import '../auth/recovery_account.dart';
import '../pets/services/pet_service.dart';
import '../auth/services/auth_services.dart';
import '../settings/widgets/account_deletion_dialog.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = locator.get<SignInController>();
  bool _rememberMe = false;
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _isLoadingDialogShowing = false;
  bool _isNavigating = false;

  @override
  void dispose() {
    _controller.removeListener(_handleControllerState);
    _emailController.dispose();
    _passwordController.dispose();
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
    _loadRememberedCredentials();

    _authStateSubscription =
        supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      debugPrint("SignInPage: Evento de Auth recebido: $event");

      if (event == AuthChangeEvent.signedIn) {
        final session = data.session;
        if (session != null) {
          final user = session.user;
          final userModel = UserModel(
            id: user.id,
            email: user.email,
            name: user.userMetadata?['name'],
          );
          await locator
              .get<SecureStorage>()
              .write(key: "CURRENT_USER", value: userModel.toJson());
        }
        if (!_isNavigating) {
          _isNavigating = true;
          _closeLoadingDialog();
          _checkPetsAndNavigate();
        }
      }
    });

    _controller.addListener(_handleControllerState);
  }

  void _handleControllerState() {
    if (!mounted) return;

    if (_controller.state is SignInStateLoading) {
      _isLoadingDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    }
    if (_controller.state is SignInStateSuccess) {
      _closeLoadingDialog();
      if (_rememberMe) {
        _saveCredentials();
      } else {
        _clearSavedCredentials();
      }
      if (!_isNavigating) {
        _isNavigating = true;
        _checkPetsAndNavigate();
      }
    }
    if (_controller.state is SignInStateError) {
      final error = _controller.state as SignInStateError;
      debugPrint("SignInPage: Erro detectado no Controller: ${error.message}");
      
      _closeLoadingDialog();
      customModalBottomSheet(
        context,
        content: AuthErrorTranslator.translate(error.message),
        buttonText: "Tentar novamente",
      );
    }
  }

  Future<void> _checkPetsAndNavigate() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final authService = locator.get<AuthService>();
        final pendingDeletionUser = await authService.checkPendingDeletion();

        if (!mounted) return;

        if (pendingDeletionUser != null) {
          final shouldCancel = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AccountDeletionDialog(
              user: pendingDeletionUser,
              onCancel: () => Navigator.pop(context, true),
              onKeep: () => Navigator.pop(context, false),
            ),
          );

          if (!mounted) return;

          if (shouldCancel == true) {
            try {
              await authService.cancelAccountDeletion();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exclusão cancelada! Sua conta foi restaurada.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao cancelar exclusão: $e'), backgroundColor: Colors.red),
              );
              await authService.signOut();
              return;
            }
          } else {
            await authService.signOut();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sua conta permanece agendada para exclusão.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
        }

        // Marca que o login foi feito pelo fluxo de tutor
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('LAST_LOGIN_MODE', 'tutor');

        // Se for Tutor, verifica os pets e vai para a Home
        final petService = PetService();
        final pets = await petService.getPetsByUserId(user.id);

        if (!mounted) return;

        _closeLoadingDialog();

        if (pets.isEmpty) {
          Navigator.pushNamedAndRemoveUntil(
              context, NamedRoute.firstProfile, (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, NamedRoute.home, (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        _closeLoadingDialog();
        Navigator.pushNamedAndRemoveUntil(
            context, NamedRoute.home, (route) => false);
      }
    }
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('remembered_email');
    final password = prefs.getString('remembered_password');
    final remember = prefs.getBool('remember_me') ?? false;
    if (remember && mounted) {
      setState(() {
        _emailController.text = email ?? '';
        _passwordController.text = password ?? '';
        _rememberMe = remember;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remembered_email', _emailController.text);
    await prefs.setString('remembered_password', _passwordController.text);
    await prefs.setBool('remember_me', true);
  }

  Future<void> _clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remembered_email');
    await prefs.remove('remembered_password');
    await prefs.setBool('remember_me', false);
  }

  void _doSignIn() {
    final valid =
        _formKey.currentState != null && _formKey.currentState!.validate();
    if (valid) {
      _controller.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      log("erro ao logar");
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
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                            padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth < 420 ? 20 : 32,
                                vertical: 32),
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
                                      SvgPicture.asset('assets/icons/patas.svg',
                                          height: 36, width: 36),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Bem-vindo de volta!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Entre na sua conta Patas',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.65),
                                      fontFamily: 'Roboto_flex',
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Email
                                  CustomTextFormField(
                                    controller: _emailController,
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    prefixIcon: const Icon(Icons.email_outlined,
                                        color: AppColors.patasColor, size: 20),
                                    labelText: 'Email',
                                    hintText: 'Adicione seu email',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: Validator.validateEmail,
                                  ),
                                  const SizedBox(height: 6),

                                  // Senha
                                  PasswordFormField(
                                    controller: _passwordController,
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: AppColors.patasColor, size: 20),
                                    labelText: 'Senha',
                                    hintText: '*********',
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _doSignIn(),
                                    validator: Validator.validatePassword,
                                  ),
                                  const SizedBox(height: 8),

                                  // Lembrar-me + Esqueceu a senha
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _rememberMe = !_rememberMe),
                                          behavior: HitTestBehavior.opaque,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) => setState(
                                                    () => _rememberMe = value ?? false),
                                                activeColor: AppColors.patasColor,
                                                checkColor: Colors.white,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity.compact,
                                                side: BorderSide(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5)),
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'Lembrar-me',
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.75),
                                                      fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    RecoveryAccount())),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Esqueceu a senha?',
                                          style: TextStyle(
                                              color: AppColors.patasColor,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Botão Entrar
                                  SizedBox(
                                    height: 48,
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed: _doSignIn,
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(
                                            AppColors.patasColor),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(32)),
                                        ),
                                      ),
                                      child: const Text(
                                        'Entrar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Fredoka',
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  Row(children: [
                                    Expanded(
                                        child: Divider(
                                            color: Colors.white.withValues(alpha: 0.25))),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('ou entre com',
                                          style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.55),
                                              fontSize: 13)),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: Colors.white.withValues(alpha: 0.25))),
                                  ]),
                                  const SizedBox(height: 16),

                                  // Social buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        _buildSocialButton(
                                          asset: 'assets/face_icon.svg',
                                          semanticLabel: 'Entrar com Facebook',
                                          onPressed: () =>
                                              _controller.signInWithFacebook(),
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
                                          onPressed: () =>
                                              _controller.signInWithGoogle(),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),
                                  MultiTextButton(
                                    onPressed: () => Navigator.popAndPushNamed(
                                        context, NamedRoute.signUp),
                                    children: [
                                      Text(
                                        'Ainda não tem uma conta? ',
                                        style: AppTextStyles.smallText.copyWith(
                                            color: Colors.white.withValues(alpha: 0.7)),
                                      ),
                                      const Text(
                                        'Criar conta',
                                        style: TextStyle(
                                          fontFamily: 'Fredoka',
                                          color: AppColors.patasColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Atalho para Área Profissional / Patas Vet
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, NamedRoute.professionalLogin);
                                    },
                                    icon: const Icon(
                                      Icons.medical_services_rounded,
                                      size: 16,
                                      color: AppColors.patasColor,
                                    ),
                                    label: const Text(
                                      'É Médico Veterinário? Acesse aqui',
                                      style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.patasColor,
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
                  color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: SvgPicture.asset(asset, width: 32, height: 32),
          ),
        ),
        if (showSoonBadge)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
