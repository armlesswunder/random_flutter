import 'dart:convert';
import 'dart:io' show Directory, File, HttpClient, HttpClientRequest, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:json_text_field/json_text_field.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_app/model/number_ext.dart';
import 'package:random_app/model/prefs.dart';
import 'package:random_app/model/web_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view/theme.dart';
import '../widget/page/settings/random.dart';
import 'audit.dart';
import 'data.dart';
import 'display_item.dart';
import 'file.dart';

String getDisplayTimestamp(DateTime time) {
  var formatter = DateFormat('h:mm a - MM/dd');
  var stringDate = formatter.format(time);
  return stringDate;
  //return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
}

String getFileTimestamp(DateTime time) {
  var formatter = DateFormat('yyyyMMdd_HHmmss');
  var stringDate = formatter.format(time);
  return stringDate;
  //return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
}

extension StrExt on String {
  String getFileName({bool removeExtension = true}) {
    if (contains(Platform.pathSeparator)) {
      var arr = split(Platform.pathSeparator);
      var str = arr[arr.length - 1];
      if (removeExtension && str.contains('.')) {
        str = str.substring(0, str.lastIndexOf('.'));
      }
      return str;
    }
    return this;
  }

  /// Maps advanced string formatting in a string to display item format
  String get asf {
    return trim()
        .replaceAll('.', '<period>')
        .replaceAll(',', '<comma>')
        .replaceAll('\n', '<nl>')
        .replaceAll('|', '<vert_bar>');
  }
}

void showSnackbarMsg(BuildContext context, String txt) {
  var snackBar = SnackBar(content: Text(txt));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

String decodeString(String tmp) {
  String tempStr = tmp;
  tempStr = tempStr.replaceAll('<nl>', '\n');
  tempStr = tempStr.replaceAll('<period>', '.');
  tempStr = tempStr.replaceAll('<comma>', ',');
  return tempStr;
}

void loadAssets() async {
  guideTxt = await loadAsset('assets/guide.txt');
}

Future<String> loadAsset(String path) async {
  return await rootBundle.loadString(path);
}

Future<void> showConfirmDialog(BuildContext context, Function? callback,
    {String title = 'Confirm', String content = '', Widget? child}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
          backgroundColor: Colors.grey.shade900,
          child: Column(children: [
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 24),
            ),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: child ??
                        SingleChildScrollView(
                          child: Column(
                            children: [Text(content)],
                          ),
                        ))),
            const SizedBox(height: 8),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (callback != null)
                      TextButton(
                        child: const Text('OK',
                            style: TextStyle(color: Colors.white70)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          callback.call();
                        },
                      ),
                    TextButton(
                      child: Text(callback != null ? 'Cancel' : 'OK',
                          style: const TextStyle(color: Colors.white70)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                )),
            const SizedBox(height: 16),
          ]));
    },
  );
}

bool jsonWorks = true;
late void Function(void Function()) jsonWorksState;

