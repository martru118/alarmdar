import 'dart:math';

import 'package:alarmdar/util/datetime_utils.dart';
import 'package:alarmdar/model/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../model/alarm_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlarmForm extends StatefulWidget {
  static const String route = "/form";
  final AlarmInfo alarmInfo;
  final String title;

  AlarmForm({Key key,
    @required this.alarmInfo,
    @required this.title,
  }): super(key: key) {
    if (alarmInfo != null) assert(alarmInfo.reference != null);
  }

  @override
  _AlarmFormState createState() => _AlarmFormState();

  //possible titles for the form
  static final titles = [
    "Set Alarm",
    "Edit Alarm",
  ];
}

class _AlarmFormState extends State<AlarmForm> {
  final gestures = GesturesProvider();
  final helper = DateTimeHelper();
  static const double pad = 12;

  //initialize ui
  int hash, timestamp;
  int recurrenceOption;
  DateTime start;
  var minDate, maxDate, alarmName, description, location;
  final formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    AlarmInfo alarm = widget.alarmInfo;
    DateTime now = new DateTime.now();

    if (alarm == null) {
      //initialize form UI
      hash = new Random().nextInt(pow(2, 31) - 1);
      start = now;
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

    //initialize time picker
    if (start.isBefore(now)) start = new DateTime(now.year, now.month, now.day, start.hour, start.minute);
    minDate = new DateTime(now.year, now.month, now.day, 0, 0);
    maxDate = helper.isLeapYear(now.year + 1)? 366 : 365;
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
      appBar: AppBar(title: Text(widget.title)),
      body: buildForm(context),
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
              Card(
                elevation: pad/2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: buildPicker(context),
                ),
              ),

              Card(
                elevation: pad/2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pad/2)),
                child: Container(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: buildInput(context),
                )),
              ),
            ]
          ),
        ),
      ),
    );
  }

  List<Widget> buildPicker(BuildContext context)  => [
    //date and time picker
    Container(
      height: MediaQuery.of(context).size.height/3,
      child: CupertinoTheme(
        data: CupertinoThemeData(brightness: Theme.of(context).brightness),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.dateAndTime,
          initialDateTime: start,
          minimumDate: minDate,
          maximumDate: minDate.add(new Duration(days: maxDate + 1)),
          use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
          onDateTimeChanged: (datetime) {
            HapticFeedback.selectionClick();

            //set time
            start = datetime;
            timestamp = helper.getTimeStamp(start);
            print("Selected time is $datetime");
          },
        ),
      ),
    ),

    //recurrence options
    Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: pad/8,
        )),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Remind me\t"),
          DropdownButton(
            value: recurrenceOption,
            items: List.generate(helper.recurrences.length, (index) {
              return DropdownMenuItem(
                value: index,
                child: Text("${helper.recurrences[index].toLowerCase()}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
              )));
            }, growable: false),
            onChanged: (index) => setState(() => recurrenceOption = index),
          ),
        ]
      ),
    ),
  ];

  List<Widget> buildInput(BuildContext context) => [
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
        ),
      ]
    ),
  ];

  //validate form
  void onValidate() {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    print("Alarm is scheduled for $timestamp, validated at $currentTime");

    //set new alarm
    if (timestamp > currentTime) {
      if (formKey.currentState.validate()) {
        var onUpdate = newAlarm(alarmName.text, description.text, location.text);
        Navigator.pop(context, onUpdate);
      }

    //form is invalid due to time chosen
    } else {
      gestures.snackbar(context, "Please choose a time in the future");
    }
  }

  //save alarm details to database
  AlarmInfo newAlarm(String name, String desc, String loc) {
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
    gestures.restore(alarm);
    return alarm;
  }
}