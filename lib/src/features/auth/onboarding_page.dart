import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app.dart';
import '../../constants/app_colors.dart';
import '../../constants/routes.dart';
import '../discovery/discovery_feed_background.dart';
import 'widgets/onboarding_auth_overlay.dart';
import '../../../main.dart'; // import supabase
import '../../utils/responsive_layout.dart';
import '../../common_widgets/patas_button.dart';
import '../../common_widgets/particles_background.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    debugPrint("=== OnboardingPage InitState ===");
    _checkExistingSession();

    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        debugPrint("=== OnboardingPage: Evento signedIn recebido! Redirecionando... ===");
        _checkExistingSession();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _checkExistingSession() {
    final session = supabase.auth.currentSession;
    if (session != null) {
      debugPrint("=== OnboardingPage: Sessão existente encontrada! Verificando tipo de perfil... ===");
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          final prefs = await SharedPreferences.getInstance();
          final loginMode = prefs.getString('LAST_LOGIN_MODE') ?? 'tutor';

          if (loginMode == 'vet') {
            final vetData = await supabase
                .from('vet_profiles')
                .select('id')
                .eq('user_id', session.user.id)
                .maybeSingle();

            if (!mounted) return;
            if (vetData != null) {
              debugPrint("--> Conta Profissional (Vet). Redirecionando para o VetDashboardScreen...");
              Navigator.pushNamedAndRemoveUntil(
                context,
                NamedRoute.saudeVet,
                (route) => false,
              );
              return;
            }
          }

          if (!mounted) return;
          debugPrint("--> Conta de Tutor. Redirecionando para a Home...");
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.home,
            (route) => false,
          );
        } catch (_) {
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.home,
            (route) => false,
          );
        }
      });
    }
  }

  void _showAuthOverlay() {
    // Pequeno atraso de 50ms para evitar condição de corrida (race condition) no TalkBack no Flutter Web.
    // Isso dá tempo para o leitor de telas processar o clique antes que a árvore de widgets sofra mutação.
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Fechar',
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const OnboardingAuthOverlay();
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isMobile = context.isMobile;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        elevation: 0,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/patas.svg',
              height: isMobile ? 26 : 32,
            ),
            SizedBox(width: isMobile ? 6 : 10),
            Text(
              'Patas',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 18 : 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: PatasButton(
                text: isMobile ? 'Patas Vet' : 'Sou Patas Vet',
                onPressed: () {
                  Navigator.pushNamed(context, NamedRoute.professionalLogin);
                },
                size: PatasButtonSize.small,
                variant: PatasButtonVariant.secondary,
                semanticsLabel: 'Acessar área do profissional',
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              right: isMobile ? 8.0 : 16.0,
              left: isMobile ? 4.0 : 8.0,
              top: 4.0,
              bottom: 4.0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: PatasButton(
                text: 'Iniciar',
                onPressed: _showAuthOverlay,
                size: PatasButtonSize.small,
                variant: PatasButtonVariant.primary,
                semanticsLabel: 'Iniciar o aplicativo',
              ),
            ),
          ),
        ],
      ),
      body: ExcludeSemantics(
        child: ParticlesBackground(
          particleColor: AppColors.patasColor,
          backgroundColor: isDark
              ? const Color(0xFF0F0F1A)
              : const Color(0xFF1C1C3A),
          backgroundColorEnd: isDark
              ? const Color(0xFF1A0A0A)
              : const Color(0xFF2D1B00),
          particleCount: 70,
          child: const DiscoveryFeedBackground(),
        ),
      ),
    );
  }
}
