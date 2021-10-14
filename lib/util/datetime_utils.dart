class DateTimeHelper {
  final List<String> recurrences = [
    "Only once",
    "Every hour",
    "Every day",
    "Every week",
    "Every month",
    "Every year",
  ];

  //calculate the date for the next alarm
  DateTime nextAlarm(DateTime initial, int option) {
    final DateTime now = new DateTime.now();

    switch (option) {
      //alarm repeats every hour
      case 1:
        var scheduled = DateTime(now.year, now.month, now.day, now.hour, initial.minute);
        if (scheduled.isBefore(now)) scheduled = scheduled.add(new Duration(hours: 1));
        return scheduled;

      //alarm repeats every day
      case 2:
        var scheduled = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);
        if (scheduled.isBefore(now)) scheduled = scheduled.add(new Duration(days: 1));
        return scheduled;

      //alarm repeats every week
      case 3: return initial.add(new Duration(days: 7));

      //alarm repeats every month
      case 4:
        List<int> daysYear = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        List<int> daysLeap = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        bool isLeap = isLeapYear(initial.year);

        //add the number of days in the current month
        int month = initial.month;
        int daystoAdd = isLeap? daysLeap[month - 1] : daysYear[month - 1];
        return initial.add(new Duration(days: daystoAdd));

      //alarm repeats every year
      case 5:
        //add the number of days in the next year
        bool isLeap = isLeapYear(initial.year + 1);
        int daystoAdd = isLeap? 366 : 365;
        return initial.add(new Duration(days: daystoAdd));

      //alarm repeats only once
      default: return null;
    }
  }

  bool isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }

  //convert alarm date and time to unix timestamp
  int getTimeStamp(DateTime date) {
    return DateTime(date.year, date.month, date.day, date.hour, date.minute).millisecondsSinceEpoch;
  }
}