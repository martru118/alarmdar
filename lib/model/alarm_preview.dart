import 'package:alarmdar/util/firebase_utils.dart';
import 'package:flutter/material.dart';

import 'alarm_info.dart';
import 'form_alarm.dart';

class AlarmPreview extends StatefulWidget {
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
  static const double pad = 14;

  //initialize ui
  AlarmInfo alarm;
  bool ringing;
  String current;

  @override
  void initState() {
    super.initState();
    alarm = widget.alarmInfo;
    ringing = widget.isRinging;

    //get alarm id
    current = alarm.reference.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    title: Text("${alarm.date} at ${alarm.startTime}"),
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
      floatingActionButton: Visibility(visible: !ringing, child: buildFab(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
    //show alarm actions when ringing
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
        ]
      );

    //show
    } else {
      return BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: null,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  //reload the page
                  reload(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Checking for updates..."),
                  ));
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
                  db.deleteData(current);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Alarm has been deleted"),
                  ));

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget buildFab(BuildContext context) {
    //archive if alarm can ring
    if (alarm.shouldNotify) {
      return FloatingActionButton.extended(
        label: Text("Archive"),
        icon: const Icon(Icons.archive),
        onPressed: () {
          alarm.shouldNotify = false;
          db.updateData(alarm, current);
          Navigator.pop(context);
        }
      );

    //restore if alarm does not ring
    } else {
      return FloatingActionButton.extended(
        label: Text("Restore"),
        icon: const Icon(Icons.restore),
        onPressed: () {
          alarm.shouldNotify = true;
          db.updateData(alarm, current);
          Navigator.pop(context);
        }
      );
    }
  }

  //get updated alarm from database
  void reload(BuildContext context) async {
    print("Reload the page");

    AlarmInfo updated = await db.retrievebyID(current);
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => new AlarmPreview(alarmInfo: updated, isRinging: ringing),
    ));
  }

  void startForm(BuildContext context, AlarmInfo alarmInfo) async {
    print("Filling out the form");
    await Navigator.of(context).push(new MaterialPageRoute(
      builder: (context) => new AlarmForm(alarmInfo: alarmInfo, title: "Edit Alarm"),
    ));

    //update alarm information
    reload(context);
  }
}