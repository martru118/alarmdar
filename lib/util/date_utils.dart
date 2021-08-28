class DateTimeHelper {
  //determines the date for the next alarm
  DateTime whentoRing(List<bool> weekdays, int offset) {
    final DateTime today = new DateTime.now();
    bool isTomorrow = weekdays.where((i) => !i).length == 7 && offset == 0;

    //check if calculation is offset by one day
    if (isTomorrow) {
      switch (offset) {
        case 0: return today.add(new Duration(days: 1));
        default: return null;
      }

    //alarm rings on the next selected weekday
    } else {
      for (int wd = offset; wd < 7 + offset; wd++) {
        if (weekdays[(today.weekday + wd) % 7])
          return today.add(new Duration(days: wd));
      }
    }
  }

  //convert alarm date and time to unix timestamp
  int getTimeStamp(DateTime date, DateTime time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute).millisecondsSinceEpoch;
  }
}