Dialog buildAdvancedDialog(DisplayItem displayItem, int index) {
  var displayItem = displayList[index];
  String oldText = displayList[index].trueData;
  jsonWorks = true;
  return Dialog(
      backgroundColor: darkMode ? dialogColor : Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: StatefulBuilder(builder: (BuildContext context, state) {
        return SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  displayList.remove(displayItem);
                  writeFile();
                  mainState!(() {});
                  state(() {});
                  Navigator.pop(context);
                }),
            TextButton(
                child: const Text(
                  'Move Up',
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: () async {
                  var d = displayList.removeAt(index);
                  displayList.insert(0, d);
                  addAuditData(d.getDisplayData(), false, false, index);
                  mainState!(() {});
                  state(() {});
                  writeFile();
                  Navigator.pop(context);
                }),
            TextButton(
                child: const Text(
                  'Randomize',
                  style: TextStyle(color: Colors.purple),
                ),
                onPressed: () async {
                  var i = next(0, displayList.length);
                  var d = displayList.removeAt(index);
                  displayList.insert(i, d);
                  addAuditData(d.getDisplayData(), false, false, index);
                  mainState!(() {});
                  writeFile();
                  Navigator.pop(context);
                }),
            if (displayItem.isJson)
              StatefulBuilder(builder: (BuildContext context,
                  void Function(void Function()) sState) {
                jsonWorksState = sState;
                return TextButton(
                    child: Text(
                      'JSON Beautify',
                      style: TextStyle(
                          color: jsonWorks ? Colors.orangeAccent : Colors.red),
                    ),
                    onPressed: () async {
                      jsonController.formatJson(sortJson: false);
                    });
              }),
            Row(children: [
              Expanded(
                  child: displayItem.isJson
                      ? JsonTextField(
                          commonTextStyle: TextStyle(color: Colors.white70),
                          stringHighlightStyle:
                              TextStyle(color: Colors.white70),
                          obscureText: false,
                          maxLines: null,
                          style: TextStyle(
                              color: darkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: darkMode
                                      ? Colors.white60
                                      : Colors.black54),
                            ),
                            hintStyle: TextStyle(
                                color:
                                    darkMode ? Colors.white60 : Colors.black54),
                            hintText: 'Name',
                            filled: true,
                            fillColor: !darkMode ? Colors.white : dialogColor,
                          ),
                          controller: jsonController
                            ..text = jsonEncode(displayList[index].map),
                          onChanged: (text) {
                            var displayItem = displayList[index];
                            if (displayItem.isJson) {
                              jsonWorks = false;
                              jsonWorksState(() {});
                              jsonController.formatJson(sortJson: false);
                              displayItem.map = jsonDecode(jsonController.text);
                              displayList[index].trueData = jsonController.text;
                              jsonWorks = true;
                              jsonWorksState(() {});
                            } else {
                              displayList[index].trueData = text;
                            }
                          })
                      : TextField(
                          obscureText: false,
                          maxLines: null,
                          style: TextStyle(
                              color: darkMode ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: darkMode
                                      ? Colors.white60
                                      : Colors.black54),
                            ),
                            hintStyle: TextStyle(
                                color:
                                    darkMode ? Colors.white60 : Colors.black54),
                            hintText: 'Name',
                            filled: true,
                            fillColor: !darkMode ? Colors.white : dialogColor,
                          ),
                          controller: controller
                            ..text = displayList[index].trueData,
                          onChanged: (text) {
                            var displayItem = displayList[index];
                            if (displayItem.isJson) {
                              displayItem.map = jsonDecode(text);
                              displayList[index].trueData = text;
                            } else {
                              displayList[index].trueData = text;
                            }
                          })),
              IconButton(
                icon: Icon(
                  Icons.copy,
                  color: darkMode ? Colors.white70 : Colors.black87,
                ),
                tooltip: 'Copy',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: controller.text));
                },
              )
            ]),
            TextButton(
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.blue),
                ),
                onPressed: () {
                  if (checkedItems
                      .contains(displayList[index].getCheckedItem())) {
                    checkedItems.remove(displayList[index].getCheckedItem());
                    checkedItems.add(displayList[index].getCheckedItem());
                  }
                  writeFile();
                  mainState!(() {});
                  state(() {});
                  Navigator.pop(context);
                }),
          ],
        ));
      }));
}

Future<void> setupDefaultDirs() async {
  if (isMobile()) {
    var value = await getExternalStorageDirectory();
    if (!value!.existsSync()) {
      value.createSync();
    }
    assetDir = '${value.path}${Platform.pathSeparator}assets';
    cacheDir = '${value.path}${Platform.pathSeparator}cache';
    if (!Directory(assetDir).existsSync()) {
      Directory(assetDir).createSync(recursive: true);
    }
    if (!Directory(cacheDir).existsSync()) {
      Directory(cacheDir).createSync(recursive: true);
    }
  }
  if (isDesktop()) {
    var value = await getApplicationDocumentsDirectory();
    assetDir =
        '${value.path}${Platform.pathSeparator}random_data${Platform.pathSeparator}assets';
    cacheDir =
        '${value.path}${Platform.pathSeparator}random_data${Platform.pathSeparator}cache';
    if (!Directory(assetDir).existsSync()) {
      Directory(assetDir).createSync(recursive: true);
    }
    if (!Directory(cacheDir).existsSync()) {
      Directory(cacheDir).createSync(recursive: true);
    }
  }
  if (isWeb()) {
    try {
      prefs = await SharedPreferences.getInstance();
      listList = [];
      await initWebFiles();
      if (urlRoute.isNotEmpty &&
          listList.any((element) => element.trueData == urlRoute)) {
        defaultFile = urlRoute;
      } else {
        defaultFile = prefs.getString('defaultFile') ?? webFiles[0];
      }
      listIndex = getSelectedListIndexForTabs();
      historyList.add(listIndex);
    } catch (e) {
      print(e);
    }
    if (isWebMode) {
      await loadDirectory();
    }
    await loadFile(defaultFile);
    mainState!(() {});
  }
}

Widget buildContainer(Widget child,
    {double ph = 8,
    double pv = 8,
    double mh = 8,
    double mv = 8,
    Color color = Colors.white10}) {
  return Container(
      decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(12))),
      margin: EdgeInsets.symmetric(horizontal: mh.ds, vertical: mv.ds),
      padding: EdgeInsets.symmetric(horizontal: ph.ds, vertical: pv.ds),
      child: child);
}

int getTimestamp() {
  return DateTime.now().millisecondsSinceEpoch;
}

bool isMobile() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isAndroid || Platform.isIOS;
}

bool isDesktop() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isMacOS || Platform.isWindows;
}

bool isWeb() {
  return kIsWeb;
}

bool isAndroid() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isAndroid;
}

bool isWindows() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isWindows;
}
