import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/localization/locator.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/home/timeline/timeline_provider.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/features/notifications/notifications.dart';
import 'package:patas_web_app/src/providers/profile_view_provider.dart';
import 'package:patas_web_app/src/providers/user_role_provider.dart';
import 'package:patas_web_app/src/providers/font_size_provider.dart';
import 'package:patas_web_app/src/providers/accessibility_provider.dart';
import 'package:patas_web_app/src/providers/connectivity_provider.dart';
import 'package:patas_web_app/src/providers/story_publish_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:patas_web_app/src/utils/url_strategy_helper.dart'
    if (dart.library.html) 'package:patas_web_app/src/utils/url_strategy_helper_web.dart';

// Credenciais injetadas via --dart-define no build de produção.
// Em desenvolvimento, o dotenv.load() as fornece como fallback.
const _supabaseUrlEnv = String.fromEnvironment('SUPABASE_URL');
const _supabaseKeyEnv = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  // Ativa URLs sem '#' (path-based) apenas na Web para suporte a deep links.
  configureUrl();

  try {
    WidgetsFlutterBinding.ensureInitialized();
    //SemanticsBinding.instance.ensureSemantics();

    // Na Web a orientação não é mandatória, mas mantemos o código base limpo
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Credenciais: tenta dart-define (produção), depois .env (dev local), depois fallback
    String supabaseUrl = _supabaseUrlEnv;
    String supabaseKey = _supabaseKeyEnv;

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      try {
        await dotenv.load(fileName: ".env");
        supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      } catch (e) {
        debugPrint(
          "Aviso: Falha ao carregar .env ($e). Usando chaves de fallback.",
        );
      }
    }

    // Se as chaves ainda estiverem vazias (comum em produção web onde o .env é bloqueado), usa as chaves públicas.
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      supabaseUrl = 'https://pvdlxhbzrfjswwhmdwww.supabase.co';
      supabaseKey = 'sb_publishable_dapWd3nboSe9L7Seq0HOdg_yIb486C2';
    }

    await initializeDateFormatting('pt_BR', null);

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

    // Auto-recuperação resiliente de sessão: se o token salvo estiver expirado,
    // renova imediatamente antes dos providers dispararem requisições em paralelo.
    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession != null && currentSession.isExpired) {
        debugPrint(
          '🔄 [Auth] Token expirado na inicialização. Renovando sessão...',
        );
        await Supabase.instance.client.auth.refreshSession();
        debugPrint('✅ [Auth] Sessão renovada com sucesso!');
      }
    } catch (e) {
      debugPrint('⚠️ [Auth] Falha ao renovar sessão automaticamente: $e');
    }

    // Inicializar injeção de dependências do GetIt
    setupDependencies();

    final prefs = await SharedPreferences.getInstance();
    final bool isDarkMode = prefs.getBool('isDarkMode') ?? true;

    _initializeBackgroundTask();

    final fontSizeProvider = await FontSizeProvider.load();
    final accessibilityProvider = await AccessibilityProvider.load();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => DarkMode(darkMode: isDarkMode),
          ),
          ChangeNotifierProvider(create: (context) => ActivePetProvider()),
          ChangeNotifierProvider(create: (context) => ActiveAccountProvider()),
          ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
          ChangeNotifierProvider(create: (context) => StoryPublishProvider()),
          ChangeNotifierProvider(create: (context) => TimelineProvider()),
          ChangeNotifierProvider(create: (context) => ProfileViewProvider()),
          ChangeNotifierProvider(create: (context) => UserRoleProvider()),
          ChangeNotifierProvider.value(value: fontSizeProvider),
          ChangeNotifierProvider.value(value: accessibilityProvider),
        ],
        child: const App(),
      ),
    );
  } catch (e, stack) {
    debugPrint("ERRO CRÍTICO NA INICIALIZAÇÃO: $e");
    debugPrint(stack.toString());

    // Se falhar o init, tenta rodar sem quebrar totalmente (Fallback visual)
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => DarkMode(darkMode: true)),
          ChangeNotifierProvider(create: (context) => ActivePetProvider()),
          ChangeNotifierProvider(create: (context) => ActiveAccountProvider()),
          ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
          ChangeNotifierProvider(create: (context) => StoryPublishProvider()),
          ChangeNotifierProvider(create: (context) => TimelineProvider()),
          ChangeNotifierProvider(create: (context) => ProfileViewProvider()),
          ChangeNotifierProvider(create: (context) => UserRoleProvider()),
          ChangeNotifierProvider(
            create: (context) => FontSizeProvider(1.0, 'normal'),
          ),
          ChangeNotifierProvider(create: (context) => AccessibilityProvider()),
        ],
        child: const App(),
      ),
    );
  }
}

Future<void> _initializeBackgroundTask() async {
  try {
    await locator<NotificationService>().init();
  } catch (e) {
    debugPrint("Erro ao inicializar notificações (silencioso): $e");
  }
}

// Variável global supabase usada em vários services
final supabase = Supabase.instance.client;
