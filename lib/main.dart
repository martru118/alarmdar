import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'event/list_events.dart';

void main() => runApp(Main());
class Main extends StatelessWidget {
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
          return MaterialApp(
            title: "Events",
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            themeMode: ThemeMode.system,
            home: CalendarEvents(title: "Events"),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}