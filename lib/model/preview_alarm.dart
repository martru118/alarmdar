import 'package:alarmdar/util/date_utils.dart';
import 'package:alarmdar/util/gestures.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  State<StatefulWidget> createState() => _PreviewState();
}

class _PreviewState extends State<AlarmPreview> {
  var gestures = GesturesProvider();
  final helper = DateTimeHelper();
  static const double pad = 14;

  //initialize ui
  bool ringing;
  int selected;

  @override
  void initState() {
    super.initState();
    gestures = Provider.of<GesturesProvider>(context, listen: false);
    gestures.setAlarm = widget.alarmInfo;

    ringing = widget.isRinging;
    selected = widget.alarmInfo.hashcode;
  }

  @override
  void dispose() {
    gestures.setAlarm = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GesturesProvider>(
      builder: (context, provider, child) {
        final alarmInfo = provider.getAlarm;

        //dynamic app layout
        return Scaffold(
          appBar: buildAppBar(context, alarmInfo, ringing),
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
                    title: SelectableText("${alarmInfo.name}", textScaleFactor: 1.5,
                        style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    subtitle: SelectableText("${alarmInfo.description}", textScaleFactor: 1.5),
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
                          title: SelectableText("${alarmInfo.start}"),
                        ),

                        //alarm recurrences
                        ListTile(
                          leading: const Icon(Icons.repeat),
                          title: SelectableText("${helper.recurrences[alarmInfo.option]}"),
                        ),

                        //location details
                        ListTile(
                          leading: const Icon(Icons.location_pin),
                          title: SelectableText(alarmInfo.location.isEmpty?
                              "Location not specified" : "${alarmInfo.location}"
                          ),
                        ),
                      ]
                    ),
                  ),
                ),
              ]
            ),
          ),

          bottomNavigationBar: buildBottomBar(context, alarmInfo, ringing),
          floatingActionButton: buildFab(context, alarmInfo, ringing),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget buildAppBar(BuildContext context, AlarmInfo alarm, bool isRinging) {
    //change app bar when alarm rings
    if (isRinging) {
      return AppBar(
        leading: BackButton(
          onPressed: () {
            nextNotification(0, alarm);
            Navigator.pop(context);
          }
        ),
        title: Text("Alarmdar"),
        centerTitle: true,
      );
    } else {
      return AppBar(title: Text("Alarm Details"));
    }
  }
  
  Widget buildBottomBar(BuildContext context, AlarmInfo alarm, bool isRinging) {
    //show ringer actions when alarm rings
    if (isRinging) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(
            label: "Snooze\n(10 mins)",
            icon: Icon(Icons.snooze),
          ),
          BottomNavigationBarItem(
            label: "Dismiss",
            icon: Icon(Icons.close),
          ),
        ],
        onTap: (index) {
          nextNotification(index, alarm);
          Navigator.pop(context);
        }
      );

    //show edit actions by default
    } else {
      return BottomAppBar(
        shape: null,
        color: Theme.of(context).primaryColor,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(children: [

            //copy button
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy),
              onPressed: () {
                //copy alarm info to clipboard
                gestures.snackbar(context, "Copied to clipboard");
                Clipboard.setData(ClipboardData(
                  text: "${alarm.name}\n${alarm.start}\n\n${alarm.description}"
                ));
              },
            ), Spacer(),

            //edit button
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () {
                Provider.of<GesturesProvider>(context, listen: false).setEdit(context, 1, alarm);
              }
            ),

            //delete button
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: () {
                gestures.snackbar(context, "Alarm has been removed");
                gestures.remove(selected);
                Navigator.pop(context);
              },
            ),
          ]),
        ),
      );
    }
  }

  Widget buildFab(BuildContext context, AlarmInfo alarm, bool isRinging) {
    if (isRinging) {
      return null;
    } else {
      //turn off alarm
      if (alarm.shouldNotify) {
        return FloatingActionButton.extended(
          label: Text("Turn OFF", style: TextStyle(color: Colors.white)),
          icon: const Icon(CupertinoIcons.bell_slash_fill, color: Colors.white),
          onPressed: () {
            gestures.archive(alarm);
            Navigator.pop(context);
          }
        );

      //turn on alarm
      } else {
        return FloatingActionButton.extended(
          label: Text("Turn ON", style: TextStyle(color: Colors.white)),
          icon: const Icon(CupertinoIcons.bell_fill, color: Colors.white),
          onPressed: () {
            int currentTime = DateTime.now().millisecondsSinceEpoch;

            if (alarm.timestamp > currentTime) {
              //alarm is in the future
              gestures.restore(alarm);
              Navigator.pop(context);
            } else {
              //alarm is in the past
              gestures.snackbar(context, "Please choose a time in the future");
              Provider.of<GesturesProvider>(context, listen: false).setEdit(context, 1, alarm);
            }
          }
        );
      }
    }
  }

  void nextNotification(int action, AlarmInfo alarm) {
    final notifications = NotificationService();
    notifications.cancel(alarm.hashcode);

    switch (action) {
      //snooze alarm
      case 0:
        gestures.toast("Alarm is snoozed for 10 minutes");
        DateTime snooze = new DateTime.now().add(new Duration(minutes: 10));
        notifications.schedule(alarm, snooze.millisecondsSinceEpoch);
        break;

      //dismiss alarm
      case 1:
        DateTime current = DateFormat.yMMMEd().add_jm().parse(alarm.start);
        DateTime next = helper.nextAlarm(current, alarm.option);

        if (next == null) {
          //turn off alarm if it does not repeat
          gestures.archive(alarm);
        } else {
          //schedule next alarm
          alarm.start = DateFormat.yMMMEd().add_jm().format(next);
          alarm.timestamp = helper.getTimeStamp(next);
          gestures.restore(alarm);
        }

        break;
    }
  }
}