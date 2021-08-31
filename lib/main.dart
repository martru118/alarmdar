import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'model/list_alarms.dart';

void main() {
  runApp(Main());
}

class Main extends StatelessWidget {
  final String title = "Alarmdar";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        //handle connection error
        if (snapshot.hasError) {
          print("Error initializing database");
          return Text("Error initializing database");
        }

        //handle connection success
        if (snapshot.connectionState == ConnectionState.done) {
          NotificationService().init();

          return MaterialApp(
            title: title,
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system,

            //route settings
            home: AlarmsList(title: title),
            onGenerateRoute: (settings) => RouteGenerator.generateRoute(settings),
            navigatorKey: RouteGenerator.navigatorKey,

            //theme settings
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.lightBlue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.orange,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}