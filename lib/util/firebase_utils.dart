import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/alarm_info.dart';

class AlarmModel {
  final db = FirebaseFirestore.instance;
  final String collectionPath = "alarms";

  //get alarms from Cloud Firestore
  Stream<QuerySnapshot> retrieveAll() {
    return db.collection(collectionPath)
        .orderBy("notify", descending: true)
        .orderBy("timestamp")
        .snapshots();
  }

  //get specific alarms by reference ID
  Future<AlarmInfo> retrievebyID(String path) async {
    AlarmInfo alarmInfo;
    await db.collection(collectionPath).doc(path).get().then((info) {
      alarmInfo = AlarmInfo.fromMap(info.data(), reference: info.reference);
    });

    return alarmInfo;
  }

  //add alarm to database
  void storeData(AlarmInfo alarm) {
    String path = alarm.hashcode.toString();
    db.collection(collectionPath).doc(path).set(alarm.toJson(), SetOptions(merge: true));
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