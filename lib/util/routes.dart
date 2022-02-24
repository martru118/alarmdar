import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/screens/alarm_details.dart';
import 'package:alarmdar/screens/alarm_form.dart';
import 'package:alarmdar/screens/alarms_list.dart';
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
      case AlarmDetails.route:
        return CupertinoPageRoute(builder: (context) {
          ScreenArguments arguments = args;
          return SafeArea(child: AlarmDetails(arguments.alarmInfo, arguments.isRinging));
        });

      //show the alarm form
      case AlarmForm.route:
        return CupertinoPageRoute(builder: (context) {
          ScreenArguments arguments = args;
          return SafeArea(child: AlarmForm(arguments.alarmInfo, arguments.title));
        });

      //show a list of alarms
      default: return MaterialPageRoute(builder: (context) {
        return SafeArea(child: AlarmsList());
      });
    }
  }

  //push route without context
  static void push(String route, ScreenArguments args) {
    Future.delayed(Duration.zero, () => _router.pushNamed(route, arguments: args));
  }
}

class ScreenArguments {
  final AlarmInfo alarmInfo;
  final String title;
  final bool isRinging;

  ScreenArguments(this.alarmInfo, {
    this.title,
    this.isRinging,
  });
}