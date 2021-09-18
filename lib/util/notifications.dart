import 'dart:typed_data';

import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/model/preview_alarm.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_utils.dart';

class NotificationService {
  final String channelID = 'alarmsChannel';
  final String channelName = 'Reminder Alarms';
  final String channelDescription = 'Alarms that ring when you have a reminder';

  NotificationDetails channelInfo;
  var localNotifications, notificationDetails;

  //create singleton
  static final NotificationService notifications  = NotificationService.internal();
  factory NotificationService() => notifications;
  NotificationService.internal();

  Future<void> init() async {
    localNotifications = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();

    //plugin setup
    var initAndroid = AndroidInitializationSettings('app_icon');
    var initSettings = InitializationSettings(android: initAndroid);
    localNotifications.initialize(
      initSettings,
      onSelectNotification: onSelectNotification,
    );

    //retrieve alarm uri from method channel
    final MethodChannel platform = MethodChannel("MethodChannel");
    final String alarmUri = await platform.invokeMethod("getAlarmUri");
    const int flag = 4;

    //setup a notification channel
    var androidChannel = AndroidNotificationDetails(
      channelID,
      channelName,
      channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound("remix"),
      enableVibration: true,
      additionalFlags: Int32List.fromList([flag]),
    );

    channelInfo = NotificationDetails(android: androidChannel);
  }

  Future onSelectNotification(var payload) async {
    final db = new AlarmModel();
    print("Send payload $payload");

    //show preview when alarm rings
    if (payload != null) {
      AlarmInfo alarmInfo = await db.retrievebyID(payload);
      RouteGenerator.push(AlarmPreview(alarmInfo: alarmInfo, isRinging: true));
    }
  }

  void schedule(AlarmInfo alarmInfo, int timestamp) {
    tz.TZDateTime when = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, timestamp);

    //schedule notification at a specific date
    localNotifications.zonedSchedule(
      alarmInfo.hashcode,
      alarmInfo.name,
      alarmInfo.description,
      when,
      channelInfo,
      payload: alarmInfo.hashcode.toString(),
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