import 'package:alarmdar/model/alarm_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'alarm_info.dart';
import '../util/firebase_utils.dart';
import 'form_alarm.dart';


class AlarmsList extends StatefulWidget {
  final String title;
  final bool ongoing;

  AlarmsList({Key key,
    @required this.title,
    @required this.ongoing,
  }): super(key: key);

  @override
  AlarmsPage createState() => AlarmsPage();
}

class AlarmsPage extends State<AlarmsList> {
  final db = new AlarmModel();
  static const double pad = 14;
  String selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: buildAppBar(context, widget.ongoing),
        body: buildList(widget.ongoing),
        floatingActionButton: Visibility(
          visible: widget.ongoing,
          child: FloatingActionButton(
            tooltip: "New Alarm",
            child: const Icon(Icons.add),
            onPressed: () => startForm(context, "Set Alarm"),
          ),
        )
      ),
    );
  }

  Widget buildAppBar(BuildContext context, bool isOngoing) {
    //show ongoing alarms
    if (isOngoing) {
      return AppBar(title: Text(widget.title));

    //show archived alarms
    } else {
      return AppBar(title: Text(widget.title),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text("Restore All"),
                ),
                value: 1,
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text("Delete All"),
                ),
                value: 2,
              ),
            ],
            onSelected: null,
          ),
        ]
      );
    }
  }

  Widget buildList(bool isOngoing) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.retrieveAll(isOngoing),
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Switch(
                value: alarmInfo.shouldNotify,
                onChanged: (value) {
                  selected = alarmInfo.reference.id;
                  HapticFeedback.selectionClick();

                  //toggle alarm switch on/off
                  setState(() {
                    print("Toggle ringer on/off");

                    alarmInfo.shouldNotify = value;
                    db.updateData(alarmInfo, selected);
                    selected = null;
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
            startForm(context, "Edit Alarm", alarmInfo);
          },
        ),
      ),
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
      builder: (context) => new AlarmPreview(alarmInfo: alarmInfo, ringing: false),
    ));

    selected = null;
  }
}