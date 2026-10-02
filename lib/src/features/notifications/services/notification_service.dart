import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:patas_web_app/src/external_services/secure_storage.dart';
import 'package:patas_web_app/src/localization/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/features/auth/services/user_database_service.dart';

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  // Singleton pattern from legacy to ensure compatibility if accessed directly
  // But we primarily use Locator now.
  // static final NotificationService _instance = NotificationService._internal();
  // factory NotificationService() => _instance;
  // NotificationService._internal();
  // COMMENTED OUT: We are using GetIt (Locator) for singleton management now.

  late final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _onNotificationClick =
      StreamController<String?>.broadcast();
  Stream<String?> get onNotificationClick => _onNotificationClick.stream;

  static const Map<String, String> notificationSounds = {
    'Padrão': 'default',
    'Miau 1 (Miau curto)': 'cat_meow00',
    'Miau 2 (Miau longo)': 'cat_meow01',
    'Ronrono': 'cat_purring',
    'Latido 1 (Latido forte)': 'dog_bark01',
    'Latido 2 (Latido rápido)': 'dog_bark02',
    'Uivo': 'dog_howl01',
  };

  static const String _soundPrefKey = 'notification_sound_pref';
  static const String _remindersKey = 'scheduled_reminders';

  // Trava em memória para impedir notificações duplicadas na status bar (15 segundos)
  static final Map<String, DateTime> _recentlyDisplayedPushKeys = {};

  /// Verifica se uma notificação com o mesmo título e corpo já foi exibida recentemente.
  /// Se já foi exibida nos últimos 15 segundos, retorna true para suprimir a duplicata.
  static bool shouldSuppressNotification(String? title, String? body) {
    if (title == null && body == null) return false;
    final now = DateTime.now();

    // Limpa entradas com mais de 30 segundos
    _recentlyDisplayedPushKeys.removeWhere((_, time) => now.difference(time).inSeconds > 30);

    final normalizedKey = '${(title ?? '').trim()}_${(body ?? '').trim()}';
    if (_recentlyDisplayedPushKeys.containsKey(normalizedKey)) {
      final lastShown = _recentlyDisplayedPushKeys[normalizedKey]!;
      if (now.difference(lastShown).inSeconds < 15) {
        debugPrint('[NotificationService] 🛑 Duplicata detectada na status bar! Suprimindo: "$title"');
        return true;
      }
    }

    _recentlyDisplayedPushKeys[normalizedKey] = now;
    return false;
  }

  /// Gera um Notification ID estável para que mesmo que haja reenvio do sistema,
  /// o Android substitua a notificação existente em vez de empilhar um segundo card.
  static int getStableNotificationId(String? title, String? body) {
    final combined = '${title ?? ''}_${body ?? ''}';
    return combined.hashCode & 0x7FFFFFFF;
  }

  // Combined Init
  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('NotificationService: Pulando inicialização do Firebase na Web.');
      return;
    }
    await Firebase.initializeApp();
    _firebaseMessaging = FirebaseMessaging.instance;

    // --- Local Notifications Init (From Legacy) ---
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _onNotificationClick.add(details.payload);
      },
    );

    // Initialize all potential sound channels
    await _initializeAllChannels();

    // Try to update default channel as a fallback (best effort for backend push)
    await _updateDefaultChannel();

    // Verificar se o app foi aberto por uma notificação (Legacy logic)
    final NotificationAppLaunchDetails? launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      Future.delayed(const Duration(seconds: 1), () {
        _onNotificationClick.add(launchDetails.notificationResponse?.payload);
      });
    }

    // --- Firebase Init ---
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification}');

        // Show local notification when foreground message arrives to ensure custom sound plays
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          final title = notification.title ?? '';
          final body = notification.body ?? '';

          // 🛑 Suprime duplicatas se já foi exibida recentemente por outro canal
          if (shouldSuppressNotification(title, body)) {
            return;
          }

          final dynamicChannelId = await getCurrentChannelId();
          final stableId = getStableNotificationId(title, body);

          _notificationsPlugin.show(
            stableId,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                dynamicChannelId,
                'Notificações do App',
                channelDescription: 'Canal principal de notificações',
                importance: Importance.max,
                priority: Priority.high,
                icon: 'ic_notification',
                // The sound is already configured in the channel itself!
              ),
              iOS: const DarwinNotificationDetails(),
            ),
          );
        }
      }
    });

    // 4. Get and Log Token
    await getFCMToken();

    // 5. Listen to Auth Changes to update token on login
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        getFCMToken();
      }
    });

    // 6. Listen to Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveFCMTokenToBackend(newToken);
    });
  }

  Future<void> updatePreferredSound(String soundKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundPrefKey, soundKey);
    debugPrint("Preferencia de som salva: $soundKey. Atualizando canal...");

    // Try to update the default channel (Backend Push compatibility)
    await _updateDefaultChannel();

    // Sync to Backend
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await locator
            .get<UserDatabaseService>()
            .updateNotificationSound(user.id, soundKey);
        debugPrint("Preferência de som sincronizada com o Backend!");
      } catch (e) {
        debugPrint("Erro ao sincronizar som com backend: $e");
      }
    }
  }

  /// Initializes all notification channels for the available sounds.
  /// This ensures that channels exist for Local Notifications immediately.
  Future<void> _initializeAllChannels() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 1. Create the Default High Importance Channel (Fallback)
      const AndroidNotificationChannel defaultChannel =
          AndroidNotificationChannel(
        'high_importance_channel',
        'Notificações Padrão',
        description: 'Canal principal de notificações',
        importance: Importance.max,
        playSound: true,
      );
      await androidPlugin.createNotificationChannel(defaultChannel);

      // 2. Create a channel for EACH custom sound
      for (var entry in notificationSounds.entries) {
        final soundRes = entry.value;
        if (soundRes == 'default') continue;

        final String channelId = 'channel_$soundRes'; // e.g. channel_cat_meow00
        final String channelName = 'Som: ${entry.key}';

        final AndroidNotificationChannel customChannel =
            AndroidNotificationChannel(
          channelId,
          channelName,
          description: 'Notificações com som de ${entry.key}',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound(soundRes),
          playSound: true,
        );

        await androidPlugin.createNotificationChannel(customChannel);
      }
      debugPrint("Todos os canais de notificação foram inicializados.");
    }
  }

  /// Updates (recreates) the 'high_importance_channel'...
  Future<void> _updateDefaultChannel() async {
    final soundRes = await getPreferredSound();
    debugPrint(
        "Atualizando canal 'high_importance_channel' para som: $soundRes");

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 1. Delete the existing channel to allow reconfiguration
      await androidPlugin.deleteNotificationChannel('high_importance_channel');

      // Pequeno delay
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Prepare the sound resource
      AndroidNotificationSound? sound;
      if (soundRes != 'default') {
        sound = RawResourceAndroidNotificationSound(soundRes);
      }

      // 3. Create the channel
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notificações do App',
        description: 'Canal principal de notificações',
        importance: Importance.max,
        sound: sound,
        playSound: true,
      );

      await androidPlugin.createNotificationChannel(channel);
      debugPrint("Canal Recriado! ID: high_importance_channel, Som: $soundRes");
    }
  }

  Future<String> getPreferredSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_soundPrefKey) ?? 'default';
  }

  // Helper to get channel ID for current preference
  Future<String> getCurrentChannelId() async {
    final soundRes = await getPreferredSound();
    if (soundRes == 'default') return 'high_importance_channel';
    return 'channel_$soundRes';
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        debugPrint("FCM Token: $token");
        await locator
            .get<SecureStorage>()
            .write(key: 'fcm_token', value: token);

        await _saveFCMTokenToBackend(token);
      }
      return token;
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> _saveFCMTokenToBackend(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await locator.get<UserDatabaseService>().updateFCMToken(user.id, token);
        debugPrint("FCM Token saved to Supabase for user ${user.id}");
      } catch (e) {
        debugPrint("Failed to save FCM Token to Supabase: $e");
      }
    }
  }

  // --- Legacy Methods for Vaccine Reminders ---

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    // Use dynamic channel!
    String channelId = await getCurrentChannelId();

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Lembretes de Vacina',
          channelDescription: 'Lembretes do Patas',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    await _saveReminder(id, title, scheduledDate);
  }

  Future<void> _saveReminder(int id, String title, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> reminders = prefs.getStringList(_remindersKey) ?? [];

    final Map<String, dynamic> newReminder = {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
    };

    reminders.add(jsonEncode(newReminder));
    await prefs.setStringList(_remindersKey, reminders);
  }

  Future<List<Map<String, dynamic>>> getScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> reminders = prefs.getStringList(_remindersKey) ?? [];

    return reminders
        .map((r) => jsonDecode(r) as Map<String, dynamic>)
        .where((r) {
      final date = DateTime.parse(r['date']);
      return date.isAfter(DateTime.now());
    }).toList();
  }

  Future<void> showLocalNotificationTest(
      String channelId, String soundName) async {
    // Ignore passed channelId, calculate current one dynamically
    final dynamicChannelId = await getCurrentChannelId();
    debugPrint('Testando notificação no canal: $dynamicChannelId');

    await _notificationsPlugin.show(
      888, // ID fixo para teste
      'Teste de Som',
      'Este é o som: $soundName',
      NotificationDetails(
        android: AndroidNotificationDetails(
          dynamicChannelId,
          'Teste de Som',
          channelDescription: 'Canal de teste',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);

    final prefs = await SharedPreferences.getInstance();
    final List<String> reminders = prefs.getStringList(_remindersKey) ?? [];
    reminders.removeWhere((r) {
      final decoded = jsonDecode(r);
      return decoded['id'] == id;
    });
    await prefs.setStringList(_remindersKey, reminders);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindersKey);
  }

  /// Dispara notificação local instantânea no dispositivo (Heads-Up Banner com som e vibração)
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (kIsWeb) return;
    try {
      // 🛑 Suprime duplicatas se já foi exibida recentemente por outro canal
      if (shouldSuppressNotification(title, body)) {
        return;
      }

      final dynamicChannelId = await getCurrentChannelId();
      final notificationId = id ?? getStableNotificationId(title, body);
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            dynamicChannelId,
            'Notificações do App',
            channelDescription: 'Canal principal de notificações',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      debugPrint('[NotificationService] Notificação instantânea exibida com sucesso: $title');
    } catch (e) {
      debugPrint('[NotificationService] Erro ao exibir notificação instantânea: $e');
    }
  }
}
