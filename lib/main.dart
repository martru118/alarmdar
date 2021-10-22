import 'package:alarmdar/model/alarm_dao.dart';
import 'package:alarmdar/screens/alarms_list.dart';
import 'package:alarmdar/model/gestures.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService().init();

  runApp(Main());
}

class Main extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        FutureProvider<Stream<List>>(
          initialData: Stream.value([]).cast<List>(),
          create: (context) => AlarmDao().alarmStream(),
          catchError: (_, e) => Stream.error(e),
        ),
        ChangeNotifierProvider.value(value: GesturesProvider()),
      ],

      child: MaterialApp(
        title: "Alarmdar",
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,

        //route settings
        initialRoute: AlarmsList.route,
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
            accentColor: Colors.lightBlue,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );
  }
}