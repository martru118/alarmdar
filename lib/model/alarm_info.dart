import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlarmInfo {
  DocumentReference reference;
  final int notifID;

  final String startTime;
  final List<dynamic> weekdays;
  String date;
  int timestamp;

  final String name;
  final String description;
  final String location;
  bool shouldNotify;

  AlarmInfo({this.reference,
    @required this.notifID,
    @required this.startTime,
    @required this.weekdays,
    @required this.date,
    @required this.timestamp,
    @required this.name,
    @required this.description,
    @required this.location,
    @required this.shouldNotify,
  });

  //get an alarm from map
  AlarmInfo.fromMap(Map<String, dynamic> snapshot, {this.reference}):
    this.notifID = snapshot['notifID'],
    this.startTime = snapshot['start'],
    this.weekdays = snapshot['weekdays'],
    this.date = snapshot['date'],
    this.timestamp = snapshot['timestamp'],
    this.name = snapshot['name'],
    this.description = snapshot['desc'],
    this.location = snapshot['loc'],
    this.shouldNotify = snapshot['notify'];

  //set alarm as JSON
  Map<String, dynamic> toJson() {
    return {
      'notifID': notifID,
      'start': startTime,
      'weekdays': weekdays,
      'date': date,
      'timestamp': timestamp,
      'name': name,
      'desc': description,
      'loc': location,
      'notify': shouldNotify,
    };
  }
}