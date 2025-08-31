import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/atividade.dart';

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestBadgePermission: true,
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
    // Cancel any existing notification for this activity
    await cancelAtividadeNotification(atividade.id!);
    
    // Don't schedule if notification timing is none
    if (atividade.notificationTiming == NotificationTiming.none) {
      return;
    }
    
    final notificationDuration = atividade.notificationTiming.duration;
    if (notificationDuration == null) return;
    
    final notificationTime = atividade.dataHora.subtract(notificationDuration);
    
    // Only schedule if the notification time is in the future
    if (notificationTime.isAfter(DateTime.now())) {
      String message;
      if (notificationDuration == Duration.zero) {
        message = 'Sua atividade "${atividade.titulo}" está começando agora!';
      } else {
        message = 'Sua atividade "${atividade.titulo}" começa em ${_formatDuration(notificationDuration)}';
      }
      
      try {
        await _notifications.zonedSchedule(
          atividade.id!,
          'Lembrete de Atividade',
          message,
          tz.TZDateTime.from(notificationTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'atividades_channel',
              'Atividades',
              channelDescription: 'Notificações de atividades',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              enableVibration: true,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        // If exact alarms fail, try with inexact scheduling
        await _notifications.zonedSchedule(
          atividade.id!,
          'Lembrete de Atividade',
          message,
          tz.TZDateTime.from(notificationTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'atividades_channel',
              'Atividades',
              channelDescription: 'Notificações de atividades',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              enableVibration: true,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} dia${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hora${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minuto${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'agora';
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

  Future<List<PendingNotificationRequest>> getPendingNotifications() async => await _notifications.pendingNotificationRequests();

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
