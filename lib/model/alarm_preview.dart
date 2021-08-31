import 'package:alarmdar/model/form_alarm.dart';
import 'package:alarmdar/util/date_utils.dart';
import 'package:alarmdar/util/firebase_utils.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'alarm_info.dart';

class AlarmPreview extends StatefulWidget {
  static const String route = "/preview";
  final AlarmInfo alarmInfo;
  final bool isRinging;

  AlarmPreview({Key key,
    @required this.alarmInfo,
    @required this.isRinging,
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => PreviewsPage();
}

class PreviewsPage extends State<AlarmPreview> {
  final db = new AlarmModel();
  final helper = new DateTimeHelper();
  final notifications = NotificationService();
  static const double pad = 14;

  //initialize ui
  AlarmInfo alarm;
  bool ringing;
  String selected;
  int notifID;

  @override
  void initState() {
    super.initState();
    alarm = widget.alarmInfo;
    ringing = widget.isRinging;

    //get alarm and notification id
    selected = alarm.reference.id;
    notifID = alarm.createdAt;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: buildAppBar(context, ringing),
        body: ListView(
          padding: EdgeInsets.all(pad/2),
          children: [
            //alarm name and description
            Card(
              elevation: pad/2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text("${alarm.name}", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${alarm.description}"),
              ),
            ),

            Card(
              elevation: pad/2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
              child: Container(
                padding: EdgeInsets.all(pad/2),
                child: Column(
                  children: [
                    //alarm date and time
                    ListTile(leading: const Icon(Icons.access_time),
                      title: Text("${alarm.start}"),
                    ),

                    //location details
                    ListTile(leading: const Icon(Icons.location_pin),
                      title: Text(alarm.location.isEmpty?
                          "Location not specified" : "${alarm.location}"
                      ),
                    ),

                    //account details
                    ListTile(leading: const Icon(Icons.person_rounded),
                      title: Text("Account details"),
                    ),
                  ]
                ),
              ),
            ),
          ]
        ),

        bottomNavigationBar: buildBottomBar(context, ringing),
        floatingActionButton: buildFab(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget buildAppBar(BuildContext context, bool isRinging) {
    //change app bar when alarm rings
    if (isRinging)
      return AppBar(title: Text("Alarmdar"), centerTitle: true);
    else
      return AppBar(leading: BackButton(), title: Text("Alarm Details"));
  }
  
  Widget buildBottomBar(BuildContext context, bool isRinging) {
    //show ringer actions when alarm rings
    if (isRinging) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Theme.of(context).accentColor,
        items: [
          BottomNavigationBarItem(
            label: "Snooze\n(5 mins)",
            icon: Icon(Icons.snooze),
          ),
          BottomNavigationBarItem(
            label: "Dismiss",
            icon: Icon(Icons.close),
          ),
        ],
        onTap: (index) {
          switch (index) {
            //snooze alarm
            case 0:
              //schedule new notification for 5 minutes later
              DateTime snooze = new DateTime.now().add(new Duration(minutes: 5));
              notifications.schedule(alarm, snooze.millisecondsSinceEpoch);
              break;

            //dismiss alarm
            case 1:
              DateTime next = helper.nextAlarm(alarm.option);

              if (next == null) {
                //turn off alarm if it does not repeat
                alarm.shouldNotify = false;
                db.updateData(alarm, selected);
                notifications.cancel(notifID);
              } else {
                int newStamp = helper.getTimeStamp(next);

                //schedule next alarm
                alarm.start = DateFormat.yMMMEd().add_jm().format(next);
                alarm.timestamp = newStamp;
                db.updateData(alarm, selected);
                notifications.schedule(alarm, newStamp);
              }

              break;
          }

          //close preview
          Navigator.of(context).pop();
        }
      );

    //show edit actions when not ringing
    } else {
      return BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: null,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(children: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Checking for updates..."),
                ));

                //reload the page
                reload(context);
              },
            ), Spacer(),

            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () => startForm(context, alarm),
            ),

            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: () {
                //delete current alarm
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Alarm has been deleted"),
                ));

                db.deleteData(selected);
                notifications.cancel(notifID);
                Navigator.pop(context);
              },
            ),
          ]),
        ),
      );
    }
  }

  Widget buildFab(BuildContext context) {
    //archive if alarm can ring
    if (alarm.shouldNotify) {
      return FloatingActionButton.extended(
        label: Text("Turn OFF"),
        icon: const Icon(CupertinoIcons.bell_slash_fill),
        onPressed: () {
          //turn off alarm
          alarm.shouldNotify = false;
          db.updateData(alarm, selected);

          //cancel notification
          notifications.cancel(notifID);
          Navigator.pop(context);
        }
      );

    //restore if alarm cannot ring
    } else {
      return FloatingActionButton.extended(
        label: Text("Turn ON"),
        icon: const Icon(CupertinoIcons.bell_fill),
        onPressed: () {
          int currentTime = DateTime.now().millisecondsSinceEpoch;

          //alarm is in the future
          if (alarm.timestamp > currentTime) {
            alarm.shouldNotify = true;
            db.updateData(alarm, selected);

            //schedule alarm
            notifications.schedule(alarm, alarm.timestamp);
            Navigator.pop(context);

          //alarm is in the past
          } else {
            startForm(context, alarm);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Please choose a time in the future"),
            ));
          }
        }
      );
    }
  }

  //get updated alarm from database
  void reload(BuildContext context) async {
    print("AlarmPreview/reload");

    AlarmInfo updated = await db.retrievebyID(selected);
    Navigator.pushReplacementNamed(context, AlarmPreview.route, arguments: ScreenArguments(
      alarmInfo: updated,
      isRinging: ringing,
    ));
  }

  void startForm(BuildContext context, AlarmInfo alarmInfo) async {
    print("AlarmPreview/startForm::alarmInfo = ${alarmInfo.toJson()}");
    
    await Navigator.of(context).pushNamed(AlarmForm.route, arguments: ScreenArguments(
      alarmInfo: alarmInfo,
      title: "Edit Alarm",
    ));

    //update alarm information
    reload(context);
  }
}