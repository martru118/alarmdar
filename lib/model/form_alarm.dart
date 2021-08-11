import 'package:flutter/cupertino.dart';
import 'package:weekday_selector/weekday_selector.dart';

import 'alarm_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'firebase_utils.dart';


class AlarmForm extends StatefulWidget {
  final AlarmInfo alarmInfo;
  final String refID;
  AlarmForm({Key key, this.alarmInfo, this.refID});

  @override
  FormPage createState() => FormPage();
}

class FormPage extends State<AlarmForm> {
  final db = AlarmModel();
  final formKey = new GlobalKey<FormState>();

  //initialize ui
  TimeOfDay _start = TimeOfDay.now();
  String eta = "tomorrow";
  List<bool> weekdays = List.filled(7, false, growable: false);

  static const double pad = 12;
  var _name, _description, _location;
  bool sync = false;

  @override
  void initState() {
    _name = TextEditingController(text: "");
    _description = TextEditingController(text: "");
    _location = TextEditingController(text: "");

    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Alarm"), leading: BackButton()),
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
                      initialDateTime: DateTime.now(),
                      use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                      onDateTimeChanged: (date) {
                        _start = TimeOfDay.fromDateTime(date);
                        print("Alarm set for ${_start.format(context)}");
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
                onChanged: (date) {
                  setState(() => weekdays[date % 7] = !weekdays[date % 7]);

                  //change message for next alarm
                  if (weekdays.where((i) => i).length == 7) eta = "everyday";
                  else if (weekdays.where((i) => !i).length == 7) eta = "tomorrow";
                  else eta = "on select weekdays";
                },
                values: weekdays,
              ),

              Card(
                elevation: pad/2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                child: Container(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Alarm will go off $eta"),
                        ],
                      ), SizedBox(height: pad/2),

                      //name textfield
                      TextFormField(
                        controller: _name,
                        validator: (value) {
                          if (value.isEmpty) {return "Enter a name for this alarm";}
                          return null;
                        },
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: const Icon(Icons.event),
                          hintText: "Name*",
                        ),
                      ), SizedBox(height: pad),

                      //description textfield
                      TextFormField(
                        controller: _description,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        validator: (value) {
                          if (value.isEmpty) {return "Enter a description for this alarm";}
                          return null;
                        },
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: const Icon(Icons.list),
                          hintText: "Description*",
                        ),
                      ),

                      //location textfield
                      TextField(
                        controller: _location,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          icon: const Icon(Icons.location_on),
                          labelText: "Location (optional)",
                        ),
                      ), SizedBox(height: pad/2),

                      //sync switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("Sync to Google Calendar"),
                          Switch(
                            value: sync,
                            onChanged: (value) {
                              print("Toggle Google Calendar sync");
                              setState(() => sync = value);
                            },
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

      floatingActionButton: new FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () {
          String name = _name.text;
          String desc = _description.text;
          String loc = _location.text;

          //validate form
          if (formKey.currentState.validate()) {
            print("Save alarm");

            setAlarm(name, desc, loc);
            Navigator.pop(context);
          }
        }
      ),
    );
  }


  //determine the next day to fire alarm
  String whentoFire() {
    String _date;
    final today = DateTime.now();

    if (weekdays.where((i) => !i).length == 7) {
      //alarm does not repeat as no weekdays are selected, so the alarm fires tomorrow
      _date = DateFormat.yMd().format(DateTime(today.year, today.month, today.day + 1));
    } else {
      for (int wd = 0; wd < 7; wd++) {
        if (weekdays[(today.weekday + wd) % 7]) {
          //alarm repeats, so the alarm fires on the next selected weekday
          _date = DateFormat.yMd().format(DateTime(today.year, today.month, today.day + wd));
          break;
        }
      }
    }

    return _date;
  }

  //save alarm details to database
  void setAlarm(String name, String desc, String loc) {
    AlarmInfo alarm = new AlarmInfo(
      startTime: _start.format(context),
      weekdays: weekdays,
      date: whentoFire(),
      name: name,
      description: desc,
      location: loc,
      gSync: sync,
      shouldNotify: true,
    );

    print("${alarm.toJson()}");
    if (widget.refID.isEmpty) db.storeData(alarm);
    else db.updateData(alarm, widget.refID);
  }
}