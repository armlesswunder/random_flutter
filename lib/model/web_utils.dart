import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:random_app/model/data.dart';
import 'package:random_app/model/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'display_item.dart';

var webFiles = ['simple_example.txt', 'complex_example.json'];

Future<FilePickerResult?> pick() {
  return FilePicker.platform.pickFiles(
    allowMultiple: true,
    allowedExtensions: ['txt', 'json', 'zip'],
    type: FileType.custom,
  );
}

Future<void> webFilePicker() async {
  var file = await pick();
  var res = file?.files;

  for (PlatformFile wf in res ?? []) {
    if (wf.name.contains('.zip')) {
      final archive = ZipDecoder().decodeBytes(wf.bytes!);
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          var newPath = filename;
          print(newPath);
          var res2 = String.fromCharCodes(data);

          await prefs.setString(filename, res2);
          if (!filename.endsWith('_cb')) {
            listList.add(DisplayItem(filename));
          }
        }
      }
    } else {
      var res2 = String.fromCharCodes(wf.bytes!);

      await prefs.setString(wf.name, res2);
      listList.add(DisplayItem(wf.name));
    }
  }
  setWebFiles();
  await initWebFiles();
  updateViews();
}

Future<void> setWebFiles() async {
  var str = listList
      .map((e) => e.trueData)
      .toList()
      .reduce((value, element) => '$value<sep/>$element');
  await prefs.setString('webFiles', str);
}

List<String> getWebFiles() {
  String ret = prefs.getString('webFiles') ?? '';
  List<String> temp = ret.split('<sep/>');
  if (temp.first.isEmpty) {
    temp = List.of(webFiles);
  }
  return temp;
}

Future<void> initWebFiles() async {
  listList = [];
  prefs = await SharedPreferences.getInstance();
  for (String webFile in getWebFiles()) {
    if (prefs.getString(webFile) == null) {
      try {
        var str = await rootBundle.loadString('presets/$webFile');
        prefs.setString(webFile, str);
      } catch (e) {
        print('No data found for $webFile');
      }
    }
    listList.add(DisplayItem(webFile));
  }
}
