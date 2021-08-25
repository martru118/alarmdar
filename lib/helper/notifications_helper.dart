import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/timezone.dart' as tz;

class Notifications {
  final channelId = 'testNotifications';
  final channelName = 'Test Notifications';
  final channelDescription = 'Test Notification Channel';

  var localNotifications;

  NotificationDetails platformChannelInfo;
  var notificationId = 100;

  Future<void> init() async {
    localNotifications = FlutterLocalNotificationsPlugin();
    if (Platform.isIOS) {permissionsIOS();}

    //plugin setup
    var initAndroid = AndroidInitializationSettings('mipmap/ic_launcher');
    var initIos = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (int id, String title, String body, String payload) {
        print('$id/$title/$body/$payload');
        return null;
      },
    );
    var initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIos,
    );
    localNotifications.initialize(
      initSettings,
      onSelectNotification: onSelectNotification,
    );

    // setup a notification channel
    var androidChannel = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'ticker',
    );
    var iosChannel = IOSNotificationDetails();

    platformChannelInfo = NotificationDetails(
      android: androidChannel,
      iOS: iosChannel,
    );
  }

  //set permissions for IOS platform
  void permissionsIOS() {
    localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>().requestPermissions(
      alert: false,
      badge: true,
      sound: true,
    );
  }

  Future onSelectNotification(var payload) async {
    if (payload != null) {
      print('onSelectNotification::payload = $payload');
    }
  }

  sendNow(String title, String body, String payload) {
    print(localNotifications);
    localNotifications.show(
      notificationId++,
      title,
      body,
      platformChannelInfo,
      payload: payload,
    );
  }

  sendLater(String title, String body, tz.TZDateTime when, String payload) {
    localNotifications.zonedSchedule(
      notificationId++,
      title,
      body,
      when,
      platformChannelInfo,
      payload: payload,
      uiLocalNotificationDateInterpretation: null,
      androidAllowWhileIdle: true,
    );
  }

  Future<List<PendingNotificationRequest>> pending() async {
    return localNotifications.pendingNotificationRequests();
  }
}
