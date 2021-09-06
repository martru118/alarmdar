import 'dart:async';

import 'package:alarmdar/auth/authenticator.dart';
import 'package:alarmdar/model/list_alarms.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_button/sign_button.dart';

class SplashScreen extends StatefulWidget {
  static const String route = "/splash";

  @override
  State<StatefulWidget> createState() => SplashState();
}

class SplashState extends State<SplashScreen> {
  final auth = new Authenticator();

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    //logo
                    Card(
                      shape: CircleBorder(),
                      elevation: 10,
                      child: CircleAvatar(
                        maxRadius: size.width/2.5,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          "assets/app_icon.png",
                        ),
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

              //sign in button
              FutureBuilder(
                future: auth.getUser(),
                builder: (context, snapshot) {
                  //handle connection error
                  if (snapshot.hasError) {
                    print("Error initializing Firebase");
                    return Text('Error initializing Firebase');
                  }

                  //handle connection completion
                  if (snapshot.hasData) {
                    final data = snapshot.data as User;
                    Timer(new Duration(seconds: 3), () {
                      //login in with current user data
                      onLogin(context, AlarmsList.route, data);
                    });
                  } else {
                    return SignInButton(
                      width: size.width * 0.8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                      buttonType: ButtonType.google,
                      buttonSize: ButtonSize.medium,
                      onPressed: () async {
                        print("Sign in to Google Account");

                        try {
                          //login as a different user
                          User user = await auth.login();
                          onLogin(context, AlarmsList.route, user);
                        } catch (e) {
                          e.toString();
                        }
                      },
                    );
                  }

                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  );
                }
              )
            ],
          ),
        ),
      ),
    );
  }

  //go to activity after logging in
  void onLogin(BuildContext context, String routeName, User user) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: ScreenArguments(
        user: user,
      )
    );
  }
}