import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class AppDatabase {
  Completer<Database> _openCompleter;

  //singleton instance
  static final AppDatabase _appData = AppDatabase._internal();
  static AppDatabase get instance => _appData;
  AppDatabase._internal();

  //initialize database
  Future<Database> get database async {
    if (_openCompleter == null) {
      _openCompleter = Completer();
      _openDatabase();
    }

    return _openCompleter.future;
  }

  //open database at specific path
  Future _openDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + "alarmdar.db";

    final db = await databaseFactoryIo.openDatabase(path);
    _openCompleter.complete(db);
  }
}