import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
    )
);

ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.deepOrange,
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
    )
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      title: 'List Master',
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
  num index = -1;
  bool selected = false;

  DisplayItem(this.trueData, this.index);

  String getDisplayData() {
    Directory d = Directory(trueData);
    String sep = Platform.isAndroid ? '/' : '\\';
    try {
      if (d.existsSync()) {
        return trueData.split(sep).last;
        //return d.path.split('\\').last;
      } else {
        return trueData.split(sep).last;
      }
    } catch(e) {
      return trueData;
    }
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
    init();
    super.initState();
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
    loadFile(defaultFile);
    setState(() {});
  }

  Future getSettings() async {
    if (Platform.isAndroid) {
      final directory = await getApplicationDocumentsDirectory();
      androidDir = directory.path + '/playlists';
      var d = Directory(androidDir);
      var c = await d.exists();
      if (!c) {
        await d.create();
      }
    }
    defaultDir = Platform.isAndroid ? androidDir : prefs.getString('defaultDir') ?? '';
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
                    return GestureDetector(
                      onLongPress: () {
                        showDialog(context: context, builder: (BuildContext context) => getAdvancedDialog(displayList[index], index));
                      },
                      child: Card(
                        margin: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 9,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(displayList[index].getDisplayData()),
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
                    ));
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
      return a.getDisplayData().toLowerCase().compareTo(b.getDisplayData().toLowerCase());
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

  final TextEditingController _controller = TextEditingController();

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
                      openFile(context, state);
                      state((){});
                    }
                ),
                TextButton(
                    child: Text('Export List'),
                    onPressed: () {
                      //openFile(context);
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
                        onLongPress: () {
                          showDialog(context: context, builder: (BuildContext context) => getAdvancedListDialog(listList[index], state));
                        },
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
                                      child: Text(listList[index].getDisplayData()),
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

  Dialog getAdvancedDialog(DisplayItem displayItem, int index) {
    return Dialog(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: StatefulBuilder(builder: (BuildContext context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  child: const Text('Remove', style: TextStyle(color: Colors.red),),
                  onPressed: () {
                    displayList.remove(displayItem);
                    writeFile();
                    setState((){});
                    state((){});
                    Navigator.pop(context);
                  }
              ),
              TextField(
                  controller: _controller..text = displayList[index].trueData,
                  onChanged: (text) {
                    displayList[index].trueData = text;
              }),
              TextButton(
                  child: const Text('Done', style: TextStyle(color: Colors.blue),),
                  onPressed: () {
                    writeFile();
                    setState((){});
                    state((){});
                    Navigator.pop(context);
                  }
              ),
            ],
          );
        }
        )
    );
  }

  Dialog getAdvancedListDialog(DisplayItem displayItem, StateSetter outerState) {
    return Dialog(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: StatefulBuilder(builder: (BuildContext context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  child: const Text('Remove', style: TextStyle(color: Colors.red),),
                  onPressed: () {
                    if (displayItem.selected) {
                      clearDefaultFile();
                    }
                    deleteFile(displayItem.trueData);
                    listList.remove(displayItem);
                    setState((){});
                    state((){});
                    outerState((){});
                    Navigator.pop(context);
                  }
              )
            ],
          );
        }
        )
    );
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
    String temp = path;
    if (Platform.isAndroid) {
      var arr = path.split('/');
      var s = arr[arr.length - 1];
      var st = androidDir + '/' + s;
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

  void loadDirectory({String directory = ''}) async {
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


  void openFile(BuildContext context, StateSetter state) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    FilePickerResult? result = await FilePicker.platform.pickFiles(initialDirectory: documentsDir.path);

    if (result != null) {
      String? path = result.files.single.path;
      await loadFile(path!);
      loadDirectory();
      setState((){});
      state((){});
    } else {
      // User canceled the picker
    }
  }

  void chooseDefaultDir(BuildContext context) async {
    if (Platform.isAndroid) return;
    final documentsDir = await getApplicationDocumentsDirectory();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(initialDirectory: documentsDir.path);

    if (selectedDirectory != null) {
      defaultDir = selectedDirectory;
      await prefs.setString('defaultDir', defaultDir);
      loadDirectory();
    }
  }
}
