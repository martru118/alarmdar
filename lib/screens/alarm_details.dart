import 'package:alarmdar/util/datetime_utils.dart';
import 'package:alarmdar/model/gestures.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/alarm_info.dart';

class AlarmDetails extends StatefulWidget {
  static const String route = "/details";
  final AlarmInfo alarmInfo;
  final bool isRinging;

  AlarmDetails(this.alarmInfo, this.isRinging, {
    Key key,
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
      key: widget.key,
      builder: (context, provider, child) {
        final alarmInfo = provider.getAlarm;

        return Scaffold(
          appBar: AppBar(title: Text("Alarm Details")),
          body: _DetailsBody(alarmInfo: alarmInfo, key: widget.key),
          bottomNavigationBar: buildBottomBar(context, alarmInfo),
          floatingActionButton: buildFab(context, alarmInfo),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }
  
  Widget buildBottomBar(BuildContext context, AlarmInfo alarm) {
    //change colors depending on system dark mode
    Color background = Theme.of(context).primaryColor;
    var brightness = MediaQuery.of(context).platformBrightness;
    if (brightness == Brightness.dark) background = Theme.of(context).appBarTheme.backgroundColor;

    return BottomAppBar(
      shape: null,
      color: background,
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Row(children: [

          //copy button
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () {
              //copy alarm info to clipboard
              gestures.snackbar(context, "Copied to clipboard");

              String toCopy = "${alarm.name}\n${alarm.start}\n\n${alarm.description}";
              if (alarm.location.isNotEmpty) toCopy += "\n\nLocated at: ${alarm.location}";
              Clipboard.setData(ClipboardData(text: "$toCopy"));
            },
          ), Spacer(),

          //edit button
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Provider.of<GesturesProvider>(context, listen: false).setEdit(context, 1, alarm),
          ),

          //delete button
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              gestures.delete(alarm.hashcode);
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

class _RingingState extends State<AlarmDetails> with WidgetsBindingObserver {
  final gestures = GesturesProvider();
  final helper = DateTimeHelper();
  static const int snoozeLen = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    gestures.setAlarm = widget.alarmInfo;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    gestures.setAlarm = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    //listen to activity lifecycle
    if (state == AppLifecycleState.paused) {
      print("Handle app exit");
      nextNotification(0, gestures.getAlarm);
    } else {
      debugPrint("Alarm is in state: $state");
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarmInfo = gestures.getAlarm;

    //prevent activity dismissal
    return WillPopScope(key: widget.key,
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(title: Text("Alarm Details")),
        body: _DetailsBody(alarmInfo: alarmInfo, key: widget.key),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
          items: [
            //snooze alarm
            BottomNavigationBarItem(
              label: "Snooze\n$snoozeLen min.",
              icon: Icon(Icons.snooze),
            ),

            //dismiss alarm
            BottomNavigationBarItem(
              label: "Dismiss",
              icon: Icon(Icons.close),
            ),
          ],

          //notification actions
          onTap: (index) => nextNotification(index, alarmInfo),
        ),
      ),
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

    //exit screen
    Navigator.pop(context);
  }
}

class _DetailsBody extends StatelessWidget {
  final helper = DateTimeHelper();
  static const int pad = 14;

  final AlarmInfo alarmInfo;
  _DetailsBody({Key key, this.alarmInfo}) : super(key: key);

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
              title: SelectableText("${alarmInfo.name}",
                textScaleFactor: pad/6,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: SelectableText("${alarmInfo.description}",
                textScaleFactor: pad/8,
                textAlign: TextAlign.start,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
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
                    title: Text("${alarmInfo.start}"),
                  ),

                  //alarm recurrences
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: Text("${helper.recurrences[alarmInfo.option]}"),
                  ),

                  //location details
                  ListTile(
                    leading: const Icon(Icons.location_pin),
                    title: Text(alarmInfo.location.isEmpty?
                        "Location not specified" : "${alarmInfo.location}"
                  )),
                ]
              ),
            ),
          ),
        ]
      ),
    );
  }
}