import 'dart:async';

import 'package:random_app/model/prefs.dart';
import 'package:random_app/utils.dart';

import 'data.dart';

void getAuditData() {
  var audit = prefs.getString('auditData') ?? '';
  if (audit.isNotEmpty) {
    auditData = audit.split(';');
  }
  auditData.removeWhere((element) => element.isEmpty || !element.contains(':'));
}

Future saveAuditData() async {
  String auditStr = '';
  for (String str in auditData) {
    auditStr += '$str;';
  }
  await prefs.setString('auditData', auditStr);
}

Future addAuditData(String toAdd) async {
  while (auditData.length >= 25) {
    auditData.removeAt(0);
  }
  auditData.add('$toAdd:${getTimestamp()}');
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
