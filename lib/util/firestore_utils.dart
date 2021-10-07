import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/alarm_info.dart';

class AlarmModel {
  final _db = FirebaseFirestore.instance;
  final String _collectionPath = "alarms";

  //get alarms from Cloud Firestore
  Stream<QuerySnapshot> retrieveAll() {
    return _db.collection(_collectionPath)
        .orderBy("notify", descending: true)
        .orderBy("timestamp")
        .snapshots();
  }

  //get specific alarms by reference ID
  Future<AlarmInfo> retrievebyID(String path) async {
    AlarmInfo alarmInfo;
    await _db.collection(_collectionPath).doc(path).get().then((info) {
      alarmInfo = AlarmInfo.fromMap(info.data(), reference: info.reference);
    });

    return alarmInfo;
  }

  //add alarm to database
  void storeData(AlarmInfo alarm) {
    String path = alarm.hashcode.toString();
    _db.collection(_collectionPath).doc(path).set(alarm.toJson(), SetOptions(merge: true));
  }

  //delete alarm
  void deleteData(String path) {
    try {
      _db.collection(_collectionPath).doc(path).delete();
    } catch (e) {
      e.toString();
    }
  }
}