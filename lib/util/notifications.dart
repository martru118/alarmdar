import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/model/alarm_preview.dart';
import 'package:alarmdar/util/firebase_utils.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final String channelId = 'alarmsChannel';
  final String channelName = 'Reminder Alarms';
  final String channelDescription = 'Alarms that ring when you have a reminder';

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
      playSound: true,
      sound: RawResourceAndroidNotificationSound("ringtone.webm"),
    );

    channelInfo = NotificationDetails(android: androidChannel, iOS: null);
  }

  Future onSelectNotification(var payload) async {
    print("Notification has been selected");

    //show preview when alarm rings
    if (payload != null) {
      final db = new AlarmModel();
      AlarmInfo alarmInfo = await db.retrievebyID(payload);
      RouteGenerator.push(AlarmPreview(alarmInfo: alarmInfo, isRinging: true));
    }
  }

  void schedule(AlarmInfo alarmInfo, int timestamp) {
    //determine when to send notification
    DateTime start = new DateTime.fromMillisecondsSinceEpoch(timestamp);
    tz.TZDateTime when = new tz.TZDateTime(
      tz.local,
      start.year,
      start.month,
      start.day,
      start.hour,
      start.minute,
    );

    //schedule notification at a specific date
    localNotifications.zonedSchedule(
      alarmInfo.createdAt,
      alarmInfo.name,
      alarmInfo.description,
      when,
      channelInfo,
      payload: alarmInfo.createdAt.toString(),
      androidAllowWhileIdle: true,
    );
  }

  void cancel(int id) async {
    try {
      await localNotifications.cancel(id);
    } catch (e) {
      e.toString();
    }
  }

  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    return localNotifications.pendingNotificationRequests();
  }

  void cancelPendingRequests() async {
    try {
      await localNotifications.cancelAll();
    } catch (e) {
      e.toString();
    }
  }
}