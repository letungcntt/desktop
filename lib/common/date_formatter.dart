import 'package:intl/intl.dart';

class DateFormatter {
  String getVerboseDateTimeRepresentation(DateTime dateTime, locale) {
    DateTime now = DateTime.now();
    DateTime justNow = now.subtract(Duration(minutes: 1));
    DateTime localDateTime = dateTime.toLocal();

    if (!localDateTime.difference(justNow).isNegative) {
      return 'Just now';
    }

    // String roughTimeString = DateFormat('jm').format(dateTime);

    // if (localDateTime.day == now.day && localDateTime.month == now.month && localDateTime.year == now.year) {
    //   return roughTimeString;
    // }

    if (localDateTime.day == now.day && localDateTime.month == now.month && localDateTime.year == now.year) {
      return 'Today';
    }

    DateTime yesterday = now.subtract(Duration(days: 1));

    if (localDateTime.day == yesterday.day && localDateTime.month == yesterday.month && localDateTime.year == yesterday.year) {
      return 'Yesterday';
    }

    if (localDateTime.year != now.year) {
      return '${DateFormat('yMMMMd', locale).format(dateTime)}';
    }

    if (now.difference(localDateTime).inDays < 4) {
      String weekday = DateFormat('EEEE', locale).format(localDateTime);
      return '$weekday';
    }
    
    return '${DateFormat('MMMMd', locale).format(dateTime)}';
  }

  String renderTime(DateTime dateTime, {String type = 'jm', timeZone = 7}) {
    return DateFormat(type).format(dateTime.add(Duration(hours: timeZone)));
  }
}