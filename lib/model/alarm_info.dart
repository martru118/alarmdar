import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlarmInfo {
  DocumentReference reference;
  @required String startTime;
  @required List<dynamic> weekdays;
  @required String date;
  @required int timestamp;
  @required String name;
  @required String description;
  @required String location;
  @required bool gSync;
  @required bool shouldNotify;

  AlarmInfo({this.reference,
    this.startTime,
    this.weekdays,
    this.date,
    this.timestamp,
    this.name,
    this.description,
    this.location,
    this.gSync,
    this.shouldNotify,
  });

  //get an alarm from map
  AlarmInfo.fromMap(Map<String, dynamic> snapshot, {this.reference}):
    this.startTime = snapshot['start'],
    this.weekdays = snapshot['weekdays'],
    this.date = snapshot['date'],
    this.timestamp = snapshot['timestamp'],
    this.name = snapshot['name'],
    this.description = snapshot['desc'],
    this.location = snapshot['loc'],
    this.gSync = snapshot['sync'],
    this.shouldNotify = snapshot['notify'];

  //set alarm as JSON
  dynamic toJson() {
    return {
      'start': startTime,
      'weekdays': weekdays,
      'date': date,
      'timestamp': timestamp,
      'name': name,
      'desc': description,
      'loc': location,
      'sync': gSync,
      'notify': shouldNotify,
    };
  }
}