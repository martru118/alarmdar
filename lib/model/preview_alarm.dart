import 'package:alarmdar/util/date_utils.dart';
import 'package:alarmdar/util/firestore_utils.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'alarm_info.dart';
import 'form_alarm.dart';
import 'list_alarms.dart';

class AlarmPreview extends StatefulWidget {
  static const String route = "/preview";
  final AlarmInfo alarmInfo;
  final bool isRinging;

  AlarmPreview({Key key,
    @required this.alarmInfo,
    @required this.isRinging,
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => _PreviewState();
}

class _PreviewState extends State<AlarmPreview> {
  final db = new AlarmModel();
  final helper = new DateTimeHelper();
  final notifications = NotificationService();
  static const double pad = 14;

  //initialize ui
  AlarmInfo alarm;
  bool ringing;
  int selected;

  @override
  void initState() {
    super.initState();
    alarm = widget.alarmInfo;
    ringing = widget.isRinging;
    selected = widget.alarmInfo.hashcode;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: buildAppBar(context, ringing),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(pad/2),
          child: Column(
            children: [
              //alarm name and description
              Card(
                elevation: pad/2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: SelectableText("${alarm.name}", textScaleFactor: 1.5,
                      style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: SelectableText("${alarm.description}", textScaleFactor: 1.5),
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
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: SelectableText("${alarm.start}"),
                      ),

                      //alarm recurrences
                      ListTile(
                        leading: const Icon(Icons.repeat),
                        title: SelectableText("${helper.recurrences[alarm.option]}"),
                      ),

                      //location details
                      ListTile(
                        leading: const Icon(Icons.location_pin),
                        title: SelectableText(alarm.location.isEmpty?
                            "Location not specified" : "${alarm.location}"
                        ),
                      ),
                    ]
                  ),
                ),
              ),
            ]
          )
        ),

        bottomNavigationBar: buildBottomBar(context, ringing),
        floatingActionButton: buildFab(context, ringing),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget buildAppBar(BuildContext context, bool isRinging) {
    //change app bar when alarm rings
    if (isRinging) return AppBar(title: Text("Alarmdar"), centerTitle: true);
    else return AppBar(leading: BackButton(), title: Text("Alarm Details"));
  }
  
  Widget buildBottomBar(BuildContext context, bool isRinging) {
    //show ringer actions when alarm rings
    if (isRinging) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Theme.of(context).colorScheme.secondary,
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
          notifications.cancel(selected);

          switch (index) {
            //snooze alarm
            case 0:
              print("Alarm has been put on snooze");
              DateTime snooze = new DateTime.now().add(new Duration(minutes: 5));
              notifications.schedule(alarm, snooze.millisecondsSinceEpoch);
              break;

            //dismiss alarm
            case 1:
              print("Alarm has been dismissed");
              DateTime current = DateFormat.yMMMEd().add_jm().parse(alarm.start);
              DateTime next = helper.nextAlarm(current, alarm.option);

              if (next == null) {
                //turn off alarm if it does not repeat
                alarm.shouldNotify = false;
                db.storeData(alarm);
              } else {
                int newStamp = helper.getTimeStamp(next);

                //schedule next alarm
                alarm.start = DateFormat.yMMMEd().add_jm().format(next);
                alarm.timestamp = newStamp;
                db.storeData(alarm);
                notifications.schedule(alarm, newStamp);
              }

              break;
          }

          //go back to homepage
          Navigator.of(context).pushReplacementNamed(AlarmsList.route);
        }
      );

    //show edit actions by default
    } else {
      return BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: null,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(children: [

            //copy button
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy),
              onPressed: () {
                //copy alarm info to clipboard
                Clipboard.setData(ClipboardData(
                  text: "${alarm.name}\n${alarm.start}\n\n${alarm.description}"
                ));

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Copied to clipboard"),
                ));
              },
            ), Spacer(),

            //edit button
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () => startForm(context, alarm),
            ),

            //delete button
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: () {
                //delete current alarm
                db.deleteData(selected.toString());
                notifications.cancel(selected);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Alarm has been deleted"),
                ));
              },
            ),
          ]),
        ),
      );
    }
  }

  Widget buildFab(BuildContext context, bool isRinging) {
    if (!isRinging) {
      //turn off alarm
      if (alarm.shouldNotify) {
        return FloatingActionButton.extended(
          label: Text("Turn OFF"),
          icon: const Icon(CupertinoIcons.bell_slash_fill),
          onPressed: () {
            alarm.shouldNotify = false;
            db.storeData(alarm);

            //cancel notification
            notifications.cancel(selected);
            Navigator.pop(context);
          }
        );

      //turn on alarm
      } else {
        return FloatingActionButton.extended(
          label: Text("Turn ON"),
          icon: const Icon(CupertinoIcons.bell_fill),
          onPressed: () {
            int currentTime = DateTime.now().millisecondsSinceEpoch;

            //alarm is in the future
            if (alarm.timestamp > currentTime) {
              alarm.shouldNotify = true;
              db.storeData(alarm);

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
    } else {
      return null;
    }
  }

  void startForm(BuildContext context, AlarmInfo alarmInfo) async {
    print("Edit alarm with info ${alarmInfo.toJson()}");

    //listen for updates
    final listener = await Navigator.of(context).pushNamed(AlarmForm.route, arguments: ScreenArguments(
      alarmInfo: alarmInfo,
      title: "Edit Alarm",
    ));

    //update alarm details
    if (listener != null) {
      print("Listening for updates: $listener");
      setState(() => alarm = listener as AlarmInfo);
    }
  }
}