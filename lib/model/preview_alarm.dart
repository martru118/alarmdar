import 'package:alarmdar/util/date_utils.dart';
import 'package:alarmdar/util/gestures.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'alarm_info.dart';

class AlarmDetails extends StatefulWidget {
  static const String route = "/details";
  final AlarmInfo alarmInfo;
  final bool isRinging;

  AlarmDetails({Key key,
    @required this.alarmInfo,
    @required this.isRinging,
  }): super(key: key) {
    if (!isRinging) assert(alarmInfo.reference != null);
  }

  @override
  State<StatefulWidget> createState() => isRinging? _RingingState() : _PreviewState();
}

class _PreviewState extends State<AlarmDetails> {
  var gestures = GesturesProvider();

  @override
  void initState() {
    //initialize provider
    super.initState();
    gestures = Provider.of<GesturesProvider>(context, listen: false);
    gestures.setAlarm = widget.alarmInfo;
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

        return Scaffold(
          appBar: AppBar(title: Text("Alarm Details")),
          body: _PreviewBody(alarmInfo: alarmInfo),
          bottomNavigationBar: buildBottomBar(context, alarmInfo),
          floatingActionButton: buildFab(context, alarmInfo),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }
  
  Widget buildBottomBar(BuildContext context, AlarmInfo alarm) {
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
              gestures.remove(alarm.hashcode);
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }

  Widget buildFab(BuildContext context, AlarmInfo alarm) {
    if (alarm.shouldNotify) {
      //turn alarm off
      return FloatingActionButton.extended(
        label: Text("Turn OFF"),
        icon: const Icon(CupertinoIcons.bell_slash_fill),
        onPressed: () {
          gestures.archive(alarm);
          Navigator.pop(context);
        }
      );
    } else {
      //turn alarm on
      return FloatingActionButton.extended(
        label: Text("Turn ON"),
        icon: const Icon(CupertinoIcons.bell_fill),
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

class _RingingState extends State<AlarmDetails> {
  final gestures = GesturesProvider();
  final helper = DateTimeHelper();
  final int snoozeLen = 10;

  @override
  Widget build(BuildContext context) {
    final alarmInfo = widget.alarmInfo;

    return WillPopScope(
      onWillPop: () async => !widget.isRinging,
      child: Scaffold(
        appBar: buildAppBar(context, alarmInfo),
        body: _PreviewBody(alarmInfo: alarmInfo),
        bottomNavigationBar: buildBottomBar(context, alarmInfo),
      ),
    );
  }

  Widget buildAppBar(BuildContext context, AlarmInfo alarm) {
    return AppBar(
      leading: BackButton(
        onPressed: () {
          //snooze on exit
          nextNotification(0, alarm);
          Navigator.pop(context);
        }
      ),
      title: Text("${alarm.name}",
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }

  Widget buildBottomBar(BuildContext context, AlarmInfo alarm) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      backgroundColor: Theme.of(context).primaryColor,
      items: [
        BottomNavigationBarItem(
          label: "Snooze\n$snoozeLen mins.",
          icon: Icon(Icons.snooze),
        ),
        BottomNavigationBarItem(
          label: "Dismiss",
          icon: Icon(Icons.close),
        ),
      ],
      onTap: (index) {
        //notification actions
        nextNotification(index, alarm);
        Navigator.pop(context);
      },
    );
  }

  //schedule next notification, if possible
  void nextNotification(int action, AlarmInfo alarm) {
    final notifications = NotificationService();
    notifications.cancel(alarm.hashcode);

    switch (action) {
      case 0:
        //snooze alarm
        gestures.toast("Alarm will ring in $snoozeLen minutes");
        DateTime snooze = new DateTime.now().add(new Duration(minutes: snoozeLen));
        notifications.schedule(alarm, snooze.millisecondsSinceEpoch);
        break;

      case 1:
        //dismiss alarm
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

class _PreviewBody extends StatelessWidget {
  final helper = DateTimeHelper();
  static const int pad = 14;

  final AlarmInfo alarmInfo;
  _PreviewBody({Key key, this.alarmInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }
}