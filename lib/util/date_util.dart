import 'package:intl/intl.dart';

class DateTimeHelper {
  //determines the date for the next alarm
  DateTime whentoRing(List<bool> weekdays) {
    final DateTime today = new DateTime.now();

    if (weekdays.where((i) => !i).length == 7) {
      //alarm rings tomorrow if no weekdays are selected
      return DateTime(today.year, today.month, today.day + 1);
    } else {
      for (int wd = 0; wd < 7; wd++) {
        //alarm rings on the next selected weekday
        if (weekdays[(today.weekday + wd) % 7])
          return DateTime(today.year, today.month, today.day + wd);
      }
    }
  }

  //convert alarm date and time to unix timestamp
  int getTimeStamp(DateTime date, DateTime time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute).millisecondsSinceEpoch;
  }
}