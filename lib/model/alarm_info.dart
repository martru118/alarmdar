import 'package:sembast/sembast.dart';

class AlarmInfo {
  RecordRef reference;
  final int hashcode;
  String start;
  int timestamp;
  final int option;
  final String name;
  final String description;
  final String location;
  bool shouldNotify;

  AlarmInfo(this.hashcode,
    this.start,
    this.timestamp,
    this.option,
    this.name,
    this.description,
    this.location,
    this.shouldNotify, {
    this.reference,
  });

  //get an alarm from map
  AlarmInfo.fromMap(Map<String, dynamic> snapshot, {this.reference}):
    this.hashcode = snapshot['hash'],
    this.start = snapshot['start'],
    this.timestamp = snapshot['timestamp'],
    this.option = snapshot['recurrence'],
    this.name = snapshot['name'],
    this.description = snapshot['desc'],
    this.location = snapshot['location'],
    this.shouldNotify = snapshot['notify'];

  //set alarm as JSON
  Map<String, dynamic> toJson() {
    return {
      'hash': hashcode,
      'start': start,
      'timestamp': timestamp,
      'recurrence': option,
      'name': name,
      'desc': description,
      'location': location,
      'notify': shouldNotify,
    };
  }
}