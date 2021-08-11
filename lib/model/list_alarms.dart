import 'package:cloud_firestore/cloud_firestore.dart';
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
  String _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: buildList(),
      floatingActionButton: new FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            print("Add alarm");
            _startForm(context);
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
            children: snapshot.data.docs.map((DocumentSnapshot snapshot) => buildAlarm(context, snapshot)).toList(),
          );
        }
      },
    );
  }

  Widget buildAlarm(BuildContext context, DocumentSnapshot documentData) {
    final alarmInfo = AlarmInfo.fromMap(documentData.data(), reference: documentData.reference);

    return Card(
      elevation: 3.0,
      child: ListTile(
        title: Text("${alarmInfo.name}\n${alarmInfo.startTime}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_buildSubtitle(alarmInfo)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            //edit button
            IconButton(icon: const Icon(Icons.edit),
              padding: EdgeInsets.only(right: 16.0),
              constraints: BoxConstraints(),
              tooltip: "Edit Alarm",
              onPressed: () {
                _selected = alarmInfo.reference.id;
                print("Edit alarm: $_selected");

                //edit selected grade
                _startForm(context, db.retrievebyID(_selected), _selected);
              }
            ),

            //delete button
            IconButton(icon: const Icon(Icons.delete),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              tooltip: "Delete Alarm",
              onPressed: () {
                _selected = alarmInfo.reference.id;
                print("Delete alarm: $_selected");

                //delete selected grade
                if (_selected != null) {
                  db.deleteData(_selected);
                  _selected = null;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  //build subtitle for alarm
  String _buildSubtitle(AlarmInfo alarm) {
    String subtitle = "${alarm.description}";

    //add location to subtitle
    if (alarm.location.isNotEmpty) subtitle += "\n\uD83D\uDCCD\t${alarm.location}";
    return subtitle;
  }

  void _startForm(BuildContext context, [AlarmInfo alarmInfo, String _id=""]) async {
    await Navigator.of(context).push(new MaterialPageRoute(
      builder: (BuildContext context) => new AlarmForm(alarmInfo: alarmInfo, refID: _id),
    ));

    _selected = null;
  }
}