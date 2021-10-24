import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/screens/alarm_details.dart';
import 'package:alarmdar/model/gestures.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AlarmsList extends StatefulWidget {
  static const String route = "/";
  AlarmsList({Key key}): super(key: key);

  @override
  _ListState createState() => _ListState();
}

class _ListState extends State<AlarmsList> {
  final gestures = GesturesProvider();
  static const double pad = 14;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Alarms")),
      body: buildList(context),
      floatingActionButton: FloatingActionButton(
        tooltip: "New Alarm",
        child: const Icon(Icons.add),
        onPressed: () => gestures.setEdit(context, 0),
      )
    );
  }

  Widget buildList(BuildContext context) {
    return Consumer<Stream<List>>(
      builder: (context, provider, child) {
        return StreamBuilder<List>(
          initialData: [],
          stream: provider,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("${snapshot.error.toString()}");
            } else {
              var alarmsList = snapshot.data.cast<AlarmInfo>();

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: pad/2),
                itemCount: alarmsList.length,
                itemBuilder: (context, index) {
                  final dao = alarmsList[index];
                  return buildAlarm(context, dao);
                },
              );
            }
          },
        );
      },
    );
  }

  Widget buildAlarm(BuildContext context, AlarmInfo alarm) {
    //initialize date and time strings
    DateTime alarmDateTime = DateFormat.yMMMEd().add_jm().parse(alarm.start);
    String startTime = DateFormat.jm().format(alarmDateTime).replaceAll(' ', '\n');
    String startDate = DateFormat.MMMEd().format(alarmDateTime);

    return Dismissible(key: ValueKey(alarm.reference.key),
      background: Container(color: Colors.red),
      child: Card(
        elevation: pad/2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
        child: ListTile(
          //alarm name and times
          leading: Text("$startTime", textAlign: TextAlign.end),
          title: Text("${alarm.name}", textScaleFactor: 1.5,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("\n\u23F0\t$startDate"),

          //alarm switch
          trailing: CupertinoSwitch(
            activeColor: Colors.amber,
            value: alarm.shouldNotify,
            onChanged: null,
          ),

          //go to alarm preview
          onTap: () async => Navigator.of(context).pushNamed(
            AlarmDetails.route,
            arguments: ScreenArguments(
              alarmInfo: alarm,
              isRinging: await NotificationService().isActive(alarm.hashcode),
          )),
          onLongPress: () {
            //shortcut for editing selected alarms
            HapticFeedback.selectionClick();
            gestures.setEdit(context, 1, alarm);
          },
        ),
      ),

      //swipe to delete alarm
      onDismissed: (direction) => gestures.delete(alarm.hashcode),
    );
  }
}