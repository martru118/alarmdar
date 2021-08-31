import 'package:alarmdar/model/alarm_preview.dart';
import 'package:alarmdar/model/form_alarm.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'alarm_info.dart';
import '../util/firebase_utils.dart';

class AlarmsList extends StatefulWidget {
  static const String route = '/';

  final String title;
  AlarmsList({Key key, @required this.title}): super(key: key);

  @override
  AlarmsPage createState() => AlarmsPage();
}

class AlarmsPage extends State<AlarmsList> {
  final db = new AlarmModel();
  static const double pad = 14;

  String selected;
  int notifID;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: buildList(),
        floatingActionButton: FloatingActionButton(
          tooltip: "New Alarm",
          child: const Icon(Icons.add),
          onPressed: () => startForm(context, "Set Alarm"),
        )
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
            leading: Text("${startTime.toString()}"),
            title: Text("${alarmInfo.name}", textScaleFactor: 1.5,
              style: TextStyle(fontWeight: FontWeight.bold),
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
                      TextSpan(text: "${startDate.toString()}\n\n",
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
                Switch(value: alarmInfo.shouldNotify, onChanged: null),
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
      onDismissed: (direction) {
        //delete current alarm
        selected = alarmInfo.reference.id;
        notifID = alarmInfo.createdAt;

        if (selected != null) {
          print("Delete alarm $selected");

          db.deleteData(selected);
          NotificationService().cancel(notifID);
          selected = null;
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Alarm has been deleted"),
        ));
      },
    );
  }

  void getPreview(BuildContext context, AlarmInfo alarmInfo) async {
    print("AlarmsList/getPreview::alarmInfo = ${alarmInfo.toJson()}");

    //push route to alarm preview
    await Navigator.of(context).pushNamed(AlarmPreview.route, arguments: ScreenArguments(
      alarmInfo: alarmInfo,
      isRinging: false,
    ));

    selected = null;
  }

  void startForm(BuildContext context, String title, [AlarmInfo alarmInfo]) async {
    print("AlarmsList/startForm");

    //push route to alarm form
    await Navigator.of(context).pushNamed(AlarmForm.route, arguments: ScreenArguments(
      alarmInfo: alarmInfo,
      title: title,
    ));

    selected = null;
  }
}