import 'package:alarmdar/model/alarm_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'alarm_info.dart';
import 'firebase_utils.dart';
import 'form_alarm.dart';


class AlarmsList extends StatefulWidget {
  AlarmsList({Key key, this.title}): super(key: key);
  final String title;

  @override
  AlarmsPage createState() => AlarmsPage();
}

class AlarmsPage extends State<AlarmsList> {
  final db = new AlarmModel();
  static const double pad = 14;
  String selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title),
        actions: [
          IconButton(icon: Icon(Icons.account_circle),
            tooltip: "Account Settings",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Login to Google Calendar"),
              ));
            },
          )
        ],
      ),
      body: buildList(),
      floatingActionButton: new FloatingActionButton(
        tooltip: "New Alarm",
        child: const Icon(Icons.add),
        onPressed: () => startForm(context, "Set Alarm"),
      ),
    );
  }

  Widget buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.retrieveAll(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
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

    return Dismissible(
      key: UniqueKey(),
      background: Container(color: Colors.red),
      child: Card(
        elevation: pad/2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
        child: InkWell(
          child: ListTile(
            leading: Text("${alarmInfo.startTime.replaceFirst(RegExp(' '), '\n')}"),
            title: Text("${alarmInfo.name}", textScaleFactor: 1.5,
              style: TextStyle(fontWeight: FontWeight.bold)
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
                      TextSpan(text: "${alarmInfo.date}\n\n",
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
              children: [
                Switch(
                  value: alarmInfo.shouldNotify,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    selected = alarmInfo.reference.id;

                    //toggle alarm switch on/off
                    setState(() {
                      print("Toggle ringer on/off");
                      alarmInfo.shouldNotify = value;
                      db.updateData(alarmInfo, selected);
                    });
                  }
                ),
              ],
            ),
          ),

          onTap: () => getPreview(context, alarmInfo),
          onLongPress: () {
            //shortcut for editing selected alarms
            HapticFeedback.selectionClick();
            startForm(context, "Edit alarm", alarmInfo);
          },
        ),
      ),
      onDismissed: (direction) {
        selected = alarmInfo.reference.id;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Alarm has been deleted"),
        ));

        //delete selected alarm
        if (selected != null) {
          print("Delete alarm from database");
          db.deleteData(selected);
          selected = null;
        }
      },
    );
  }

  void startForm(BuildContext context, String title, [AlarmInfo alarmInfo]) async {
    print("Filling out the form");
    await Navigator.of(context).push(new MaterialPageRoute(
      builder: (context) => new AlarmForm(alarmInfo: alarmInfo, title: title),
    ));

    selected = null;
  }

  void getPreview(BuildContext context, AlarmInfo alarmInfo) async {
    print("Showing alarm details");
    await Navigator.of(context).push(new MaterialPageRoute(
      builder: (context) => new AlarmPreview(alarmInfo: alarmInfo, isRinging: false),
    ));

    selected = null;
  }
}