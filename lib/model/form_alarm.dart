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
  FormPage createState() => FormPage();
}

class FormPage extends State<AlarmForm> {
  final helper = new DateTimeHelper();
  final formKey = new GlobalKey<FormState>();
  static const double pad = 12;

  //initialize ui
  int createdAt, timestamp;
  int recurrenceOption;
  DateTime start;
  var alarmName, description, location;

  @override
  void initState() {
    super.initState();
    AlarmInfo alarm = widget.alarmInfo;

    if (alarm == null) {
      //initialize for UI
      createdAt = new DateTime.now().millisecondsSinceEpoch;
      start = new DateTime.now();
      timestamp = helper.getTimeStamp(start);
      recurrenceOption = 0;

      alarmName = TextEditingController(text: "");
      description = TextEditingController(text: "");
      location = TextEditingController(text: "");
    } else {
      //autofill form
      createdAt = alarm.createdAt;
      start = DateFormat.yMMMEd().add_jm().parse(alarm.start);
      timestamp = alarm.timestamp;
      recurrenceOption = alarm.option;

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
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: pad/2),
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
                        minimumDate: new DateTime.now(),
                        maximumDate: start.add(new Duration(days: 365)),
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
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                    ListTile(
                      leading: Icon(Icons.music_note),
                      title: Text("An alarm will play at the above times"),
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
                    ), SizedBox(height: pad),

                    //save button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          label: Text("Save"),
                          icon: const Icon(Icons.save),
                          onPressed: () {
                            int currentTime = DateTime.now().millisecondsSinceEpoch;
                            print("Alarm is schduled for $timestamp, validated at $currentTime");

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
    );
  }

  //save alarm details to database
  void setAlarm(String name, String desc, String loc) {
    final db = new AlarmModel();
    final notifications = NotificationService();

    AlarmInfo alarm = new AlarmInfo(
      createdAt: createdAt,
      start: DateFormat.yMMMEd().add_jm().format(start),
      timestamp: timestamp,
      option: recurrenceOption,
      name: name,
      description: desc,
      location: loc,
      shouldNotify: true,
    );

    //send alarm to database
    if (alarm.reference == null) {
      print("Store alarm in database");

      db.storeData(alarm);
      notifications.schedule(alarm, timestamp);
    } else {
      print("Update alarm in database");
      db.updateData(alarm, alarm.createdAt.toString());
      notifications.schedule(alarm, timestamp);
    }
  }
}