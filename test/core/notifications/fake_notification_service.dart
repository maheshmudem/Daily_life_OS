import 'package:daily_life_os/core/notifications/notification_service.dart';

class ScheduledNotificationRecord {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? payload;
  final String channelId;

  ScheduledNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
    required this.channelId,
  });
}

class InstantNotificationRecord {
  final int id;
  final String title;
  final String body;
  final String? payload;
  final String channelId;

  InstantNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    required this.channelId,
  });
}

class FakeNotificationService implements NotificationService {
  bool isInitialized = false;
  bool permissionsGranted = true;
  final List<InstantNotificationRecord> instantNotifications = [];
  final List<ScheduledNotificationRecord> scheduledNotifications = [];
  final List<int> cancelledIds = [];
  bool allCancelled = false;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    return permissionsGranted;
  }

  @override
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = NotificationChannels.reminders,
  }) async {
    instantNotifications.add(
      InstantNotificationRecord(
        id: id,
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
      ),
    );
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = NotificationChannels.reminders,
  }) async {
    scheduledNotifications.add(
      ScheduledNotificationRecord(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        channelId: channelId,
      ),
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelledIds.add(id);
    scheduledNotifications.removeWhere((item) => item.id == id);
    instantNotifications.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    allCancelled = true;
    scheduledNotifications.clear();
    instantNotifications.clear();
  }

  void reset() {
    isInitialized = false;
    permissionsGranted = true;
    instantNotifications.clear();
    scheduledNotifications.clear();
    cancelledIds.clear();
    allCancelled = false;
  }
}
