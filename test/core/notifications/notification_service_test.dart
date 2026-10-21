import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/notifications/notification_service.dart';
import 'fake_notification_service.dart';

void main() {
  late FakeNotificationService service;

  setUp(() {
    service = FakeNotificationService();
  });

  group('NotificationService Contract & Channels Tests', () {
    test('defines required production notification channels', () {
      expect(NotificationChannels.reminders, 'daily_life_reminders');
      expect(NotificationChannels.countdowns, 'daily_life_countdowns');
      expect(NotificationChannels.focus, 'daily_life_focus');
    });

    test('initializes correctly and requests permissions', () async {
      expect(service.isInitialized, isFalse);

      await service.initialize();
      expect(service.isInitialized, isTrue);

      final granted = await service.requestPermissions();
      expect(granted, isTrue);
    });

    test('shows instant notifications with correct channel and payload', () async {
      await service.showInstantNotification(
        id: 101,
        title: 'Focus Sprint Ended',
        body: 'Take a 5-minute break',
        channelId: NotificationChannels.focus,
        payload: 'focus_sprint_end',
      );

      expect(service.instantNotifications.length, 1);
      final item = service.instantNotifications.first;
      expect(item.id, 101);
      expect(item.title, 'Focus Sprint Ended');
      expect(item.body, 'Take a 5-minute break');
      expect(item.channelId, NotificationChannels.focus);
      expect(item.payload, 'focus_sprint_end');
    });

    test('schedules notifications for reminders and countdowns', () async {
      final scheduledTime = DateTime.now().add(const Duration(hours: 2));

      await service.scheduleNotification(
        id: 202,
        title: 'Team Standup',
        body: 'Scheduled for 10:00 AM',
        scheduledDate: scheduledTime,
        channelId: NotificationChannels.reminders,
        payload: 'planner_reminder_202',
      );

      expect(service.scheduledNotifications.length, 1);
      final item = service.scheduledNotifications.first;
      expect(item.id, 202);
      expect(item.title, 'Team Standup');
      expect(item.scheduledDate, scheduledTime);
      expect(item.channelId, NotificationChannels.reminders);
    });

    test('cancels specific notification by ID', () async {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));

      await service.scheduleNotification(
        id: 301,
        title: 'Doctor Appointment',
        body: 'Tomorrow at 09:00 AM',
        scheduledDate: scheduledTime,
        channelId: NotificationChannels.reminders,
      );

      expect(service.scheduledNotifications.length, 1);

      await service.cancelNotification(301);

      expect(service.cancelledIds.contains(301), isTrue);
      expect(service.scheduledNotifications.isEmpty, isTrue);
    });

    test('cancels all notifications', () async {
      final time1 = DateTime.now().add(const Duration(days: 1));
      final time2 = DateTime.now().add(const Duration(days: 7));

      await service.scheduleNotification(
        id: 401,
        title: 'Birthday 1-Day Alert',
        body: 'Tomorrow!',
        scheduledDate: time1,
        channelId: NotificationChannels.countdowns,
      );
      await service.scheduleNotification(
        id: 402,
        title: 'Birthday 7-Day Alert',
        body: 'Next week!',
        scheduledDate: time2,
        channelId: NotificationChannels.countdowns,
      );

      expect(service.scheduledNotifications.length, 2);

      await service.cancelAllNotifications();

      expect(service.allCancelled, isTrue);
      expect(service.scheduledNotifications.isEmpty, isTrue);
    });
  });
}
