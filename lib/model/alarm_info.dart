import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlarmInfo {
  DocumentReference reference;
  final int hashcode;
  String start;
  int timestamp;
  final int option;
  final String name;
  final String description;
  final String location;
  bool shouldNotify;

  AlarmInfo({this.reference,
    @required this.hashcode,
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