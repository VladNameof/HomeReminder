// Local & Web Push Notification Service for HomeReminder
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/product_item.dart';
import 'web_notification_stub.dart'
    if (dart.library.html) 'web_notification_web.dart';

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      tz.initializeTimeZones();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init warning: $e');
    }
  }

  Future<void> scheduleProductReminder(ProductItem item) async {
    if (!_initialized || kIsWeb) return;
    try {
      final now = DateTime.now();
      var targetDate = DateTime(
        item.reminderDate.year,
        item.reminderDate.month,
        item.reminderDate.day,
        10,
        0,
      );
      if (targetDate.isBefore(now)) {
        targetDate = now.add(const Duration(seconds: 10));
      }

      const androidDetails = AndroidNotificationDetails(
        'homereminder_restock_channel',
        'Напоминания о покупках',
        channelDescription: 'Уведомления о заканчивающейся косметике и бытовой химии',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);

      final storeText = item.preferredStore != null
          ? 'Проверьте цену в ${item.preferredStore} (Rossmann / Hebe / Allegro / Ekodrogeria).'
          : 'Сравните цены в Rossmann, Hebe, Allegro и Ekodrogeria.';

      await _plugin.zonedSchedule(
        item.id,
        'Пора докупить: ${item.name}',
        'Осталось на ~${item.daysRemaining} дн. $storeText',
        tz.TZDateTime.from(targetDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification for ${item.name}: $e');
    }
  }

  Future<void> triggerInstantTestPush(ProductItem item) async {
    final title = '🔔 HomeReminder: ${item.name}';
    final body =
        'Осталось ${item.daysRemaining} дн. Магазин в Польше: ${item.preferredStore ?? "Rossmann / Hebe"}';

    if (kIsWeb) {
      showWebNotification(title, body);
      return;
    }
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'homereminder_restock_channel',
      'Напоминания о покупках',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _plugin.show(
      item.id + 10000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
