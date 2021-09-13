import 'dart:math';

import 'package:alarmdar/util/date_utils.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'alarm_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../util/firebase_utils.dart';

class AlarmForm extends StatefulWidget {
  static const String route = "/form";
  final AlarmInfo alarmInfo;
  final String title;

  AlarmForm({Key key,
    @required this.alarmInfo,
    @required this.title,
  }): super(key: key);

  @override
  _AlarmFormState createState() => _AlarmFormState();
}

class _AlarmFormState extends State<AlarmForm> {
  final helper = new DateTimeHelper();
  final formKey = new GlobalKey<FormState>();
  static const double pad = 12;

  //initialize ui
  int hash, timestamp;
  int recurrenceOption;
  DateTime start;
  var minimum, alarmName, description, location;

  @override
  void initState() {
    super.initState();
    AlarmInfo alarm = widget.alarmInfo;
    DateTime today = new DateTime.now();

    if (alarm == null) {
      //initialize form UI
      hash = new Random().nextInt(pow(2, 31) - 1);
      start = today;
      timestamp = helper.getTimeStamp(start);
      recurrenceOption = 0;

      alarmName = TextEditingController(text: "");
      description = TextEditingController(text: "");
      location = TextEditingController(text: "");
    } else {
      //autofill form
      hash = alarm.hashcode;
      start = DateFormat.yMMMEd().add_jm().parse(alarm.start);
      timestamp = alarm.timestamp;
      recurrenceOption = alarm.option;

      alarmName = TextEditingController(text: alarm.name);
      description = TextEditingController(text: alarm.description);
      location = TextEditingController(text: alarm.location);
    }

    //minimum date and time for picker
    minimum = new DateTime(today.year, today.month, today.day, 0, 0);
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
        body: buildForm(context),
      ),
    );
  }

  Widget buildForm(BuildContext context) {
    return Form(key: formKey,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: pad/2),
          child: Column(
            children: [

              //date and time picker
              Card(
                elevation: pad/2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height/3,
                      child: CupertinoTheme(
                        data: CupertinoThemeData(brightness: Theme.of(context).brightness),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.dateAndTime,
                          initialDateTime: start,
                          minimumDate: minimum,
                          maximumDate: start.add(new Duration(days: 366)),
                          use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                          onDateTimeChanged: (datetime) {
                            HapticFeedback.selectionClick();

                            //set time
                            start = datetime;
                            timestamp = helper.getTimeStamp(start);
                            print("AlarmFrom/CupertinoDatePicker::time = $datetime");
                          },
                        ),
                      ),
                    ),
                  ]
                ),
              ),

              //recurrence options
              Card(
                elevation: pad/2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Remind me "),
                        DropdownButton(
                          value: recurrenceOption,
                          items: List.generate(helper.recurrences.length, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Text("${helper.recurrences[index].toLowerCase()}",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            );
                          }),
                          onChanged: (value) => setState(() => recurrenceOption = value),
                        ),
                      ]
                    ),
                  ],
                ),
              ),

              Card(
                elevation: pad/2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                child: Container(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      //alarm message
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text("An alarm will ring at the above times")],
                      ),

                      //name textfield
                      TextFormField(
                        controller: alarmName,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value.isEmpty) return "Enter a name for this alarm";
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
                          if (value.isEmpty) return "Enter a description for this alarm";
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
                      ), SizedBox(height: pad),

                      //save button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            label: Text("Save"),
                            icon: const Icon(Icons.save),
                            onPressed: onValidate,
                          )
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
    );
  }

  //validate form
  void onValidate() {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    print("Alarm is scheduled for $timestamp, validated at $currentTime");

    //validate form
    if (timestamp > currentTime) {
      if (formKey.currentState.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Alarm has been set"),
        ));

        //get new alarm
        var onUpdate = setAlarm(alarmName.text, description.text, location.text);
        Navigator.pop(context, onUpdate);
      }

    //form is invalid due to time chosen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please choose a time in the future"),
      ));
    }
  }

  //save alarm details to database
  AlarmInfo setAlarm(String name, String desc, String loc) {
    final db = new AlarmModel();
    final notifications = NotificationService();

    AlarmInfo alarm = new AlarmInfo(
      hashcode: hash,
      start: DateFormat.yMMMEd().add_jm().format(start),
      timestamp: timestamp,
      option: recurrenceOption,
      name: name,
      description: desc,
      location: loc,
      shouldNotify: true,
    );

    //schedule alarm
    db.storeData(alarm);
    notifications.schedule(alarm, timestamp);
    return alarm;
  }
}