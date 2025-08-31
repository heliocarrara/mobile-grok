import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/atividade.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> scheduleAtividadeNotification(Atividade atividade) async {
    // Agendar notificação 15 minutos antes da atividade
    final notificationTime = atividade.dataHora.subtract(const Duration(minutes: 15));
    
    // Só agendar se a atividade for no futuro
    if (notificationTime.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        atividade.id!,
        'Lembrete de Atividade',
        'Sua atividade "${atividade.titulo}" começa em 15 minutos',
        tz.TZDateTime.from(notificationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'atividades_channel',
            'Atividades',
            channelDescription: 'Notificações de atividades',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> scheduleAtividadeNotificationNow(Atividade atividade) async {
    await _notifications.show(
      atividade.id!,
      'Nova Atividade',
      'Atividade "${atividade.titulo}" foi criada',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'atividades_channel',
          'Atividades',
          channelDescription: 'Notificações de atividades',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancelAtividadeNotification(int atividadeId) async {
    await _notifications.cancel(atividadeId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Agendar notificações para múltiplas atividades
  Future<void> scheduleMultipleAtividades(List<Atividade> atividades) async {
    for (final atividade in atividades) {
      if (!atividade.concluida) {
        await scheduleAtividadeNotification(atividade);
      }
    }
  }

  // Verificar se as notificações estão habilitadas
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    
    return true; // Para iOS, assumimos que estão habilitadas
  }
}
