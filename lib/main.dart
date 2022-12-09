import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';

bool darkMode = true;

Color dialogColor = const Color.fromARGB(255, 63, 63, 63);

ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.white,
    dialogBackgroundColor: Colors.white,
    canvasColor: Colors.white,
    hintColor: Colors.white70,
    textTheme: const TextTheme(
      bodyText1: TextStyle(),
      bodyText2: TextStyle(),
      button: TextStyle(),
    ).apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white10,
      iconColor: Colors.black87,
      hintStyle: TextStyle(color: Colors.black87),
      labelStyle: TextStyle(color: Colors.black87),
    ));

ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.black87,
    dialogBackgroundColor: Colors.grey,
    canvasColor: Colors.black,
    hintColor: Colors.black87,
    textTheme: const TextTheme(
      bodyText1: TextStyle(),
      bodyText2: TextStyle(),
      button: TextStyle(),
    ).apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white70,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey,
      iconColor: Colors.white70,
      hintStyle: TextStyle(color: Colors.white70),
      labelStyle: TextStyle(color: Colors.white70),
    ));

void main() {
  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> _notifier = ValueNotifier(ThemeMode.dark);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: _notifier,
        builder: (_, mode, __) {
          return MaterialApp(
            title: 'List Master',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: mode,
            home: const MyHomePage(title: 'List Master'),
          );
        });
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
  bool selected = false;

  DisplayItem(this.trueData);

  String getDisplayData() {
    Directory d = Directory(trueData);
    String sep = trueData.contains('/') ? '/' : '\\';
    String tempStr = trueData;
    try {
      if (d.existsSync()) {
        tempStr = trueData.split(sep).last.replaceAll('_', ' ');
        //return d.path.split('\\').last;
      } else {
        tempStr = trueData.split(sep).last.replaceAll('_', ' ');
      }
    } catch (e) {
      tempStr = trueData.replaceAll('_', ' ');
    }

    if (tempStr.contains('.')) {
      var i = tempStr.lastIndexOf('.');
      tempStr = tempStr.substring(0, i);
    }

    return tempStr;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<DisplayItem> displayList = [];
  List<DisplayItem> listList = [];
  late SharedPreferences prefs;
  String defaultDir = '';
  String defaultFile = '';
  String androidDir = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    await getSettings();
    var statusA = await Permission.storage.status;
    var statusB = await Permission.manageExternalStorage.status;
    if (!statusA.isGranted || !statusB.isGranted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.manageExternalStorage,
        Permission.storage,
      ].request();
    }
    loadDirectory();
    await loadFile(defaultFile);
    _notifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;
    setState(() {});
  }

  Future getSettings() async {
    if (Platform.isAndroid) {
      final directory = await getApplicationDocumentsDirectory();
      androidDir = '${directory.path}/playlists';
      var d = Directory(androidDir);
      var c = await d.exists();
      if (!c) {
        await d.create();
      }
    }
    defaultDir =
        Platform.isAndroid ? androidDir : prefs.getString('defaultDir') ?? '';
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
                      icon: Icon(
                        Icons.list,
                        color: darkMode ? Colors.white70 : Colors.black87,
                      ),
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
                      icon: Icon(
                        Icons.settings,
                        color: darkMode ? Colors.white70 : Colors.black87,
                      ),
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
                      icon: Icon(
                        Icons.shuffle,
                        color: darkMode ? Colors.white70 : Colors.black87,
                      ),
                      tooltip: 'Shuffle',
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                getConfirmDialog('Shuffle', () {
                                  shuffle();
                                  Navigator.pop(context);
                                  setState(() {});
                                }));
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.sort_by_alpha,
                        color: darkMode ? Colors.white70 : Colors.black87,
                      ),
                      tooltip: 'Sort',
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                getConfirmDialog('Sort', () {
                                  sort();
                                  Navigator.pop(context);
                                  setState(() {});
                                }));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
              key: UniqueKey(),
              child: RefreshIndicator(
                  onRefresh: () {
                    shuffle();
                    return Future(() => null);
                  },
                  child: ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                            onLongPress: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      getAdvancedDialog(
                                          displayList[index], index));
                            },
                            child: Card(
                                color:
                                    !darkMode ? Colors.black12 : Colors.white10,
                                margin: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(displayList[index]
                                              .getDisplayData()),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.move_down,
                                            color: darkMode
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
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
                                )));
                      })))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) => getAddDialog());
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
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
      return a
          .getDisplayData()
          .toLowerCase()
          .compareTo(b.getDisplayData().toLowerCase());
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
          ));
    });
  }

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _addController = TextEditingController();

  Widget getListScreen() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lists'),
        ),
        body: Column(
          children: [
            Row(children: [
              TextButton(
                  child: Text(
                    'Import List',
                    style: TextStyle(
                      color: darkMode ? Colors.white70 : Colors.deepPurple,
                    ),
                  ),
                  onPressed: () {
                    openFile(context, state);
                    state(() {});
                  }),
              TextButton(
                  child: Text('Export List',
                      style: TextStyle(
                        color: darkMode ? Colors.white70 : Colors.deepPurple,
                      )),
                  onPressed: () {
                    exportFile();
                    state(() {});
                  }),
              TextButton(
                  child: Text('Choose Default List',
                      style: TextStyle(
                        color: darkMode ? Colors.white70 : Colors.deepPurple,
                      )),
                  onPressed: () {
                    chooseDefaultDir(context);
                    state(() {});
                  })
            ]),
            Expanded(
              key: UniqueKey(),
              child: ListView.builder(
                  itemCount: listList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onLongPress: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                getAdvancedListDialog(index, state));
                      },
                      onTap: () async {
                        await load(listList[index].trueData);
                        setListSelected(index);
                        setState(() {});
                        state(() {});
                      },
                      child: Card(
                          margin: const EdgeInsets.all(4.0),
                          color: getSelectedCardColor(listList[index].selected),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child:
                                        Text(listList[index].getDisplayData()),
                                  ),
                                ),
                              ),
                            ],
                          )),
                    );
                  }),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => getAddListDialog(state));
          },
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  Future<void> exportFile() async {
    if (Platform.isAndroid) {
      File file = File(defaultFile);
      await Share.shareFiles([file.path], text: 'Export Data');
    }
  }

  void setListSelected(int index) {
    listList[index].selected = !listList[index].selected;
    for (int i = 0; i < listList.length; i++) {
      if (i != index) {
        listList[i].selected = false;
      }
    }
  }

  Dialog getAddListDialog(StateSetter outerState) {
    return Dialog(
        backgroundColor: darkMode ? dialogColor : Colors.white,
        elevation: 10,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: StatefulBuilder(builder: (BuildContext context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                style: TextStyle(color: darkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: darkMode ? Colors.white60 : Colors.black54),
                  ),
                  hintStyle: TextStyle(
                      color: darkMode ? Colors.white60 : Colors.black54),
                  hintText: 'Name',
                  filled: true,
                  fillColor: !darkMode ? Colors.white : dialogColor,
                ),
                controller: _addController,
              ),
              TextButton(
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    displayList.add(DisplayItem(_addController.text));
                    createFile(_addController.text, context, outerState);
                    _addController.text = '';
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  Dialog getAddDialog() {
    return Dialog(
        backgroundColor: darkMode ? dialogColor : Colors.white,
        elevation: 10,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: StatefulBuilder(builder: (BuildContext context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                style: TextStyle(color: darkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: darkMode ? Colors.white60 : Colors.black54),
                  ),
                  hintStyle: TextStyle(
                      color: darkMode ? Colors.white60 : Colors.black54),
                  hintText: 'Name',
                  filled: true,
                  fillColor: !darkMode ? Colors.white : dialogColor,
                ),
                controller: _addController,
              ),
              TextButton(
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    displayList.add(DisplayItem(_addController.text));
                    writeFile();
                    _addController.text = '';
                    setState(() {});
                    state(() {});
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  Dialog getAdvancedDialog(DisplayItem displayItem, int index) {
    return Dialog(
        backgroundColor: darkMode ? dialogColor : Colors.white,
        elevation: 10,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: StatefulBuilder(builder: (BuildContext context, state) {
          return Column(
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
                    setState(() {});
                    state(() {});
                    Navigator.pop(context);
                  }),
              TextField(
                  style:
                      TextStyle(color: darkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: darkMode ? Colors.white60 : Colors.black54),
                    ),
                    hintStyle: TextStyle(
                        color: darkMode ? Colors.white60 : Colors.black54),
                    hintText: 'Name',
                    filled: true,
                    fillColor: !darkMode ? Colors.white : dialogColor,
                  ),
                  controller: _controller..text = displayList[index].trueData,
                  onChanged: (text) {
                    displayList[index].trueData = text;
                  }),
              TextButton(
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    writeFile();
                    setState(() {});
                    state(() {});
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  Dialog getAdvancedListDialog(int index, StateSetter outerState) {
    return Dialog(
        backgroundColor: darkMode ? dialogColor : Colors.white,
        elevation: 10,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: StatefulBuilder(builder: (BuildContext context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    if (listList[index].selected) {
                      clearDefaultFile();
                    }
                    deleteFile(listList[index].trueData);
                    listList.remove(listList[index]);
                    setState(() {});
                    state(() {});
                    outerState(() {});
                    Navigator.pop(context);
                  }),
              TextField(
                  style:
                      TextStyle(color: darkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: darkMode ? Colors.white60 : Colors.black54),
                    ),
                    hintStyle: TextStyle(
                        color: darkMode ? Colors.white60 : Colors.black54),
                    hintText: 'Name',
                    filled: true,
                    fillColor: !darkMode ? Colors.white : dialogColor,
                  ),
                  controller: _controller..text = listList[index].trueData,
                  onChanged: (text) {
                    listList[index].trueData = text;
                  }),
              TextButton(
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    defaultFile = listList[index].trueData;
                    prefs.setString("defaultFile", defaultFile);
                    writeFile();
                    loadFile(listList[index].trueData);
                    setState(() {});
                    state(() {});
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  Dialog getConfirmDialog(String title, dynamic callback) {
    return Dialog(
        backgroundColor: darkMode ? dialogColor : Colors.white,
        elevation: 10,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: StatefulBuilder(builder: (BuildContext context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16.0, fontWeight: FontWeight.bold),
                  )),
              TextButton(
                  onPressed: callback,
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.blue),
                  ))
            ],
          );
        }));
  }

  Color getSelectedCardColor(bool selected) {
    var themeColor = !darkMode ? Colors.white70 : Colors.black87;
    return selected ? const Color.fromARGB(63, 255, 234, 0) : themeColor;
  }

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

    displayList.clear();
    try {
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
  }

  Future writeFile({String? path}) {
    File file = File(path ?? defaultFile);
    String tempStr = '';
    for (int i = 0; i < displayList.length; i++) {
      var element = displayList[i];
      tempStr += '${element.trueData}\n';
    }
    return file.writeAsString(tempStr);
  }

  void loadDirectory({String directory = ''}) {
    listList.clear();
    if (directory.isNotEmpty) {
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
          .compareTo(b.getDisplayData().toLowerCase());
    });
  }

  void openFile(BuildContext context, StateSetter state) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(initialDirectory: documentsDir.path);
    if (result != null) {
      String? path = result.files.single.path;
      await loadFile(path!);
      loadDirectory();
      setState(() {});
      state(() {});
    } else {
      // User canceled the picker
    }
  }

  void createFile(String path, BuildContext context, StateSetter state) async {
    await loadFile('$androidDir/${path.replaceAll(' ', '_')}');
    loadDirectory();
    setState(() {});
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
}
