import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/features/auth/onboarding_page.dart';
import 'package:patas_web_app/src/features/bottom_navi_bar/bottom_navi_bar.dart';
import 'package:patas_web_app/src/features/first_profile/first_profile_page.dart';
import 'package:patas_web_app/src/features/sign_in/sign_in_page.dart';
import 'package:patas_web_app/src/features/sign_up/sign_up_page.dart';
import 'package:patas_web_app/src/features/notifications/notifications.dart';
import 'package:patas_web_app/src/features/splash/splash_page.dart';
import 'package:patas_web_app/core/responsive/responsive_layout.dart';
import 'package:patas_web_app/src/features/health_professional/professional_login_page.dart';
import 'package:patas_web_app/src/features/health_professional/professional_sign_up_page.dart';
import 'package:patas_web_app/src/features/interests/interests_questionnaire_page.dart';
import 'package:patas_web_app/src/features/encontra/screens/localizador_page.dart';
import 'package:patas_web_app/src/features/encontra/screens/admin_qr_generator_screen.dart';
import 'package:patas_web_app/src/features/encontra/screens/tutor_encontra_dashboard.dart';
import 'package:patas_web_app/src/features/friendly/screens/friendly_dashboard_screen.dart';
import 'package:patas_web_app/src/features/health/screens/tutor_vet_map_screen.dart';
import 'package:patas_web_app/src/features/health/screens/tutor_appointments_screen.dart';
import 'package:patas_web_app/src/features/health/screens/tutor_health_history_screen.dart';
import 'package:patas_web_app/src/features/health/screens/vet/vet_dashboard_screen.dart';
import 'package:patas_web_app/src/features/health/vacinas/vacinas_page.dart';
import 'package:patas_web_app/src/features/health/dicas/dicas_page.dart';
import 'package:patas_web_app/src/features/home/timeline/screens/public_post_page.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patas_web_app/src/providers/font_size_provider.dart';
import 'package:patas_web_app/src/providers/accessibility_provider.dart';
import 'package:patas_web_app/src/providers/locale_provider.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:patas_web_app/src/common_widgets/connectivity_banner.dart';
import 'package:patas_web_app/src/common_widgets/story_publish_banner.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> desktopContentNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<int> bottomNavIndexNotifier = ValueNotifier<int>(2);
final ValueNotifier<int> homeTabIndexNotifier = ValueNotifier<int>(
  1,
); // 0: Perfil, 1: Timeline (default)

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListener();

    // Força a inicialização segura da árvore semântica após a renderização do primeiro frame (apenas em mobile nativo).
    // Isso garante que o leitor de telas (TalkBack) encontre a árvore de acessibilidade ativa e
    // previne o crash precoce de 'TypeError' que ocorria ao rodar no main().
    // Evitamos rodar isso na Web para prevenir exceções do tipo "Child #... is missing in the tree".
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SemanticsBinding.instance.ensureSemantics();
      });
    }
  }

  void _setupNotificationListener() {
    NotificationService().onNotificationClick.listen((payload) {
      if (payload != null && payload.contains('health')) {
        bottomNavIndexNotifier.value = 3;
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          NamedRoute.home,
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lido aqui onde o context é descendente direto do MultiProvider
    final fontScale = Provider.of<FontSizeProvider>(context).multiplier;
    final accProvider = Provider.of<AccessibilityProvider>(context);
    final reduceMotion = accProvider.reduceMotion;
    final colorFilter = accProvider.currentColorFilter;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(430, 932), // Tamanho base (ex: iPhone 14 Pro Max)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: AppColors.patasColor),
          ),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            // Regra de Fallback Inteligente Internacional:
            // 1. Se o dispositivo estiver em Português ('pt'), renderiza em Português.
            // 2. Se estiver em QUALQUER OUTRO idioma (Inglês, Italiano, Espanhol, Francês, etc.),
            //    renderiza obrigatoriamente em INGLÊS por padrão mundial!
            if (deviceLocale != null &&
                deviceLocale.languageCode.toLowerCase() == 'pt') {
              return const Locale('pt', 'BR');
            }
            return const Locale('en', 'US');
          },
          initialRoute: NamedRoute.splash,
          builder: (context, widget) {
            Widget rootWidget = ResponsiveAppWrapper(
              child: widget ?? const SizedBox.shrink(),
            );

            if (colorFilter != null) {
              rootWidget = ColorFiltered(
                colorFilter: colorFilter,
                child: rootWidget,
              );
            }

            // WCAG A1.2 e A2: injeta textScaler e disableAnimations
            // lidos no nível do _AppState para evitar ProviderNotFoundException
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(fontScale),
                disableAnimations: reduceMotion,
              ),
              child: ConnectivityBannerWrapper(
                child: StoryPublishBannerWrapper(child: rootWidget),
              ),
            );
          },
          routes: {
            NamedRoute.initial: (context) => const OnboardingPage(),
            NamedRoute.splash: (context) => const SplashPage(),
            NamedRoute.signUp: (context) => const SignUpPage(),
            NamedRoute.signIn: (context) => const SignInPage(),
            NamedRoute.firstProfile: (context) => const FirstProfilePage(),
            NamedRoute.home: (context) => const BottomNaviBar(),
            NamedRoute.professionalLogin: (context) => const ProfessionalLoginPage(),
            NamedRoute.professionalSignUp: (context) => const ProfessionalSignUpPage(),
            NamedRoute.interestsQuestionnaire: (context) => const InterestsQuestionnairePage(),
            NamedRoute.adminQrGenerator: (context) => const AdminQrGeneratorScreen(),
            NamedRoute.encontraDashboard: (context) => const TutorEncontraDashboard(),
            NamedRoute.friendlyDashboard: (context) => const FriendlyDashboardScreen(),
            NamedRoute.saudeMapa: (context) => const TutorVetMapScreen(),
            NamedRoute.saudeAgendamentos: (context) => const TutorAppointmentsScreen(),
            NamedRoute.saudeHistorico: (context) => const TutorHealthHistoryScreen(initialIndex: 0),
            NamedRoute.saudeVet: (context) => const VetDashboardScreen(),
            NamedRoute.saudeVacinas: (context) => const VacinasPage(),
            NamedRoute.saudeDicas: (context) => const DicasPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name != null) {
              final uri = Uri.parse(settings.name!);

              if (settings.name!.startsWith('/encontra/t/')) {
                final uuid = uri.pathSegments.last;
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => LocalizadorPage(uuid: uuid),
                );
              }

              // Rota pública de post: /post?id=xyz ou /post/xyz ou /p/xyz
              if (uri.path == '/post' || uri.path.startsWith('/post/') || uri.path.startsWith('/p/')) {
                String? postId = uri.queryParameters['id'];
                if (postId == null || postId.isEmpty) {
                  if (uri.pathSegments.isNotEmpty && uri.pathSegments.last != 'post') {
                    postId = uri.pathSegments.last;
                  }
                }
                if (postId != null && postId.isNotEmpty) {
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (context) => PublicPostPage(postId: postId!),
                  );
                }
              }
            }
            return null;
          },
        );
      },
    );
  }
}

class DarkMode with ChangeNotifier {
  bool darkMode;

  DarkMode({this.darkMode = true});

  changemode() async {
    darkMode = !darkMode;
    notifyListeners();

    // Persistir escolha
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', darkMode);
  }
}
