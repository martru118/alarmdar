import 'package:cloud_firestore/cloud_firestore.dart';

import 'event_info.dart';

class EventModel {
  final db = FirebaseFirestore.instance;
  final String collectionPath = "events";

  //get events from firestore
  Stream<QuerySnapshot> retrieveEvents() {
    return db.collection(collectionPath).orderBy("date", descending: true).snapshots();
  }

  //get specific events by reference ID
  EventInfo retrievebyID(String path) {
    EventInfo getEvent;
    db.collection(collectionPath).doc(path).get().then((info) {
      getEvent = EventInfo.fromMap(info.data());
    });

    return getEvent;
  }

  //add event
  void storeEventData(EventInfo event) {
    db.collection(collectionPath).add(event.toJson());
  }

  //update event
  void updateEventData(EventInfo event, String document) {
    try {
      db.collection(collectionPath).doc(document).update(event.toJson());
    } catch (e) {
      e.toString();
    }
  }

  //delete event
  void deleteEvent(String path) {
    try {
      db.collection(collectionPath).doc(path).delete();
    } catch (e) {
      e.toString();
    }
  }
}