import 'dart:async';

import 'package:alarmdar/screens/alarm_details.dart';
import 'package:alarmdar/model/gestures.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/alarm_info.dart';
import '../model/firestore_utils.dart';

class AlarmsList extends StatefulWidget {
  static const String route = "/";
  AlarmsList({Key key}): super(key: key);

  @override
  _ListState createState() => _ListState();
}

class _ListState extends State<AlarmsList> {
  final gestures = GesturesProvider();
  static const double pad = 14;
  Stream listStream;

  @override
  void initState() {
    super.initState();
    listStream = context.read<AlarmsRepository>().retrieveAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Alarms")),
      body: buildList(),
      floatingActionButton: FloatingActionButton(
        tooltip: "New Alarm",
        child: const Icon(Icons.add),
        onPressed: () => gestures.setEdit(context, 0),
      )
    );
  }

  Widget buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: listStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("${snapshot.error.toString()}");
        } else if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
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

    //initialize date and time strings
    DateTime alarmDateTime = DateFormat.yMMMEd().add_jm().parse(alarmInfo.start);
    String startTime = DateFormat.jm().format(alarmDateTime).replaceAll(' ', '\n');
    String startDate = DateFormat.MMMEd().format(alarmDateTime);

    return Dismissible(
      key: UniqueKey(),
      background: Container(color: Colors.red),
      child: Card(
        elevation: pad/2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
        child: ListTile(
          //alarm name and times
          leading: Text("$startTime", textAlign: TextAlign.end),
          title: Text("${alarmInfo.name}", textScaleFactor: 1.5,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("\n\u23F0\t$startDate"),

          //alarm switch
          trailing: Switch(value: alarmInfo.shouldNotify, onChanged: null),

          //go to alarm preview
          onTap: () async => Navigator.of(context).pushNamed(
            AlarmDetails.route,
            arguments: ScreenArguments(
              alarmInfo: alarmInfo,
              isRinging: await NotificationService().isActive(alarmInfo.hashcode),
          )),
          onLongPress: () {
            //shortcut for editing selected alarms
            HapticFeedback.selectionClick();
            gestures.setEdit(context, 1, alarmInfo);
          },
        ),
      ),

      //swipe to delete alarm
      onDismissed: (direction) => gestures.delete(alarmInfo.hashcode),
    );
  }
}