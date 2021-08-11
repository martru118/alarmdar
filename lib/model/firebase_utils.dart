import 'package:cloud_firestore/cloud_firestore.dart';

import 'alarm_info.dart';

class AlarmModel {
  final db = FirebaseFirestore.instance;
  final String collectionPath = "alarms";

  //get alarms from Cloud Firestore
  Stream<QuerySnapshot> retrieveAll() {
    return db.collection(collectionPath).orderBy("start", descending: true).snapshots();
  }

  //get specific alarms by reference ID
  AlarmInfo retrievebyID(String path) {
    AlarmInfo alarm;
    db.collection(collectionPath).doc(path).get().then((info) {
      alarm = AlarmInfo.fromMap(info.data());
    });

    return alarm;
  }

  //add alarm
  void storeData(AlarmInfo alarm) {
    db.collection(collectionPath).add(alarm.toJson());
  }

  //update alarm
  void updateData(AlarmInfo alarm, String document) {
    try {
      db.collection(collectionPath).doc(document).update(alarm.toJson());
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