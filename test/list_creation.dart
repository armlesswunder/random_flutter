import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:random_app/model/my_json_utils.dart';
import 'package:test/test.dart';

void main() {
  test('persona4 social links checkbox info items addition', () async {
    WidgetsFlutterBinding.ensureInitialized();
    var ps = '\\';
    String documentsDir = 'C:\\Users\\000ab\\Documents';
    String inputFilePath = '$documentsDir\\random_data\\inputFiles';
    String outputFilePath = '$documentsDir\\random_data\\outputFiles';
    var inDir = Directory(inputFilePath);
    var outDir = Directory(outputFilePath);

    for (FileSystemEntity file in inDir.listSync(recursive: true)) {
      try {
        List<Map<String, dynamic>> temp = [];
        List<String> list = File(file.path).readAsLinesSync();
        for (int i = 0; i < list.length; i++) {
          temp.add({"description": list[i], "selected": false});
        }

        var fileName = file.path.replaceAll(inputFilePath, '');
        var outFile = File('${outDir.path}$fileName');
        if (!outFile.existsSync()) {
          outFile.createSync(recursive: true);
        }
        var jsonList = JsonUtils.getPrettyPrintJson(jsonEncode(temp));
        String content = "\"info_list\": $jsonList";
        outFile.writeAsStringSync(content);
      } catch (e) {
        print(e);
      }
    }
  });
  test('palia gifts conversion', () async {
    WidgetsFlutterBinding.ensureInitialized();
    var ps = '\\';
    String documentsDir = 'C:\\Users\\000ab\\Documents';
    String inputFilePath = '$documentsDir\\random_data\\inputFiles';
    String outputFilePath = '$documentsDir\\random_data\\outputFiles';
    var inDir = Directory(inputFilePath);
    var outDir = Directory(outputFilePath);

    for (FileSystemEntity file in inDir.listSync(recursive: true)) {
      try {
        List<Map<String, dynamic>> temp = [];
        List<String> list = File(file.path).readAsLinesSync();
        String content = "";
        for (int i = 0; i < list.length; i++) {
          var str = list[i];
          var arr = str.split(';');
          var pre = arr[0].split(',');
          var sec = arr[1].split(',');
          temp.add({
            "name": '${pre[0]} ${pre[1].toLowerCase()}',
            "image": '\\palia\\items\\${pre[0].toLowerCase()}.webp'
          });
          for (String vil in sec) {
            temp.add({
              "name": vil,
              "image": '\\palia\\villagers\\${vil.toLowerCase()}.webp'
            });
          }

          var jsonList = JsonUtils.getPrettyPrintJson(jsonEncode(temp));
          content += "{\"desc_list\": $jsonList},";
          temp.clear();
        }

        var fileName = file.path.replaceAll(inputFilePath, '');
        var outFile = File('${outDir.path}$fileName');
        if (!outFile.existsSync()) {
          outFile.createSync(recursive: true);
        }
        outFile.writeAsStringSync(content);
      } catch (e) {
        print(e);
      }
    }
  });
}
