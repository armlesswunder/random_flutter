import 'dart:io';

import 'package:flutter/material.dart';

import '../../../model/data.dart';
import '../../../model/file.dart';
import '../../../model/utils.dart';
import '../../../view/theme.dart';
import 'header.dart';

List<int> list = [];
//List<int> list = [2, 3, 26, 31, 32, 50, 20, 41, 22, 23, 27];

TextEditingController showNameController = TextEditingController();

Widget buildEpisodesScreen(BuildContext context, StateSetter state) {
  List<Widget> seasons = [];
  for (int i = 0; i < list.length; i++) {
    var controller = TextEditingController();
    int count = list[i];
    int season = i;
    controller.text = '$count';
    seasons.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text('Season $season: Episodes: '),
            SizedBox(
                height: 40,
                width: 60,
                child: TextField(
                  onTap: () => controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: controller.value.text.length),
                  style:
                      TextStyle(color: darkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: darkMode ? Colors.white60 : Colors.black54),
                    ),
                    hintStyle: TextStyle(
                        color: darkMode ? Colors.white60 : Colors.black54),
                    filled: true,
                    fillColor: !darkMode ? Colors.white : dialogColor,
                  ),
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (str) {
                    try {
                      int newVal = int.parse(str);
                      list[i] = newVal;
                    } catch (e) {
                      print(e);
                    }
                  },
                )),
            Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: TextButton(
                    onPressed: () {
                      list.removeAt(i);
                      state(() {});
                    },
                    child: const Text('Remove',
                        style: TextStyle(color: Colors.white70))))
          ],
        )));
  }

  return SingleChildScrollView(
      child: Column(children: [
    buildSettingsHeader(context, state),
    Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
              child: TextField(
            style: TextStyle(color: darkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: darkMode ? Colors.white60 : Colors.black54),
              ),
              hintStyle:
                  TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
              hintText: 'Name',
              filled: true,
              fillColor: !darkMode ? Colors.white : dialogColor,
            ),
            controller: showNameController,
          )),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: IconButton(
                  onPressed: () {
                    list.add(0);
                    state(() {});
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white70,
                  ))),
        ])),
    ...seasons,
    Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.all(Radius.circular(12))),
        child: TextButton(
            onPressed: () {
              generateEpisodes();
              state(() {});
            },
            child: const Text('Generate Episodes',
                style: TextStyle(color: Colors.white70))))
  ]));
}

void generateEpisodes() async {
  List<String> temp = [];
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
  String text = '';
  for (int k = 0; k < temp.length; k++) {
    String str = temp[k];
    text += '$str\n';
  }

  if (isAndroid()) {
    var fileName = '$defaultDir/${getShowName()}'.replaceAll(' ', '_');
    unselectAllLists();
    await importFile(fileName, text);
  } else {
    var fileName = '$defaultDir${Platform.pathSeparator}${getShowName()}'
        .replaceAll(' ', '_');
    unselectAllLists();
    await importFile(fileName, text);
  }
}

String getShowName() {
  return showNameController.text.isEmpty
      ? "${getFileTimestamp(DateTime.now())}.txt"
      : "${showNameController.text.trim()}.txt";
}
