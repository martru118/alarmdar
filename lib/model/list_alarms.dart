import 'package:alarmdar/auth/authenticator.dart';
import 'package:alarmdar/auth/splash.dart';
import 'package:alarmdar/model/preview_alarm.dart';
import 'package:alarmdar/model/form_alarm.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'alarm_info.dart';
import '../util/firebase_utils.dart';

class AlarmsList extends StatefulWidget {
  static const String route = "/list";

  final User user;
  AlarmsList({Key key, @required this.user}): super(key: key);

  @override
  AlarmsPage createState() => AlarmsPage();
}

class AlarmsPage extends State<AlarmsList> {
  final db = new AlarmModel();
  final auth = new Authenticator();
  final notifications = NotificationService();
  static const double pad = 14;

  int selected;
  User currentUser;

  @override
  void initState() {
    super.initState();
    notifications.init();
    currentUser = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Your Alarms")),
        drawer: buildDrawer(context),
        body: buildList(),
        floatingActionButton: FloatingActionButton(
          tooltip: "New Alarm",
          child: const Icon(Icons.add),
          onPressed: () => startForm(context, "Set Alarm"),
        )
      ),
    );
  }

  Widget buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.retrieveAll(currentUser.email),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        } else {
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: pad/2),
            children: snapshot.data.docs.map((DocumentSnapshot snapshot) =>
                buildAlarm(context, snapshot)).toList(),
          );
        }
      },
    );
  }

  Widget buildAlarm(BuildContext context, DocumentSnapshot documentData) {
    final alarmInfo = AlarmInfo.fromMap(documentData.data(), reference: documentData.reference);

    //initialize date and time strings
    DateTime alarmDateTime = DateFormat.yMMMEd().add_jm().parse(alarmInfo.start);
    String startTime = DateFormat.jm().format(alarmDateTime).replaceAll(' ', '\n');
    String startDate = DateFormat.MMMEd().format(alarmDateTime);

    return Dismissible(
      key: UniqueKey(),
      background: Container(color: Colors.red),
      child: Card(
        elevation: pad/2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
        child: ListTile(
          leading: Text("$startTime"),
          title: Text("${alarmInfo.name}", textScaleFactor: 1.5,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(child: RichText(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(text: "\u23F0\t",
                  style: TextStyle(
                    color: MediaQuery.of(context).platformBrightness == Brightness.light?
                        Colors.grey[700] : Colors.white,
                  ),
                  children: [
                    //alarm date
                    TextSpan(text: "$startDate\n\n",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    //description
                    TextSpan(text: "${alarmInfo.description}",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ]
                ),
              )),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Switch(value: alarmInfo.shouldNotify, onChanged: null),
            ],
          ),

          //item gestures
          onTap: () => getPreview(context, alarmInfo),
          onLongPress: () {
            //shortcut for editing selected alarms
            HapticFeedback.selectionClick();
            startForm(context, "Edit Alarm", alarmInfo);
          },
        ),
      ),
      onDismissed: (direction) {
        //delete current alarm
        selected = alarmInfo.hashcode;

        if (selected != null) {
          print("Delete alarm $selected");

          db.deleteData(selected.toString());
          notifications.cancel(selected);
          selected = null;
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Alarm has been deleted"),
        ));
      },
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          //user account header
          UserAccountsDrawerHeader(
            accountName: Text("${currentUser.displayName}"),
            accountEmail: Text("${currentUser.email}"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(currentUser.photoURL),
              radius: 45,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),

          //account options
          ListTile(
            leading: const Icon(Icons.event),
            title: Text("Open in Google Calendar"),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app_outlined),
            title: Text("Sign Out"),
            onTap: () async {
              //sign out of app
              await auth.logout();
              notifications.cancelPendingRequests();

              Navigator.pushNamedAndRemoveUntil(
                context,
                SplashScreen.route,
                (route) => false,
              );
            },
          ),
        ]
      ),
    );
  }

  void getPreview(BuildContext context, AlarmInfo alarmInfo) async {
    print("AlarmsList/getPreview::alarmInfo = ${alarmInfo.toJson()}");

    //push route to alarm preview
    await Navigator.of(context).pushNamed(AlarmPreview.route, arguments: ScreenArguments(
      alarmInfo: alarmInfo,
      isRinging: false,
    ));

    selected = null;
  }

  void startForm(BuildContext context, String title, [AlarmInfo alarmInfo]) async {
    print("AlarmsList/startForm");

    //push route to alarm form
    await Navigator.of(context).pushNamed(AlarmForm.route, arguments: ScreenArguments(
      alarmInfo: alarmInfo,
      title: title,
      accountName: currentUser.email
    ));

    selected = null;
  }
}