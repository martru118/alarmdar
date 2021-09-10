import 'dart:async';

import 'package:alarmdar/model/list_alarms.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  static const String route = "/splash";

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    //show splash screen for a few seconds
    Future.delayed(const Duration(seconds: 4), () {
      print("Exit splash screen");
      RouteGenerator.push(AlarmsList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              //splash screen layout
              Expanded(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //logo
                      Card(
                        shape: CircleBorder(),
                        color: Colors.transparent,
                        elevation: 10,
                        child: CircleAvatar(
                          maxRadius: size.width/2.5,
                          backgroundColor: Colors.transparent,
                          child: Image.asset("assets/app_icon.png"),
                        ),
                      ), SizedBox(height: 20),

                      //title and short description
                      Text('Alarmdar',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      ),
                      Text('Alarms with Reminders',
                        style: TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          fontSize: 24,
                        ),
                      ),
                    ]
                  ),
                ),
              ),

              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ]
          ),
        ),
      ),
    );
  }
}