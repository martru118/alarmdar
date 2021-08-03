import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'event_info.dart';
import 'firebase_utils.dart';
import 'form_events.dart';


class CalendarEvents extends StatefulWidget {
  CalendarEvents({Key key, this.title}): super(key: key);
  final String title;

  @override
  EventsPage createState() => EventsPage();
}

class EventsPage extends State<CalendarEvents> {
  final db = new EventModel();
  String _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: buildList(),
      floatingActionButton: new FloatingActionButton(
          tooltip: "Add event",
          child: const Icon(Icons.add),
          onPressed: () {
            print("Add event");
            _startForm(context);
          }
      ),
    );
  }

  Widget buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.retrieveEvents(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        } else {
          return ListView(
            children: snapshot.data.docs.map((DocumentSnapshot snapshot) => _buildEvent(context, snapshot)).toList(),
          );
        }
      },
    );
  }

  Widget _buildEvent(BuildContext context, DocumentSnapshot documentData) {
    final eventInfo = EventInfo.fromMap(documentData.data(), reference: documentData.reference);

    return Card(
      elevation: 3.0,
      child: ListTile(
        title: Text("${eventInfo.name}\n${eventInfo.date}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_buildSubtitle(eventInfo)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            //edit button
            IconButton(icon: const Icon(Icons.edit),
              padding: EdgeInsets.only(right: 16.0),
              constraints: BoxConstraints(),
              tooltip: "Edit Event",
              onPressed: () {
                _selected = eventInfo.reference.id;
                print("Edit event: $_selected");

                //edit selected grade
                _startForm(context, db.retrievebyID(_selected), _selected);
              }
            ),

            //delete button
            IconButton(icon: const Icon(Icons.delete),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              tooltip: "Delete Event",
              onPressed: () {
                _selected = eventInfo.reference.id;
                print("Delete event: $_selected");

                //delete selected grade
                if (_selected != null) {
                  db.deleteEvent(_selected);
                  _selected = null;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  //build subtitle for event
  String _buildSubtitle(EventInfo event) {
    String subtitle = "${event.description}";
    subtitle += "\n\n\uD83D\uDD53\t${event.startTime} to ${event.endTime}";

    //add location to subtitle
    if (event.location.isNotEmpty) subtitle += "\n\uD83D\uDCCD\t${event.location}";
    return subtitle;
  }

  void _startForm(BuildContext context, [EventInfo eventInfo, String _id=""]) async {
    await Navigator.of(context).push(new MaterialPageRoute(
      builder: (BuildContext context) => new CalendarForm(event: eventInfo, refID: _id),
    ));

    _selected = null;
  }
}