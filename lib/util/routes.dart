import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/model/preview_alarm.dart';
import 'package:alarmdar/model/form_alarm.dart';
import 'package:alarmdar/model/list_alarms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static final navigatorKey = new GlobalKey<NavigatorState>();
  static NavigatorState get _router => navigatorKey.currentState;

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
        return CupertinoPageRoute(builder: (context) {
          ScreenArguments arguments = args;

          return AlarmForm(
            alarmInfo: arguments.alarmInfo,
            title: arguments.title,
          );
        });

      //show a list of alarms
      default: return MaterialPageRoute(builder: (context) => AlarmsList());
    }
  }

  //push an activity without context
  static void push(Widget activity) async {
    _router.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => activity),
      (Route<dynamic> route) => false,
    );
  }
}

class ScreenArguments {
  final AlarmInfo alarmInfo;
  final String title;
  final bool isRinging;

  ScreenArguments({
    this.alarmInfo,
    this.title,
    this.isRinging,
  });
}