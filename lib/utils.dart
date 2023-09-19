import 'package:intl/intl.dart';

String getDisplayTimestamp(DateTime time) {
  var formatter = DateFormat('h:mm a - MM/dd');
  var stringDate = formatter.format(time);
  return stringDate;
  //return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
}

int getTimestamp() {
  return DateTime.now().millisecondsSinceEpoch;
}
