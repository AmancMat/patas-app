import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:patas_web_app/src/models/notification_model.dart';
import 'package:patas_web_app/src/features/notifications/utils/web_notification_prompt_helper.dart'
    if (dart.library.html) 'package:patas_web_app/src/features/notifications/utils/web_notification_prompt_helper_web.dart';
import 'package:patas_web_app/src/localization/locator.dart';
import 'package:patas_web_app/src/features/notifications/services/notification_service.dart';
import '../../../../main.dart';

class SupabaseNotificationService {
  final _supabase = supabase;

  static StreamSubscription? _webRealtimeSub;
  static final Set<String> _knownNotificationIds = {};
  static bool _hasLoadedInitialSnapshot = false;

  /// Inicia o listener de notificações em tempo real na Web para disparar
  /// a notificação nativa do navegador (Desktop Notification).
  void initWebRealtimeListener() {
    if (!kIsWeb) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Se já estiver ativo para este usuário, não duplica
    if (_webRealtimeSub != null) return;

    _hasLoadedInitialSnapshot = false;
    _knownNotificationIds.clear();

    _webRealtimeSub = streamNotifications().listen((notifications) {
      if (!_hasLoadedInitialSnapshot) {
        // Registra notificações existentes para não disparar push no histórico antigo
        for (final n in notifications) {
          _knownNotificationIds.add(n.id);
        }
        _hasLoadedInitialSnapshot = true;
        debugPrint(
          '🔔 [WebNotification] Snapshot inicial com ${_knownNotificationIds.length} notificações registradas.',
        );
        return;
      }

      // Detecta novas notificações inseridas em tempo real
      for (final n in notifications) {
        if (!_knownNotificationIds.contains(n.id)) {
          _knownNotificationIds.add(n.id);
          debugPrint('🔔 [WebNotification] Nova notificação detectada: ${n.title}');
          showBrowserNotification(
            title: n.title,
            body: n.content,
          );
        }
      }
    }, onError: (e) {
      debugPrint('⚠️ [WebNotification] Erro no stream de notificações: $e');
    });
  }

  // Conjunto em memória para bloquear disparos simultâneos concorrentes da mesma notificação
  static final Set<String> _inMemoryRecentKeys = <String>{};

  /// Remove duplicatas da lista (tanto por ID quanto por conteúdo idêntico no mesmo intervalo de tempo)
  static List<NotificationModel> deduplicateList(List<NotificationModel> list) {
    final seenIds = <String>{};
    final seenKeys = <String>{};
    final uniqueList = <NotificationModel>[];

    for (final item in list) {
      if (seenIds.contains(item.id)) continue;
      seenIds.add(item.id);

      // Chave baseada em título, corpo e minuto de criação para agrupar duplicatas acidentais
      final minuteKey = '${item.userId}_${item.title}_${item.content}_${item.createdAt.year}_${item.createdAt.month}_${item.createdAt.day}_${item.createdAt.hour}_${item.createdAt.minute}';
      if (seenKeys.contains(minuteKey)) continue;
      seenKeys.add(minuteKey);

      uniqueList.add(item);
    }
    return uniqueList;
  }

  /// Busca as notificações do usuário atual
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('notifications')
          .select('*, pets(name, photo_url)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return deduplicateList(list);
    } catch (e) {
      debugPrint('SupabaseNotificationService: Erro ao buscar: $e');
      return [];
    }
  }

  /// Ouve novas notificações em tempo real (ordenadas da mais recente no topo para a mais antiga)
  Stream<List<NotificationModel>> streamNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) {
          final list = data
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return deduplicateList(list);
        });
  }

  /// Marca uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      debugPrint('SupabaseNotificationService: Erro ao marcar como lida: $e');
    }
  }

  /// Marca todas como lidas
  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('SupabaseNotificationService: Erro ao marcar todas: $e');
    }
  }

  /// Conta notificações não lidas
  Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('SupabaseNotificationService: Erro ao contar não lidas: $e');
      return 0;
    }
  }

  /// Stream com a contagem de não lidas
  Stream<int> unreadCountStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(0);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) => data.where((json) => json['is_read'] == false).length);
  }

  /// Cria uma nova notificação (usado internamente pelos outros serviços)
  Future<void> sendNotification({
    required String receiverUserId,
    String? senderPetId,
    required NotificationType type,
    required String title,
    required String content,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      // Não notificar a si mesmo (exceto em lembretes e confirmações essenciais: vacinas, doações, resgates)
      final currentUser = _supabase.auth.currentUser;
      final bool allowSelfNotification = type == NotificationType.vaccine ||
          type == NotificationType.donation ||
          type == NotificationType.rescueAlert;

      if (currentUser?.id == receiverUserId && !allowSelfNotification) {
        return;
      }

      // ─────────────────────────────────────────────────────────────
      // 1. Trava em memória contra disparos concorrentes simultâneos (15 segundos)
      // ─────────────────────────────────────────────────────────────
      final memoryKey = '${receiverUserId}_${type.name}_$title';
      if (_inMemoryRecentKeys.contains(memoryKey)) {
        debugPrint('SupabaseNotificationService: Bloqueado disparo duplicado em memória para: $memoryKey');
        return;
      }
      _inMemoryRecentKeys.add(memoryKey);
      // Libera após 15 segundos
      Future.delayed(const Duration(seconds: 15), () {
        _inMemoryRecentKeys.remove(memoryKey);
      });

      // ─────────────────────────────────────────────────────────────
      // 2. Trava no banco contra inserção duplicada recente (últimos 15 segundos)
      // ─────────────────────────────────────────────────────────────
      try {
        final recentThreshold = DateTime.now().toUtc().subtract(const Duration(seconds: 15)).toIso8601String();
        final existing = await _supabase
            .from('notifications')
            .select('id')
            .eq('user_id', receiverUserId)
            .eq('title', title)
            .gte('created_at', recentThreshold)
            .limit(1);

        if ((existing as List).isNotEmpty) {
          debugPrint('SupabaseNotificationService: Notificação já existe no banco recentemente. Ignorando.');
          return;
        }
      } catch (dbCheckErr) {
        debugPrint('SupabaseNotificationService: Aviso na checagem de duplicidade: $dbCheckErr');
      }

      await _supabase.from('notifications').insert({
        'user_id': receiverUserId,
        'sender_pet_id': senderPetId,
        'type': type == NotificationType.rescueAlert ? 'rescue_alert' : type.name,
        'title': title,
        'content': content,
        'data': data,
      });

      // Se a notificação for para o próprio usuário conectado no dispositivo móvel,
      // dispara imediatamente a notificação local para feedback visual e sonoro imediato
      if (!kIsWeb && currentUser?.id == receiverUserId) {
        try {
          if (locator.isRegistered<NotificationService>()) {
            await locator.get<NotificationService>().showInstantNotification(
              title: title,
              body: content,
            );
          }
        } catch (notifErr) {
          debugPrint('SupabaseNotificationService: Aviso ao disparar notificação local: $notifErr');
        }
      }
    } catch (e) {
      debugPrint('SupabaseNotificationService: Erro ao enviar: $e');
    }
  }
}
