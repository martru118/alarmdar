import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final String channelId = 'alarm';
  final String channelName = 'Alarms';
  final String channelDescription = 'Alarms for your reminders';
  NotificationDetails channelInfo;

  var localNotifications;
  var notificationId = 100;

  Future<void> init() async {
    localNotifications = FlutterLocalNotificationsPlugin();

    //plugin setup
    var initAndroid = AndroidInitializationSettings('app_icon');
    var initSettings = InitializationSettings(android: initAndroid);
    localNotifications.initialize(
      initSettings,
      onSelectNotification: onSelectNotification,
    );

    //setup a notification channel
    var androidChannel = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'ticker',
    );

    channelInfo = NotificationDetails(android: androidChannel);
  }

  Future onSelectNotification(var payload) async {
    if (payload != null) {
      print('onSelectNotification::payload = $payload');
    }
  }

  //schedule a notification
  void schedule(String title, String body, tz.TZDateTime when, String payload) {
    localNotifications.zonedSchedule(
      notificationId++,
      title,
      body,
      when,
      channelInfo,
      payload: payload,
      uiLocalNotificationDateInterpretation: null,
      androidAllowWhileIdle: true,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    return localNotifications.pendingNotificationRequests();
  }
}