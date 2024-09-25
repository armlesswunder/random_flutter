import 'dart:async';

import 'package:random_app/model/display_item.dart';
import 'package:random_app/model/prefs.dart';
import 'package:random_app/model/utils.dart';

import 'data.dart';

void getAuditData() {
  var audit = prefs.getString('${defaultFile}_auditData') ?? '';
  auditData.clear();
  if (audit.isNotEmpty) {
    var data = audit.split(';');
    data = data.map((e) {
      var file = DisplayItem(defaultFile).getDisplayData();
      var str = '$e:${file}';
      return str;
    }).toList();
    auditData.addAll(data);
  }
  auditData.removeWhere((element) => element.isEmpty || !element.contains(':'));

  auditData.removeWhere((element) => element.startsWith(':'));
}

List<String> getAllAuditData() {
  List<String> tmp = [];
  var arr = getFilteredLists().map((e) => e.trueData).toList();
  for (var list in arr) {
    var audit = prefs.getString('${list}_auditData') ?? '';
    auditData.clear();
    if (audit.isNotEmpty) {
      var data = audit.split(';');
      data =
          data.map((e) => '$e:${DisplayItem(list).getDisplayData()}').toList();
      tmp.addAll(data);
    }
    tmp.removeWhere((element) => element.isEmpty || !element.contains(':'));
    tmp.removeWhere((element) => element.startsWith(':'));
  }
  return tmp;
}

Future saveAuditData() async {
  String auditStr = '';

  auditData.removeWhere((element) => element.startsWith(':'));
  for (String str in auditData) {
    auditStr += '$str;';
  }
  await prefs.setString('${defaultFile}_auditData', auditStr);
}

Future addAuditData(
    String toAdd, bool isChecking, bool value, int position) async {
  auditData.removeWhere((element) => element.startsWith(':'));
  while (auditData.length >= 25) {
    auditData.removeAt(0);
  }
  auditData.add('$toAdd:${getTimestamp()}:$isChecking:$value:$position');
  await saveAuditData();
}

void removeLastAudit() {
  int latestTime = 0;
  int latestIndex = 0;
  int i = 0;
  for (String str in auditData) {
    var arr = str.split(':');
    var t = int.parse(arr[1]);
    if (latestTime == 0 || t < latestTime) {
      latestTime = t;
      latestIndex = i;
    }
    i++;
  }
  auditData.removeAt(latestIndex);
}
