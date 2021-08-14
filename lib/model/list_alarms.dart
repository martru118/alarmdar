import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: buildList(),
      floatingActionButton: new FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
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
                  Icon(CupertinoIcons.bell_fill),
                  SizedBox(width: pad/4),
                  Text("${alarmInfo.date}"),
                ]), SizedBox(height: pad/2),

                //location details
                Row(children: [
                  Icon(CupertinoIcons.map_pin),
                  SizedBox(width: pad/4),
                  Expanded(child: Text(alarmInfo.location.isEmpty? "Location not specified" : "${alarmInfo.location}")),
                ]), SizedBox(height: pad/2),
              ]
            ),

            trailing: Column(
              children: [
                Switch(
                  value: alarmInfo.shouldNotify,
                  onChanged: (value) {
                    print("Toggle alarm");
                    setState(() => alarmInfo.shouldNotify = value);
                  }
                ),
              ],
            ),
          ),

          onTap: () {
            selected = alarmInfo.reference.id;
            print("Edit alarm ${alarmInfo.toJson()}");

            //edit selected alarm
            startForm(context, alarmInfo, selected);
          },
        ),
      ),
      onDismissed: (direction) {
        selected = alarmInfo.reference.id;
        print("Delete alarm ${alarmInfo.toJson()}");

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