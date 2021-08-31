import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlarmInfo {
  DocumentReference reference;
  final int createdAt;
  String start;
  int timestamp;
  int option;
  final String name;
  final String description;
  final String location;
  bool shouldNotify;

  AlarmInfo({this.reference,
    @required this.createdAt,
    @required this.start,
    @required this.timestamp,
    @required this.option,
    @required this.name,
    @required this.description,
    @required this.location,
    @required this.shouldNotify,
  });

  //get an alarm from map
  AlarmInfo.fromMap(Map<String, dynamic> snapshot, {this.reference}):
    this.createdAt = snapshot['createdAt'],
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
      'createdAt': createdAt,
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