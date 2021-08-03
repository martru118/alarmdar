import 'dart:async';

import 'event_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'firebase_utils.dart';


class CalendarForm extends StatefulWidget {
  final EventInfo event;
  final String refID;
  CalendarForm({Key key, this.event, this.refID});

  @override
  FormPage createState() => FormPage();
}

class FormPage extends State<CalendarForm> {
  final db = EventModel();
  final _formKey = new GlobalKey<FormState>();

  //initialize ui
  final _name = TextEditingController(text: "");
  final _description = TextEditingController(text: "");

  final _location = TextEditingController(text: "");
  final String api = "AIzaSyCoJd4N_hGhEdv8tSrCGkOdVNelVOlntdY";

  DateTime _date = DateTime.now();
  TimeOfDay _start = TimeOfDay.now();
  TimeOfDay _end = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));

  bool notify = false;


  //modify event
  void _setEvent(String name, String desc, String loc) {
    EventInfo event = new EventInfo(
      name: name,
      date: DateFormat.yMd().format(_date),
      startTime: _start.format(context),
      endTime: _end.format(context),
      description: desc,
      location: loc,
      shouldNotify: notify,
    );

    if (widget.refID.isEmpty) {
      //add event to firestore
      db.storeEventData(event);
    } else {
      //update event
      db.updateEventData(event, widget.refID);
    }
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
      appBar: AppBar(title: Text("Modify Event")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            //name textfield
            TextFormField(
              controller: _name,
              validator: (value) {
                if (value.isEmpty) {return "Please enter the name of this event";}
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.event),
                labelText: "Name of Event",
              ),
            ),

            //select date row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Select Date:"), SizedBox(width: 20.0),
                FlatButton(
                  color: Theme.of(context).primaryColor,
                  child: Text(DateFormat.yMd().format(_date)),
                  onPressed: () => selectDate(context),
                ),
              ],
            ),

            //select time row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //start time
                Text("Time:"), SizedBox(width: 20.0),
                FlatButton(
                  color: Theme.of(context).primaryColor,
                  child: Text(_start.format(context)),
                  onPressed: () => selectStartTime(context),
                ), SizedBox(width: 5.0),

                //end time
                Text("to"), SizedBox(width: 5.0),
                FlatButton(
                  color: Theme.of(context).primaryColor,
                  child: Text(_end.format(context)),
                  onPressed: () => selectEndTime(context),
                ),
              ],
            ),

            //description textfield
            TextFormField(
              controller: _description,
              validator: (value) {
                if (value.isEmpty) {return "Please enter a description for this event";}
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.list),
                labelText: "Event Description",
              ),
            ),

            //location textfield
            TextFormField(
              readOnly: true,
              controller: _location,
              validator: (value) {
                if (value.isEmpty) {return "Please enter a location for this event";}
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.location_on),
                labelText: "Location",
              ),
            ),

            //notification switch
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Send notifications?"), SizedBox(width: 10),
                Switch(
                  activeTrackColor: Theme.of(context).accentColor,
                  activeColor: Theme.of(context).accentColor,
                  value: notify,
                  onChanged: (value) {
                    setState(() => notify = value);
                  },
                )
              ],
            )
          ],
        ),
      ),

      floatingActionButton: new FloatingActionButton(
        tooltip: "Save event",
        child: const Icon(Icons.save),
        onPressed: () {
          String name = _name.text;
          String desc = _description.text;
          String loc = _location.text;

          //validate textfields
          if (_formKey.currentState.validate()) {
            print("Save event");

            _setEvent(name, desc, loc);
            Navigator.pop(context);
          }
        }
      ),
    );
  }

  Future<void> selectDate(BuildContext context) async {
    print("Select date");

    //pick a date
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );

    //set date
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> selectStartTime(BuildContext context) async {
    print("Select starting time");

    //pick a time
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: _start,
    );

    //set time
    if (picked != null) setState(() {
      _start = picked;
      _end = TimeOfDay(hour: picked.hour+1, minute: picked.minute);
    });
  }

  Future<void> selectEndTime(BuildContext context) async {
    print("Select ending time");

    //pick a time
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: _end,
    );

    //set time
    if (picked != null) {
      double starting = _start.hour + (_start.minute/60.0);
      double ending = picked.hour + (picked.minute/60.0);

      //check if end time is greater than start time
      setState(() {
        if (ending > starting) _end = picked;
        else _end = TimeOfDay(hour: _start.hour+1, minute: _start.minute);
      });
    }
  }
}