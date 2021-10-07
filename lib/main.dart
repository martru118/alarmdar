import 'package:alarmdar/model/list_alarms.dart';
import 'package:alarmdar/util/gestures.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  NotificationService().init();

  runApp(Main());
}

class Main extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: GesturesProvider()),
      ],
      child: MaterialApp(
        title: "Alarmdar",
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,

        //route settings
        home: AlarmsList(),
        onGenerateRoute: (settings) => RouteGenerator.generateRoute(settings),
        navigatorKey: RouteGenerator.navigatorKey,

        //theme settings
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSwatch(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            accentColor: Colors.blueAccent,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );
  }
}