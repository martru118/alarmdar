import 'package:cloud_firestore/cloud_firestore.dart';

import 'alarm_info.dart';

class AlarmModel {
  final db = FirebaseFirestore.instance;
  final String collectionPath = "alarms";

  //get alarms from Cloud Firestore
  Stream<QuerySnapshot> retrieveAll() {
    return db.collection(collectionPath).orderBy("timestamp").snapshots();
  }

  //get specific alarms by reference ID
  AlarmInfo retrievebyID(String path) {
    db.collection(collectionPath).doc(path).get().then((info) {
      return AlarmInfo.fromMap(info.data(), reference: info.reference);
    });
  }

  //add alarm
  void storeData(AlarmInfo alarm) {
    db.collection(collectionPath).add(alarm.toJson());
  }

  //update alarm
  void updateData(AlarmInfo alarm, String path) {
    try {
      db.collection(collectionPath).doc(path).update(alarm.toJson());
    } catch (e) {
      e.toString();
    }
  }

  //delete alarm
  void deleteData(String path) {
    try {
      db.collection(collectionPath).doc(path).delete();
    } catch (e) {
      e.toString();
    }
  }
}