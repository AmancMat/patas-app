import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _onNotificationClick =
      StreamController<String?>.broadcast();
  Stream<String?> get onNotificationClick => _onNotificationClick.stream;

  static const String _remindersKey = 'scheduled_reminders';

  Future<void> init() async {
    // Inicializa Timezones
    tz.initializeTimeZones();

    // Tenta obter o fuso horário local ou usa um padrão (São Paulo)
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

    // Verificar se o app foi aberto por uma notificação
    final NotificationAppLaunchDetails? launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      // Pequeno delay para garantir que o Navigator esteja pronto
      Future.delayed(const Duration(seconds: 1), () {
        _onNotificationClick.add(launchDetails.notificationResponse?.payload);
      });
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Não agendar se a data for no passado
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaccine_reminders',
          'Lembretes de Vacina',
          channelDescription:
              'Canal de notificações para lembretes de vacinação dos pets',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    // Persistir o lembrete
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

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);

    // Remover da persistência
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
}
