import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlarmInfo {
  DocumentReference reference;
  final String startTime;
  final List<dynamic> weekdays;
  final String date;
  final int timestamp;
  final String name;
  final String description;
  final String location;
  bool gSync;
  bool shouldNotify;

  AlarmInfo({this.reference,
    @required this.startTime,
    @required this.weekdays,
    @required this.date,
    @required this.timestamp,
    @required this.name,
    @required this.description,
    @required this.location,
    @required this.gSync,
    @required this.shouldNotify,
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
  Map<String, dynamic> toJson() {
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