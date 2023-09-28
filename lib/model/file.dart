import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_app/model/prefs.dart';
import 'package:share_plus/share_plus.dart';

import 'data.dart';
import 'display_item.dart';

void clearDefaultFile() {
  defaultFile = '';
  prefs.setString('defaultFile', '');
}

void deleteFile(String path) {
  File file = File(path);
  file.deleteSync();
}

Future load(String path) async {
  Directory d = Directory(path);
  if (d.existsSync()) {
    loadDirectory(directory: path);
  } else {
    await loadFile(path);
  }
}

Future loadFile(String path) async {
  if (path.isEmpty) return;

  try {
    await loadFileContents(path);
  } catch (err) {
    print(err);
  }
  String temp = path;
  if (Platform.isAndroid) {
    var arr = path.split('/');
    var s = arr[arr.length - 1];
    var st = '$androidDir/$s';
    st = st.replaceAll(' ', '_');
    File file = File(st);
    await writeFile(path: file.path);
    temp = file.path;
  }

  defaultFile = temp;
  prefs.setString("defaultFile", temp);
  useCheckboxes = prefs.getBool(useCheckboxesKey()) ?? false;
}

Future loadFileContents(String path) async {
  displayList.clear();
  File file = File(path);
  var s = file.openRead().map(utf8.decode);
  var str = '';
  await s.forEach((element) {
    str += element;
  });
  var fileList = str.split('\n');
  for (int i = 0; i < fileList.length; i++) {
    var element = fileList[i];
    if (element.trim().isEmpty) continue;
    var displayItem = DisplayItem(element);
    displayList.add(displayItem);
  }
}

Future writeFile({String? path}) async {
  File file = File(path ?? defaultFile);
  String tempStr = '';
  for (int i = 0; i < displayList.length; i++) {
    var element = displayList[i];
    tempStr += '${element.trueData}\n';
  }
  return file.writeAsString(tempStr);
}

String currentDir = '';

void loadDirectory({String directory = ''}) {
  listList.clear();
  if (directory.isNotEmpty) {
    currentDir = directory;
    Directory d = Directory(directory);
    var fileList = d.listSync();
    for (int i = 0; i < fileList.length; i++) {
      var element = fileList[i];
      var displayItem = DisplayItem(element.path);
      listList.add(displayItem);
    }
  } else if (defaultDir.isNotEmpty) {
    Directory d = Directory(defaultDir);
    var fileList = d.listSync();
    for (int i = 0; i < fileList.length; i++) {
      var element = fileList[i];
      var displayItem = DisplayItem(element.path);
      listList.add(displayItem);
    }
  }
  listList.sort((a, b) {
    return a
        .getDisplayData()
        .toLowerCase()
        .compareTo(b.getDisplayData().toLowerCase())
        .compareTo((b.isDirectory() ? 0 : 1));
  });
  listList.sort((a, b) {
    return (a.isDirectory() ? 0 : 1) - (b.isDirectory() ? 0 : 1);
  });
}

void moveToParentDirectory(BuildContext context) async {
  try {
    Directory currentDirectory = Directory(currentDir);
    if (currentDirectory.existsSync() && currentDirectory.parent.existsSync()) {
      currentDir = currentDirectory.parent.path;
      load(currentDir);
      updateViews();
    }
  } catch (e) {
    print(e);
  }
}

void openFile(BuildContext context, StateSetter state) async {
  final documentsDir = await getApplicationDocumentsDirectory();
  FilePickerResult? result =
      await FilePicker.platform.pickFiles(initialDirectory: documentsDir.path);
  if (result != null) {
    String? path = result.files.single.path;
    await loadFile(path!);
    loadDirectory();
    updateViews();
    state(() {});
  } else {
    // User canceled the picker
  }
}

Future importFile(String path, String data) async {
  if (path.isEmpty || data.isEmpty) return;
  File newFile = File(path);
  newFile.writeAsStringSync(data);

  defaultFile = path;
  await prefs.setString("defaultFile", path);

  //defaultFile = path;
  //prefs.setString("defaultFile", path);
  loadDirectory();
  findSelectedList();
  useCheckboxes = prefs.getBool(useCheckboxesKey()) ?? false;
}

void createFile(String path, BuildContext context, StateSetter state) async {
  await loadFile('$androidDir/${path.replaceAll(' ', '_')}');
  loadDirectory();
  updateViews();
  state(() {});
}

void chooseDefaultDir(BuildContext context) async {
  if (Platform.isAndroid) return;
  final documentsDir = await getApplicationDocumentsDirectory();
  String? selectedDirectory = await FilePicker.platform
      .getDirectoryPath(initialDirectory: documentsDir.path);

  if (selectedDirectory != null) {
    defaultDir = selectedDirectory;
    await prefs.setString('defaultDir', defaultDir);
    loadDirectory();
  }
}

Future<void> exportFile() async {
  if (Platform.isAndroid) {
    XFile xfile = XFile(defaultFile);
    if (useNotes) {
      DisplayItem displayItem = DisplayItem(defaultFile);
      String subject = displayItem.getDisplayData();
      String data = await xfile.readAsString();
      await Share.shareXFiles([xfile], subject: subject, text: data);
    } else {
      await Share.shareXFiles([xfile], text: 'Export Data');
    }
  }
}

void reloadFile(int index) async {
  defaultFile = listList[index].trueData;
  await prefs.setString("defaultFile", defaultFile);
  await writeFile();
  await loadFile(listList[index].trueData);
  updateViews();
}
