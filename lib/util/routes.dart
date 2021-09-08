import 'package:alarmdar/auth/splash.dart';
import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/model/preview_alarm.dart';
import 'package:alarmdar/model/form_alarm.dart';
import 'package:alarmdar/model/list_alarms.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static final navigatorKey = new GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    //set named routes
    switch (settings.name) {
      //show the alarm preview
      case AlarmPreview.route:
        return CupertinoPageRoute(builder: (context) {
          ScreenArguments arguments = args;

          return AlarmPreview(
            alarmInfo: arguments.alarmInfo,
            isRinging: arguments.isRinging,
          );
        });

      //show the alarm form
      case AlarmForm.route:
        return MaterialPageRoute(builder: (context) {
          ScreenArguments arguments = args;

          return AlarmForm(
            alarmInfo: arguments.alarmInfo,
            title: arguments.title,
            account: arguments.accountName,
          );
        });

      //show the splash screen
      case SplashScreen.route:
        return MaterialPageRoute(builder: (context) {
          return SplashScreen();
        });

      //show a list of alarms
      default:
        return MaterialPageRoute(builder: (context) {
          ScreenArguments arguments = args;
          return AlarmsList(user: arguments.user);
        });
    }
  }

  //push an activity without context
  static void push(Widget activity) {
    navigatorKey.currentState.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => activity),
      (Route<dynamic> route) => false,
    );
  }
}

class ScreenArguments {
  final AlarmInfo alarmInfo;
  final User user;
  final String title;
  final String accountName;
  final bool isRinging;

  ScreenArguments({
    this.alarmInfo,
    this.user,
    this.title,
    this.accountName,
    this.isRinging,
  });
}