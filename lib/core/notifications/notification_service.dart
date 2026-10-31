import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../config/theme/app_colors.dart';

export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show DateTimeComponents;

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = NotificationChannels.reminders,
  });
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = NotificationChannels.reminders,
    DateTimeComponents? matchDateTimeComponents,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
}

class NotificationChannels {
  static const String reminders = 'daily_life_reminders';
  static const String countdowns = 'daily_life_countdowns';
  static const String focus = 'daily_life_focus';
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  NotificationServiceImpl({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Timezones
      tz.initializeTimeZones();

      // 2. Android Initialization Settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // 3. Darwin / iOS Initialization Settings
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        },
      );

      // 4. Create Notification Channels for Android
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              NotificationChannels.reminders,
              'Daily Life Reminders',
              description:
                  'Notifications for smart reminders and planner tasks',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            ),
          );

          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              NotificationChannels.countdowns,
              'Important Countdowns',
              description:
                  'Advance alerts and countdown milestone notifications',
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );

          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              NotificationChannels.focus,
              'Pomodoro Focus Alerts',
              description: 'Alerts when Pomodoro focus sprint or breaks end',
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization exception: $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImpl != null) {
          final granted = await androidImpl.requestNotificationsPermission();
          return granted ?? false;
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        final darwinImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (darwinImpl != null) {
          final granted = await darwinImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  @override
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = NotificationChannels.reminders,
  }) async {
    try {
      final details = _getNotificationDetails(channelId: channelId);
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = NotificationChannels.reminders,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      // If the scheduled time is in the past and non-repeating, trigger instantly or ignore
      final now = DateTime.now();
      if (scheduledDate.isBefore(now) && matchDateTimeComponents == null) {
        await showInstantNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
          channelId: channelId,
        );
        return;
      }

      final details = _getNotificationDetails(channelId: channelId);
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      // Fallback: If exact alarms fail or permission is restricted, show instant confirmation
      await showInstantNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
      );
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  NotificationDetails _getNotificationDetails({required String channelId}) {
    String channelName;
    String channelDesc;

    switch (channelId) {
      case NotificationChannels.countdowns:
        channelName = 'Important Countdowns';
        channelDesc = 'Notifications for milestone events and countdowns';
        break;
      case NotificationChannels.focus:
        channelName = 'Pomodoro Focus Alerts';
        channelDesc = 'Alerts for Pomodoro timer and breaks';
        break;
      case NotificationChannels.reminders:
      default:
        channelName = 'Daily Life Reminders';
        channelDesc = 'Notifications for scheduled tasks and reminders';
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.moduleTime,
      ledColor: AppColors.moduleTime,
      ledOnMs: 1000,
      ledOffMs: 500,
      showWhen: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }
}
