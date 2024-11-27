import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:random_app/model/my_json_utils.dart';
import 'package:random_app/model/utils.dart';
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

  test('persona5 to json items', () async {
    WidgetsFlutterBinding.ensureInitialized();
    var ps = '\\';
    String documentsDir = 'C:\\Users\\000ab\\Documents';
    String inputFilePath = '$documentsDir\\random_data\\inputFiles';
    String outputFilePath = '$documentsDir\\random_data\\outputFiles';
    var inDir = Directory(inputFilePath);
    var outDir = Directory(outputFilePath);

    List<Map<String, dynamic>> temp = [];
    for (FileSystemEntity file in inDir.listSync(recursive: true)) {
      Map<String, dynamic> obj = {};
      List<Map<String, dynamic>> descList = [];
      try {
        List<String> list = File(file.path).readAsLinesSync();
        String first = list.first;
        List<String> firstParts = first.split(' - ');
        String name = firstParts.last;
        String sign = firstParts.first;
        String title = name + ": " + sign;

        String headerAbilities = 'Confidant Abilities:';
        String headerSchedules = 'Schedule';
        String headerProgression = 'Rank Up Progression';
        String headerGiftGuide = 'Gift Guide';
        String headerBonus = 'Bonus Events';

        obj['name'] = title;
        obj['searchable'] = title;
        obj['image'] = '\\persona5\\$name.png';

        Map<String, List<String>> map = {};
        map[headerAbilities] = [];
        map[headerSchedules] = [];
        map[headerProgression] = [];
        map[headerGiftGuide] = [];
        map[headerBonus] = [];

        String currentHeader = '';
        for (String line in list) {
          if (line.trim().isEmpty) continue;
          if (line.trim().startsWith(headerAbilities)) {
            currentHeader = headerAbilities;
            continue;
          }
          if (line.trim().startsWith(headerSchedules)) {
            currentHeader = headerSchedules;
            continue;
          }
          if (line.trim().startsWith(headerProgression)) {
            currentHeader = headerProgression;
            continue;
          }
          if (line.trim().startsWith(headerGiftGuide)) {
            currentHeader = headerGiftGuide;
            continue;
          }
          if (line.trim().startsWith(headerBonus)) {
            currentHeader = headerBonus;
            continue;
          }

          if (currentHeader == headerAbilities) {
            map[currentHeader]?.add(line);
          }
          if (currentHeader == headerSchedules) {
            map[currentHeader]?.add(line);
          }
          if (currentHeader == headerProgression) {
            map[currentHeader]?.add(line);
          }
          if (currentHeader == headerGiftGuide) {
            map[currentHeader]?.add(line);
          }
          if (currentHeader == headerBonus) {
            map[currentHeader]?.add(line);
          }
        }

        try {
          descList.add({
            "description": map[headerSchedules]
                ?.reduce((value, element) => value.asf + '<nl>' + element.asf)
          });
        } catch (e) {}

        int rank = 0;
        String strRank = '';
        Map<int, String> progresMap = {};
        for (String line in map[headerProgression]!) {
          String first = line[0];
          try {
            rank = int.parse(first);
            if (strRank.isNotEmpty) {
              progresMap[rank - 1] = strRank;
              print(strRank);
              descList.add({"description": strRank, "selected": false});
              strRank = '';
            }
            strRank += '${line.asf}<nl>';
          } catch (e) {
            strRank += '${line.asf}<nl>';
          }
          // TODO fix this
          List<String>? list = map[headerProgression];
          if (list?.last == line) {
            progresMap[rank - 1] = strRank;
            descList.add({"description": strRank, "selected": false});
          }
        }

        try {
          descList.add({
            "description": map[headerGiftGuide]
                ?.reduce((value, element) => value.asf + '<nl>' + element.asf)
          });
        } catch (e) {}
        try {
          descList.add({
            "description": map[headerBonus]
                ?.reduce((value, element) => value.asf + '<nl>' + element.asf)
          });
        } catch (e) {}
        try {
          descList.add({
            "description": map[headerAbilities]
                ?.reduce((value, element) => value.asf + '<nl>' + element.asf)
          });
        } catch (e) {}
        obj["info_list"] = descList;
      } catch (e) {
        print(e);
      }
      temp.add(obj);
    }

    var fileName = '\\final.json';
    var outFile = File('${outDir.path}$fileName');
    if (!outFile.existsSync()) {
      outFile.createSync(recursive: true);
    }

    //String? content =
    //    map[headerAbilities]?.reduce((l1, l2) => l1 + '\n' + l2);
//
    //outFile.writeAsStringSync(content!);

    outFile.writeAsStringSync(JsonUtils.getPrettyPrintJson(jsonEncode(temp)));
  });

  test('persona5 relationships to independent files', () async {
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
        List<String> list = File(file.path).readAsStringSync().split('<sep>');
        for (String item in list) {
          if (item.isEmpty) continue;
          List<String> lines =
              item.trim().split('\n').map((e) => e.trim()).toList();
          String id = lines.first;
          String newItem =
              lines.reduce((value, element) => value + '\n' + element);
          var fileName = outputFilePath + '\\' + id + '.txt';
          var outFile = File('$fileName');
          if (!outFile.existsSync()) {
            outFile.createSync(recursive: true);
          }
          outFile.writeAsStringSync(newItem);
        }
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
  test('ssbm bonus conversion', () async {
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
          var str = list[i];
          var arr = str.split('\t');
          var bonusName = arr[0];
          var points = arr[1];
          var bonusDescription = arr[2].replaceAll('"', '');

          temp.add({"name": bonusName, "description": bonusDescription});
        }

        var fileName = file.path.replaceAll(inputFilePath, '');
        var outFile = File('${outDir.path}$fileName');
        if (!outFile.existsSync()) {
          outFile.createSync(recursive: true);
        }
        outFile
            .writeAsStringSync(JsonUtils.getPrettyPrintJson(jsonEncode(temp)));
      } catch (e) {
        print(e);
      }
    }
  });
  test('palia fish conversion', () async {
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
          var str = list[i];
          var arr = str.split('\t');
          var name = arr[0].replaceAll('"', '').trim();
          var description = arr[1].replaceAll('"', '').trim();
          var rarity = arr[2].replaceAll('"', '').trim();
          var location = arr[3].replaceAll('"', '').trim();
          var times = arr[4].replaceAll('"', '').trim();
          var bait = arr[5].replaceAll('"', '').trim();
          var value = arr[6].replaceAll('"', '').trim();
          var starValue = arr[7].replaceAll('"', '').trim();
          var neededFor = arr[8].replaceAll('"', '').trim();
          var nf = neededFor.trim().isEmpty ? '' : ', Uses: $neededFor';
          var ig = '65px-${name.replaceAll(' ', '_')}';
          var img = '\\palia\\fish\\$ig.png';

          temp.add({
            "name": name,
            "description": "$location, $times$nf",
            "image": img,
            "info":
                "$rarity\n$location\n$description\nBait: $bait\n$value/$starValue"
          });
        }

        var fileName = file.path.replaceAll(inputFilePath, '');
        var outFile = File('${outDir.path}$fileName');
        if (!outFile.existsSync()) {
          outFile.createSync(recursive: true);
        }
        outFile
            .writeAsStringSync(JsonUtils.getPrettyPrintJson(jsonEncode(temp)));
      } catch (e) {
        print(e);
      }
    }
  });
  test('palia insect conversion', () async {
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
          var str = list[i];
          var arr = str.split('\t');
          var name = arr[0].replaceAll('"', '').trim();
          var description = arr[1].replaceAll('"', '').trim();
          var rarity = arr[2].replaceAll('"', '').trim();
          var location = arr[3].replaceAll('"', '').trim();
          var times = arr[4].replaceAll('"', '').trim();
          var behavior = arr[5].replaceAll('"', '').trim();
          var value = arr[6].replaceAll('"', '').trim();
          var starValue = arr[7].replaceAll('"', '').trim();
          var ig = '65px-${name.replaceAll(' ', '_')}';
          var img = '\\palia\\insects\\$ig.png';

          temp.add({
            "name": name,
            "description": "$location, $times",
            "image": img,
            "info":
                "$rarity\n$location\n$description\nBehavior: $behavior\n$value/$starValue"
          });
        }

        var fileName = file.path.replaceAll(inputFilePath, '');
        var outFile = File('${outDir.path}$fileName');
        if (!outFile.existsSync()) {
          outFile.createSync(recursive: true);
        }
        outFile
            .writeAsStringSync(JsonUtils.getPrettyPrintJson(jsonEncode(temp)));
      } catch (e) {
        print(e);
      }
    }
  });
}
