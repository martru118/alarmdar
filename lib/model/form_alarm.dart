import 'package:alarmdar/util/date_utils.dart';
import 'package:alarmdar/util/notifications_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:weekday_selector/weekday_selector.dart';

import 'alarm_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../util/firebase_utils.dart';


class AlarmForm extends StatefulWidget {
  final AlarmInfo alarmInfo;
  final String title;

  AlarmForm({Key key,
    @required this.alarmInfo,
    @required this.title,
  }): super(key: key);

  @override
  FormPage createState() => FormPage();
}

class FormPage extends State<AlarmForm> {
  final helper = DateTimeHelper();
  final formKey = new GlobalKey<FormState>();
  static const double pad = 12;

  //initialize ui
  String refID;
  int notifID;
  DateTime startTime, startDate;
  String timeString, dateString;
  int timestamp;
  List<bool> daysList;
  var alarmName, description, location;

  @override
  void initState() {
    super.initState();
    AlarmInfo alarm = widget.alarmInfo;

    if (alarm == null) {
      //initialize widgets in form
      refID = "";
      notifID = DateTime.now().millisecondsSinceEpoch;

      startTime = new DateTime.now();
      startDate = startTime;
      daysList = List.filled(7, false, growable: false);
      timestamp = helper.getTimeStamp(startDate, startTime);

      alarmName = TextEditingController(text: "");
      description = TextEditingController(text: "");
      location = TextEditingController(text: "");
    } else {
      //autofill form
      refID = alarm.reference.id;
      notifID = alarm.notifID;

      startTime = DateFormat.jm().parse(alarm.startTime);
      startDate = DateFormat.MMMEd().parse(alarm.date);
      daysList = alarm.weekdays.map((i) => i as bool).toList(growable: false);
      timestamp = alarm.timestamp;

      alarmName = TextEditingController(text: alarm.name);
      description = TextEditingController(text: alarm.description);
      location = TextEditingController(text: alarm.location);
    }

    timeString = TimeOfDay.fromDateTime(startTime).format(context);
    dateString = DateFormat.MMMEd().format(startDate);
  }

  @override
  void dispose() {
    alarmName.dispose();
    description.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title), leading: BackButton()),
        body: Form(
          key: formKey,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: pad/2),
              children: [

                //time picker
                Card(
                  elevation: pad/2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                  child: Container(
                    height: MediaQuery.of(context).size.height/3,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(brightness: Theme.of(context).brightness),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: startTime,
                        use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                        onDateTimeChanged: (date) {
                          HapticFeedback.selectionClick();
                          startTime = date;
                          timeString = TimeOfDay.fromDateTime(startTime).format(context);
                        },
                      ),
                    ),
                  ),
                ),

                //options for repeating alarms
                WeekdaySelector(
                  elevation: pad/2,
                  selectedElevation: pad/3,
                  textStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).accentColor),
                  selectedTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  values: daysList,
                  onChanged: (day) {
                    HapticFeedback.selectionClick();

                    setState(() {
                      //select weekdays for repeating alarms
                      daysList[day % 7] = !daysList[day % 7];

                      //get the date for the next alarm
                      startDate = helper.whentoRing(daysList, 0);
                      timestamp = helper.getTimeStamp(startDate, startTime);
                      dateString = DateFormat.MMMEd().format(startDate);
                    });
                  },
                ),

                Card(
                  elevation: pad/2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                  child: Container(
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        //show preview for next alarm
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Alarm will ring on "),
                            Text("$dateString", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),

                        //name textfield
                        TextFormField(
                          controller: alarmName,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value.isEmpty) {return "Enter a name for this alarm";}
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            icon: const Icon(Icons.event),
                            labelText: "Name",
                          ),
                        ),

                        //description textfield
                        TextFormField(
                          controller: description,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                          validator: (value) {
                            if (value.isEmpty) {return "Enter a description for this alarm";}
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            icon: const Icon(Icons.list),
                            labelText: "Description",
                          ),
                        ),

                        //location textfield
                        TextField(
                          controller: location,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            icon: const Icon(Icons.location_on),
                            labelText: "Location (optional)",
                          ),
                        ),

                        //save button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: Text("Save"),
                              onPressed: () {
                                int currentTime = DateTime.now().millisecondsSinceEpoch;

                                //validate form
                                if (timestamp > currentTime) {
                                  if (formKey.currentState.validate()) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text("Alarm has been set"),
                                    ));

                                    setAlarm(alarmName.text, description.text, location.text);
                                    Navigator.pop(context);
                                  }

                                //form is invalid due to time chosen
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text("Please choose a time in the future"),
                                  ));
                                }
                              }
                            ),
                          ]
                        ),
                      ]
                    ),
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }

  //save alarm details to database
  void setAlarm(String name, String desc, String loc) {
    final db = new AlarmModel();
    final notifications = NotificationService();

    AlarmInfo alarm = new AlarmInfo(
      notifID: notifID,
      startTime: timeString,
      weekdays: daysList,
      date: dateString,
      timestamp: timestamp,
      name: name,
      description: desc,
      location: loc,
      shouldNotify: true,
    );

    //send alarm to database
    if (refID.isEmpty) {
      print("Store alarm in database");

      db.storeData(alarm);
      notifications.schedule(alarm, timestamp);
    } else {
      print("Update alarm in database");

      db.updateData(alarm, refID);
      notifications.schedule(alarm, timestamp);
    }
  }
}