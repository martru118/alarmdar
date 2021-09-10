import 'package:alarmdar/splash.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Alarmdar());
}

class Alarmdar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String title = this.runtimeType.toString();

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      //route settings
      home: SplashScreen(),
      onGenerateRoute: (settings) => RouteGenerator.generateRoute(settings),
      navigatorKey: RouteGenerator.navigatorKey,

      //theme settings
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}