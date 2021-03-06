import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/screens/alarm_details.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final String _channelID = 'alarmsChannel';
  final String _channelName = 'Reminder Alarms';
  final String _channelDesc = 'Alarms that ring when you have a reminder';

  NotificationDetails _channelInfo;
  var _localNotifications, _appLaunchDetails;

  //create singleton
  static final NotificationService _notifications  = NotificationService._internal();
  factory NotificationService() => _notifications;
  NotificationService._internal();

  Future<void> init() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();

    //plugin setup
    var initAndroid = AndroidInitializationSettings("ic_notification");
    var initSettings = InitializationSettings(android: initAndroid);
    _localNotifications.initialize(
      initSettings,
      onSelectNotification: _onSelectNotification,
    );

    //launch app from notification
    _appLaunchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    if (_appLaunchDetails.didNotificationLaunchApp) {
      var payload = _appLaunchDetails.payload;
      _onSelectNotification(payload);
    }

    //setup a notification channel
    List<int> flags = const [4];
    var androidChannel = AndroidNotificationDetails(
      _channelID,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      color: const Color.fromARGB(255, 3, 169, 244),
      playSound: true,
      sound: RawResourceAndroidNotificationSound("remix"),
      enableVibration: true,
      enableLights: true,
      ongoing: true,
      additionalFlags: Int32List.fromList(flags),
    );

    _channelInfo = NotificationDetails(android: androidChannel);
    _pendingRequests();
  }

  Future _onSelectNotification(String payload) async {
    print("Send payload $payload");

    //show preview when alarm rings
    if (payload != null) {
      AlarmInfo alarmInfo = AlarmInfo.fromMap(jsonDecode(payload));
      RouteGenerator.push(AlarmDetails.route, new ScreenArguments(alarmInfo, isRinging: true));
    }
  }

  void schedule(AlarmInfo alarmInfo, int timestamp) async {
    int secOffset = new Random().nextInt(5000);
    tz.TZDateTime when = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, timestamp + secOffset);
    print("Alarm is scheduled for $when; validated at ${tz.TZDateTime.now(tz.local)}");

    //schedule notification at a specific date
    await _localNotifications.zonedSchedule(
      alarmInfo.hashcode,
      alarmInfo.name,
      alarmInfo.description,
      when,
      _channelInfo,
      payload: jsonEncode(alarmInfo.toJson()),
      androidAllowWhileIdle: true,
    );

    _pendingRequests();
  }

  void cancel(int id) async {
    try {
      //cancel notification, if it exists
      await _localNotifications.cancel(id);
      _pendingRequests();
    } catch (e) {
      e.toString();
    }
  }

  //get notification queue
  void _pendingRequests() async {
    List<PendingNotificationRequest> requests = await _localNotifications.pendingNotificationRequests();
    print("${requests.length} notifications pending");
  }
}