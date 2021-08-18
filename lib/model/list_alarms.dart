import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
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
  static const double pad = 12;

  String selected;
  bool shouldRing = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title),
        actions: [
          IconButton(icon: Icon(CupertinoIcons.profile_circled),
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
        child: const Icon(Icons.add),
        onPressed: () {
          HapticFeedback.selectionClick();
          print("Add alarm");
          startForm(context);
        }
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
            children: snapshot.data.docs.map((DocumentSnapshot snapshot) => buildAlarm(context, snapshot)).toList(),
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
            title: Text("${alarmInfo.name}", style: TextStyle(fontWeight: FontWeight.bold)),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //description
                Text("${alarmInfo.description}"), SizedBox(height: pad/2),

                //alarm date
                Row(children: [
                  Icon(Icons.alarm), SizedBox(width: pad/3),
                  Expanded(child: Text("${alarmInfo.date}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                ]), SizedBox(height: pad/4),

                //location details
                Row(children: [
                  Icon(Icons.location_pin), SizedBox(width: pad/3),
                  Expanded(child: Text(
                    alarmInfo.location.isEmpty? "Location not specified" : "${alarmInfo.location}"
                  )),
                ]), SizedBox(height: pad/4),
              ]
            ),

            trailing: Column(
              children: [
                Switch(
                  value: alarmInfo.shouldNotify,
                  onChanged: (value) {
                    selected = alarmInfo.reference.id;
                    HapticFeedback.selectionClick();

                    //toggle alarm switch on/off
                    setState(() {
                      alarmInfo.shouldNotify = value;
                      db.updateData(alarmInfo, selected);

                      print("Toggle alarm ${alarmInfo.toJson()}");
                    });
                  }
                ),
              ],
            ),
          ),

          onTap: () {
            selected = alarmInfo.reference.id;
            HapticFeedback.selectionClick();
            print("Edit alarm ${alarmInfo.toJson()}");

            //edit selected alarm
            startForm(context, alarmInfo, selected);
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
          db.deleteData(selected);
          selected = null;
        }
      },
    );
  }

  void startForm(BuildContext context, [AlarmInfo alarmInfo, String id=""]) async {
    await Navigator.of(context).push(new MaterialPageRoute(
      builder: (BuildContext context) => new AlarmForm(alarmInfo: alarmInfo, refID: id),
    ));

    selected = null;
  }
}