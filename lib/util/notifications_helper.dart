import 'dart:io' show Platform;

import 'package:alarmdar/model/alarm_info.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final String channelId = 'alarm';
  final String channelName = 'Alarms';
  final String channelDescription = 'An alarm that rings when you have a reminder';

  NotificationDetails channelInfo;
  var localNotifications;

  Future<void> init() async {
    localNotifications = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();

    //plugin setup
    var initAndroid = AndroidInitializationSettings('app_icon');
    var initSettings = InitializationSettings(android: initAndroid, iOS: null);
    localNotifications.initialize(
      initSettings,
      onSelectNotification: onSelectNotification,
    );

    //setup a notification channel
    var androidChannel = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound("ringtone.webm"),
      timeoutAfter: 120000,
    );

    channelInfo = NotificationDetails(android: androidChannel, iOS: null);
  }

  Future onSelectNotification(var payload) async {
    if (payload != null) {
      print('onSelectNotification::payload = $payload');
    }
  }

  void schedule(AlarmInfo alarmInfo, int timestamp) {
    //determine when to send notification
    DateTime start = DateTime.fromMillisecondsSinceEpoch(timestamp);
    tz.TZDateTime when = tz.TZDateTime(
      tz.local,
      start.year,
      start.month,
      start.day,
      start.hour,
      start.minute,
    );

    //schedule notification at a specific date
    localNotifications.zonedSchedule(
      alarmInfo.notifID,
      alarmInfo.name,
      alarmInfo.description,
      when,
      channelInfo,
      payload: alarmInfo.toJson(),
      androidAllowWhileIdle: true,
    );
  }

  void cancel(int id) async {
    await localNotifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    return localNotifications.pendingNotificationRequests();
  }

  void cancelPendingRequests() async {
    await localNotifications.cancelAll();
  }
}