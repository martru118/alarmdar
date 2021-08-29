import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/model/alarm_preview.dart';
import 'package:alarmdar/model/form_alarm.dart';
import 'package:alarmdar/model/list_alarms.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static final navigatorKey = new GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    //set named routes
    switch (settings.name) {
      //show the alarm preview
      case "preview":
        return MaterialPageRoute(builder: (context) {
          ScreenArguments arguments = args;

          return AlarmPreview(
            alarmInfo: arguments.alarmInfo,
            isRinging: arguments.isRinging,
          );
        });

      //show the alarm form
      case "form":
        return MaterialPageRoute(builder: (context) {
          ScreenArguments arguments = args;

          return AlarmForm(
            alarmInfo: arguments.alarmInfo,
            title: arguments.title,
          );
        });

      //show a list of alarms
      default:
        return MaterialPageRoute(builder: (context) {
          ScreenArguments arguments = args;
          return AlarmsList(title: arguments.title);
        });
    }
  }

  //push an activity without context
  static void push(Widget activity) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => activity));
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