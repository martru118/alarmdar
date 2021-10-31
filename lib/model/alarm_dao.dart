import 'dart:async';

import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/model/sembast_utlis.dart';
import 'package:sembast/sembast.dart';

class AlarmDao {
  static const String _collectionPath = "alarms";
  final _store = intMapStoreFactory.store(_collectionPath);

  //open current instance of database
  Future<Database> get _db async => await AppDatabase.instance.database;

  //listen to changes in the database
  Future<Stream<List<AlarmInfo>>> alarmStream() async {
    var finder = Finder(sortOrders: [
      SortOrder("notify", false),
      SortOrder("timestamp", true),
    ]);

    //get entries from snapshot
    var transformer = StreamTransformer<
        List<RecordSnapshot<int, Map<String, dynamic>>>,
        List<AlarmInfo>
    >.fromHandlers(handleData: (field, sink) {
      List<AlarmInfo> results = [];
      field.forEach((snapshot) => results.add(AlarmInfo.fromMap(snapshot.value, reference: snapshot.ref)));
      sink.add(results);

      print("${results.length} items in the database");
    });

    return _store.query(finder: finder).onSnapshots(await _db).transform(transformer);
  }

  //get alarm by id
  Future<AlarmInfo> getAlarm(int path) async {
    var ref = _store.record(path);
    var snapshot = await ref.get(await _db);
    return AlarmInfo.fromMap(snapshot, reference: ref);
  }

  //add alarm to database
  void storeAlarm(AlarmInfo alarmInfo) async {
    await _store.record(alarmInfo.hashcode).put(await _db, alarmInfo.toJson(), merge: true);
  }

  //delete alarm from database
  void deleteAlarm(int path) async {
    try {
      await _store.record(path).delete(await _db);
    } catch (e) {
      e.toString();
    }
  }
}