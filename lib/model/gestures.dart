import 'package:alarmdar/model/alarm_dao.dart';
import 'package:alarmdar/model/alarm_info.dart';
import 'package:alarmdar/screens/alarm_form.dart';
import 'package:alarmdar/util/notifications.dart';
import 'package:alarmdar/util/routes.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GesturesProvider extends ChangeNotifier {
  AlarmInfo _alarm;
  AlarmInfo get getAlarm => this._alarm;
  set setAlarm(AlarmInfo alarmInfo) => this._alarm = alarmInfo;

  final _db = AlarmDao();
  final _notifications = NotificationService();

  //actions performed when setting and editing an alarm
  void setEdit(BuildContext context, int heading, [AlarmInfo alarmInfo]) async {
    print("Start form for setting or editing an alarm");

    //listen for updates
    final listener = await Navigator.of(context).pushNamed(
      AlarmForm.route,
      arguments: ScreenArguments(
        alarmInfo: alarmInfo,
        title: AlarmForm.titles[heading],
    )) as AlarmInfo;

    //update alarm info
    if (listener != null && alarmInfo != null) {
      listener.reference = alarmInfo.reference;
      setAlarm = listener;

      print("Updated alarm info ${getAlarm.toJson()}");
      notifyListeners();
    }
  }

  //remove alarm if not null
  void delete(int selected) {
    print("Delete alarm $selected");

    if (selected != null) {
      toast("Alarm has been removed");
      _db.deleteAlarm(selected);
      _notifications.cancel(selected);
    }
  }

  //turn alarm off
  void archive(AlarmInfo alarmInfo) {
    print("Alarm ${alarmInfo.hashcode} is turned OFF");
    toast("Alarm is turned off");

    //cancel current alarm
    alarmInfo.shouldNotify = false;
    _db.storeAlarm(alarmInfo);
    _notifications.cancel(alarmInfo.hashcode);
  }

  //turn alarm on
  void restore(AlarmInfo alarmInfo) {
    print("Alarm ${alarmInfo.hashcode} is turned ON");
    toast("Alarm is set for ${alarmInfo.start}");

    //reschedule current alarm
    alarmInfo.shouldNotify = true;
    _db.storeAlarm(alarmInfo);
    _notifications.schedule(alarmInfo, alarmInfo.timestamp);
  }

  void snackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void toast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER
    );
  }
}