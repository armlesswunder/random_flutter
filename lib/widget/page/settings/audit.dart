import 'dart:io';

import 'package:flutter/material.dart';
import 'package:random_app/model/display_item.dart';

import '../../../model/audit.dart';
import '../../../model/data.dart';
import '../../../model/file.dart';
import '../../../model/utils.dart';
import '../../../view/theme.dart';

bool auditCurrent = true;

class AuditPage extends StatefulWidget {
  const AuditPage({Key? key}) : super(key: key);

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> tempData = [];
    List<String> tempArr = [];
    for (var d in displayList) {
      tempArr.add(d.getDisplayData());
    }
    getAuditData();

    for (String str in auditCurrent ? auditData : getAllAuditData()) {
      var s = str.split(':');
      //if (!auditCurrent || tempArr.contains(s.first)) {
      var map = {'name': s[0], 'time': s[1]};
      try {
        map['isCheckedData'] = s[2];
      } catch (e) {}
      try {
        map['checked'] = s[3];
      } catch (e) {}
      try {
        map['position'] = s[4];
      } catch (e) {}
      try {
        map['file'] = s[5];
      } catch (e) {}
      tempData.add(map);
      //}
    }
    tempData.sort((a, b) {
      return b['time'].compareTo(a['time']);
    });
    return Scaffold(
        appBar: AppBar(title: const Text('Audit')),
        body: Column(children: [
          Row(
            children: [
              Expanded(
                  child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: TextField(
                  focusNode: auditFocus,
                  onTapOutside: (e) {
                    mainFocus.requestFocus();
                  },
                  style:
                      TextStyle(color: darkMode ? Colors.white : Colors.black),
                  controller: _controller,
                  onChanged: (v) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(14),
                    isDense: true,
                    filled: true,
                    fillColor: darkMode ? Colors.white24 : Colors.black26,
                    hintText: 'Search',
                    hintStyle: TextStyle(
                        color: darkMode ? Colors.white : Colors.black),
                    prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.search,
                          color: darkMode ? Colors.white : Colors.black,
                        )),
                    suffixIcon: IconButton(
                      padding: const EdgeInsets.only(right: 16),
                      onPressed: () {
                        _controller.text = '';
                        setState(() {});
                      },
                      icon: Icon(Icons.clear,
                          color: darkMode ? Colors.white : Colors.black),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(48.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              )),
              Text('Audit current: '),
              Checkbox(
                  value: auditCurrent,
                  onChanged: (b) {
                    auditCurrent = !auditCurrent;
                    setState(() {});
                  })
            ],
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: tempData.length,
                  itemBuilder: (BuildContext context, int index) {
                    String s = 'Invalid';
                    String t = 'Invalid';
                    bool isCheckedData = false;
                    bool checked = false;
                    int pos = -1;
                    String list = defaultFile;
                    try {
                      s = tempData[index]['name'];
                      DateTime time = DateTime.fromMicrosecondsSinceEpoch(
                          int.parse(tempData[index]['time']) * 1000);
                      t = getDisplayTimestamp(time);
                      isCheckedData =
                          bool.parse(tempData[index]['isCheckedData']);
                      checked = bool.parse(tempData[index]['checked']);
                      pos = int.parse(tempData[index]['position']);
                      list = tempData[index]['file'];
                      list = getFilteredLists()
                          .firstWhere(
                              (element) => element.getDisplayData() == list)
                          .trueData;
                    } catch (e) {}
                    //return Text(
                    //  s,
                    //  style: TextStyle(color: Colors.white),
                    //);
                    return !s
                            .toLowerCase()
                            .trim()
                            .contains(_controller.text.toLowerCase().trim())
                        ? Container()
                        : Container(
                            decoration: BoxDecoration(
                                color:
                                    !darkMode ? Colors.black12 : Colors.white10,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(12))),
                            margin: const EdgeInsets.fromLTRB(12.0, 4, 12, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(children: [
                                    Container(
                                        padding: const EdgeInsets.all(8.0),
                                        //child: Center(child: Text('${index + 1} $s')),
                                        child: Center(child: Text(s))),
                                    auditCurrent
                                        ? Container()
                                        : Container(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Center(
                                                child: Text(
                                                    DisplayItem(list)
                                                        .getDisplayData(),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.white38)))),
                                  ]),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: Text(t),
                                    ),
                                  ),
                                ),
                                isCheckedData
                                    ? Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: StatefulBuilder(builder:
                                                (BuildContext context,
                                                    StateSetter cbState) {
                                              return Checkbox(
                                                value: checked,
                                                onChanged: (v) {
                                                  var checkedItems = [];
                                                  var checkFilePath =
                                                      getCheckedFilePath(
                                                          filePath: list);
                                                  checkedItems.addAll(
                                                      File(checkFilePath)
                                                          .readAsStringSync()
                                                          .split('\n'));

                                                  var foundIndex = checkedItems
                                                      .indexWhere((element) =>
                                                          DisplayItem(element)
                                                              .getDisplayData() ==
                                                          s);
                                                  if (foundIndex != -1) {
                                                    var tmp = checkedItems[
                                                        foundIndex];
                                                    if (v != null && v) {
                                                      checkedItems.add(tmp);
                                                    } else {
                                                      checkedItems.remove(tmp);
                                                    }
                                                    var checkFilePath =
                                                        getCheckedFilePath(
                                                            filePath: list);
                                                    String str = checkedItems
                                                        .reduce((value,
                                                                element) =>
                                                            '$value\n$element');
                                                    File(checkFilePath)
                                                        .writeAsStringSync(str);
                                                    cbState(() {});
                                                    showSnackbarMsg(context,
                                                        'Reverted checkbox value');
                                                    load(defaultFile).then(
                                                        (value) =>
                                                            mainState!(() {}));
                                                  } else {
                                                    var data = File(list)
                                                        .readAsLinesSync();
                                                    foundIndex = data
                                                        .indexWhere((element) =>
                                                            DisplayItem(element)
                                                                .getDisplayData() ==
                                                            s);
                                                    var tmp = data[foundIndex];
                                                    checkedItems.add(tmp);
                                                    var checkFilePath =
                                                        getCheckedFilePath(
                                                            filePath: list);
                                                    String str = checkedItems
                                                        .reduce((value,
                                                                element) =>
                                                            '$value\n$element');
                                                    File(checkFilePath)
                                                        .writeAsStringSync(str);
                                                    cbState(() {});
                                                    showSnackbarMsg(context,
                                                        'Reverted checkbox value');
                                                    load(defaultFile).then(
                                                        (value) =>
                                                            mainState!(() {}));
                                                  }
                                                },
                                              );
                                            }),
                                          ),
                                        ),
                                      )
                                    : Expanded(
                                        flex: 2,
                                        child: Container(
                                          width: 40,
                                          child: IconButton(
                                            icon: const Icon(Icons.undo),
                                            onPressed: () {
                                              if (pos != -1) {
                                                var data = File(list)
                                                    .readAsLinesSync();
                                                var foundIndex =
                                                    data.indexWhere((element) =>
                                                        DisplayItem(element)
                                                            .getDisplayData()
                                                            .trim() ==
                                                        s.trim());
                                                if (foundIndex != -1) {
                                                  var tmp = data[foundIndex];
                                                  data.remove(tmp);
                                                  data.insert(pos, tmp);
                                                  File(list).writeAsStringSync(
                                                      data.reduce((value,
                                                              element) =>
                                                          '$value\n$element'));
                                                  showSnackbarMsg(context,
                                                      'Reverted change at $pos');
                                                  load(defaultFile).then(
                                                      (value) =>
                                                          mainState!(() {}));
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                              ],
                            ));
                  })),
        ]));
  }
}
