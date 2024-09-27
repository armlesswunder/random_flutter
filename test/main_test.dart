import 'dart:convert';
import 'dart:io';

import 'package:random_app/model/my_json_utils.dart';
import 'package:random_app/model/utils.dart';
import 'package:test/test.dart';

void main() {
  test('display timestamp test', () {
    String time =
        getDisplayTimestamp(DateTime.fromMicrosecondsSinceEpoch(10000000));
    expect(time, '6:00 PM - 12/31');
  });

  test('2 test', () {
    //String time = getFileTimestamp(DateTime.now()
  });

  test('file timestamp test', () {
    //String time = getFileTimestamp(DateTime.now());

    String time = getFileTimestamp(DateTime.now());
    getFileTimestamp(DateTime.fromMicrosecondsSinceEpoch(10000000));
    expect(time, '20231114_090332');
  });

  test('asdf test', () {
    List<String> temp = [];
    List<int> list = [2, 3, 26, 31, 32, 50, 20, 41, 22, 23, 27];
    for (int i = 0; i < list.length; i++) {
      int count = list[i];
      String countStr = '${i}';
      if (countStr.length == 1) countStr = '0$countStr';
      String prefix = "S$countStr";
      for (int j = 0; j < count; j++) {
        String countStr1 = '${j + 1}';
        if (countStr1.length == 1) countStr1 = '0$countStr1';
        String suffix = ' E$countStr1';
        temp.add(prefix + suffix);
      }
    }
    for (int k = 0; k < temp.length; k++) {
      String s = temp[k];
      print(s);
    }
  });

  test('toJson conversion test', () {
    List<Map<String, dynamic>> temp = [];
    List<String> list = ['foo', 'bar', 'baz'];
    for (int i = 0; i < list.length; i++) {
      temp.add({"description": list[i]});
    }
    var outFile = File('C:\\Users\\000ab\\Documents\\random_data\\out.txt');
    if (!outFile.existsSync()) {
      outFile.createSync();
    }
    outFile.writeAsStringSync(JsonUtils.getPrettyPrintJson(jsonEncode(temp)));
  });
}
