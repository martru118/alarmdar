import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:weekday_selector/weekday_selector.dart';

import 'alarm_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'firebase_utils.dart';


class AlarmForm extends StatefulWidget {
  final AlarmInfo alarmInfo;
  final String title;

  AlarmForm({Key key,
    @required this.alarmInfo,
    @required this.title,
  });

  @override
  FormPage createState() => FormPage();
}

class FormPage extends State<AlarmForm> {
  final db = AlarmModel();
  final formKey = new GlobalKey<FormState>();
  static const double pad = 12;

  String selected;
  DateTime startTime;
  String startDate;
  int timestamp;
  List<bool> daysList;
  var alarmName, description, location;
  bool sync = false;

  @override
  void initState() {
    super.initState();
    AlarmInfo alarm = widget.alarmInfo;

    if (alarm == null) {
      //initialize widgets in form
      selected = "";
      startTime = new DateTime.now();
      daysList = List.filled(7, false, growable: false);
      startDate = whentoRing();

      alarmName = TextEditingController(text: "");
      description = TextEditingController(text: "");
      location = TextEditingController(text: "");
    } else {
      //autofill form
      selected = alarm.reference.id;
      startTime = DateFormat.jm().parse(alarm.startTime);
      daysList = alarm.weekdays.map((i) => i as bool).toList(growable: false);
      startDate = whentoRing();

      alarmName = TextEditingController(text: alarm.name);
      description = TextEditingController(text: alarm.description);
      location = TextEditingController(text: alarm.location);
    }
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
    return Scaffold(
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
                    startDate = whentoRing();
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
                          Text("$startDate", style: TextStyle(fontWeight: FontWeight.bold)),
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

                      //sync switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("Sync to Google Calendar"),
                          Switch(value: sync, onChanged: null),
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

      floatingActionButton: new FloatingActionButton(
        tooltip: "Save Changes",
        child: const Icon(Icons.save),
        onPressed: () {
          //validate form
          if (formKey.currentState.validate()) {
            setAlarm(alarmName.text, description.text, location.text);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Alarm has been set"),
            ));

            Navigator.pop(context);
          }
        }
      ),
    );
  }


  //determines the date for the next alarm
  String whentoRing() {
    final DateTime today = DateTime.now();
    DateTime nextDate;

    if (daysList.where((i) => !i).length == 7) {
      //alarm rings tomorrow if no weekdays are selected
      nextDate = DateTime(today.year, today.month, today.day + 1);
    } else {
      for (int wd = 0; wd < 7; wd++) {
        if (daysList[(today.weekday + wd) % 7]) {
          //alarm rings on the next selected weekday
          nextDate = DateTime(today.year, today.month, today.day + wd);
          break;
        }
      }
    }

    timestamp = getTimeStamp(nextDate, startTime);
    return DateFormat.MMMEd().format(nextDate);
  }

  //convert alarm date and time to unix timestamp
  int getTimeStamp(DateTime date, DateTime time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute).millisecondsSinceEpoch;
  }

  //save alarm details to database
  void setAlarm(String name, String desc, String loc) {
    AlarmInfo alarm = new AlarmInfo(
      startTime: TimeOfDay.fromDateTime(startTime).format(context),
      weekdays: daysList,
      date: startDate,
      timestamp: timestamp,
      name: name,
      description: desc,
      location: loc,
      gSync: sync,
      shouldNotify: true,
    );

    //send alarm to database
    if (selected.isEmpty) {
      print("Store alarm in database");
      db.storeData(alarm);
    } else {
      print("Update alarm in database");
      db.updateData(alarm, selected);
    }
  }
}