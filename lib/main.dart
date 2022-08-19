import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'List Master',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(title: 'List Master'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class DisplayItem {
  String trueData = '';
  String displayData = '';
  num index = -1;
  bool selected = false;

  DisplayItem(this.trueData, this.index) {
    Directory d = Directory(trueData);
    try {
      if (d.existsSync()) {
        displayData = d.path.split('\\').last;
      } else {
        displayData = trueData.split('\\').last;
      }
    } catch(e) {
      displayData = trueData.split('\\').last;
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<DisplayItem> displayList = [];
  List<DisplayItem> listList = [];
  late SharedPreferences prefs;
  String defaultDir = '';
  String defaultFile = '';

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    getSettings();
    loadDirectory();
    loadFile(defaultFile);
    setState(() {});
  }

  void getSettings() {
    defaultDir = prefs.getString('defaultDir') ?? '';
    defaultFile = prefs.getString('defaultFile') ?? '';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 0.0,
        ),
        body: Column(
          children: <Widget>[
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.list),
                        tooltip: 'Lists',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return getListScreen();
                            },
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return getSettingsScreen();
                            },
                          ));
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        tooltip: 'Shuffle',
                        onPressed: () {
                          shuffle();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.sort_by_alpha),
                        tooltip: 'Sort',
                        onPressed: () {
                          sort();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              key: UniqueKey(),
              child: RefreshIndicator(onRefresh: () {
                shuffle();
                return Future(() => null);
              },
              child: ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                        margin: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 9,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(displayList[index].displayData),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.move_down),
                                  tooltip: 'Move to Bottom',
                                  onPressed: () {
                                    var d = displayList.removeAt(index);
                                    displayList.add(d);
                                    setState(() {});
                                    writeFile();
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                    );
                  }
                )
              )
            )
          ],
        )
    );
  }

  void shuffle({bool writeChanges = true}) {
    displayList.shuffle();
    setState(() {});
    if (writeChanges) {
      writeFile();
    }
  }

  void sort({bool writeChanges = true}) {
    displayList.sort((a, b) {
      return a.displayData.toLowerCase().compareTo(b.displayData.toLowerCase());
    });
    setState(() {});
    if (writeChanges) {
      writeFile();
    }
  }

  Widget getSettingsScreen() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter state) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: Column(
            children: [],
          )
      );
    });
  }

  Widget getListScreen() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter state) {
      return Scaffold(
          appBar: AppBar(
            title: Text('Lists'),
          ),
          body: Column(
            children: [
              Row(children: [
                TextButton(
                    child: Text('Import List'),
                    onPressed: () {
                      openFile(context);
                      state((){});
                    }
                ),
                TextButton(
                    child: Text('Export List'),
                    onPressed: () {
                      openFile(context);
                      state((){});
                    }
                ),
                TextButton(
                    child: Text('Choose Default List'),
                    onPressed: () {
                      chooseDefaultDir(context);
                      state((){});
                    }
                )
              ]),
              Expanded(
                key: UniqueKey(),
                child: ListView.builder(
                    itemCount: listList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () async {
                          await load(listList[index].trueData);
                          listList[index].selected = !listList[index].selected;
                          setState(() {});
                          state((){});
                        },
                        child: Card(
                            margin: const EdgeInsets.all(4.0),
                            color: listList[index].selected ?
                            const Color.fromARGB(63, 255, 234, 0) :
                            const Color.fromARGB(210, 255, 255, 255),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: Text(listList[index].displayData),
                                    ),
                                  ),
                                ),
                              ],
                            )
                        ),
                      );
                    }
                ),
              )
            ],
          )
      );
    });
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

    displayList.clear();
    File file = File(path);
    var s = file.openRead().map(utf8.decode);
    var str = '';
    await s.forEach((element) {
      str += element;
    });
    var fileList = str.split('\n');
    for(int i = 0; i < fileList.length; i++) {
      var element = fileList[i];
      if (element.trim().isEmpty) continue;
      var displayItem = DisplayItem(element, i);
      displayList.add(displayItem);
    }
    prefs.setString("defaultFile", path);
  }

  Future writeFile() {
    File file = File(defaultFile);
    String tempStr = '';
    for (int i = 0; i < displayList.length; i++) {
      var element = displayList[i];
      tempStr += '${element.trueData}\n';
    }
    tempStr = tempStr.substring(0, tempStr.length - 2);
    return file.writeAsString(tempStr);
  }

  void loadDirectory({String directory = ''}) {
    listList.clear();
    if (directory.isNotEmpty) {
      Directory d = Directory(directory);
      var fileList = d.listSync();
      for(int i = 0; i < fileList.length; i++) {
        var element = fileList[i];
        var displayItem = DisplayItem(element.path, i);
        listList.add(displayItem);
      }
    } else if (defaultDir.isNotEmpty) {
      Directory d = Directory(defaultDir);
      var fileList = d.listSync();
      for(int i = 0; i < fileList.length; i++) {
        var element = fileList[i];
        var displayItem = DisplayItem(element.path, i);
        listList.add(displayItem);
      }
    }
  }


  void openFile(BuildContext context) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    FilePickerResult? result = await FilePicker.platform.pickFiles(initialDirectory: documentsDir.path);

    if (result != null) {
      String? path = result.files.single.path;
      loadFile(path!);
    } else {
      // User canceled the picker
    }
  }

  void chooseDefaultDir(BuildContext context) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(initialDirectory: documentsDir.path);

    if (selectedDirectory != null) {
      defaultDir = selectedDirectory;
      await prefs.setString('defaultDir', defaultDir);
      loadDirectory();
    }
  }
}
