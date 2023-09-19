import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:encrypt/encrypt.dart' as ec;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_app/utils.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/display_item.dart';

final key = ec.Key.fromUtf8('hAWnzuoKakJqgyPbNTVjxzRsDIhUnzKU');
final iv = ec.IV.fromLength(16);
final encrypter = ec.Encrypter(ec.AES(key));

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

class _MyHomePageState extends State<MyHomePage> {
  List<DisplayItem> displayList = [];
  List<DisplayItem> listList = [];

  List<String> auditData = [];

  late SharedPreferences prefs;
  String defaultDir = '';
  String defaultFile = '';
  String androidDir = '';

  bool useNotes = false;

  late StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles = [];
  String _sharedText = '';

  // 0 all, 1 unchecked, 2 checked
  num cbViewMode = 0;

  @override
  void initState() {
    super.initState();
    init();
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) async {
      //_sharedFiles = value;
      //if (_sharedFiles.isEmpty) return;
      //await getSettings();
      //await loadFile(_sharedFiles.first.path);
      //_sharedFiles.clear();
      //setState(() {});
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia()
        .then((List<SharedMediaFile> value) async {
      _sharedFiles = value;
      if (_sharedFiles.isEmpty) return;
      prefs = await SharedPreferences.getInstance();
      final directory = await getApplicationDocumentsDirectory();
      androidDir = '${directory.path}/playlists';
      defaultDir = androidDir;
      unselectAllLists();
      await loadFile(_sharedFiles.first.path.replaceAll(' ', '_'));
      _sharedFiles.clear();
      setState(() {});
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) async {
      //_sharedText = value;
      //if (_sharedText.isEmpty) return;
      //await getSettings();
      //var fileName = '$androidDir/${DateTime.timestamp()}';
      //importFile(fileName, _sharedText);
      //_sharedText = "";
      //setState(() {});
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) async {
      _sharedText = value ?? '';
      if (_sharedText.isEmpty) return;
      prefs = await SharedPreferences.getInstance();
      final directory = await getApplicationDocumentsDirectory();
      androidDir = '${directory.path}/playlists';
      defaultDir = androidDir;
      var fileName = '$androidDir/${DateTime.timestamp()}'.replaceAll(' ', '_');
      unselectAllLists();
      await importFile(fileName, _sharedText);
      _sharedText = "";
      setState(() {});
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    await getSettings();
    //var statusA = await Permission.storage.status;
    //var statusB = await Permission.manageExternalStorage.status;
    //if (!statusA.isGranted || !statusB.isGranted) {
    //  Map<Permission, PermissionStatus> statuses = await [
    //    Permission.manageExternalStorage,
    //    Permission.storage,
    //  ].request();
    //}
    loadDirectory();
    await loadFile(defaultFile);
    _notifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;
    findSelectedList();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black87,
    ));
    setState(() {});
  }

  void findSelectedList() {
    for (DisplayItem item in listList) {
      if (item.trueData == defaultFile) {
        item.selected = true;
        break;
      }
    }
  }

  void unselectAllLists() {
    for (DisplayItem item in listList) {
      item.selected = false;
    }
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
    useNotes = prefs.getBool('USES_NOTES') ?? false;
    getAuditData();
  }

  String useCheckboxesKey() {
    return '${defaultFile}_useCheckboxes';
  }

  String checkedItemKey(String itemName) {
    return '${defaultFile}_${itemName}_useCheckboxes';
  }

  void getAuditData() {
    var audit = prefs.getString('auditData') ?? '';
    if (audit.isNotEmpty) {
      auditData = audit.split(';');
    }
    auditData
        .removeWhere((element) => element.isEmpty || !element.contains(':'));
  }

  Future saveAuditData() async {
    String auditStr = '';
    for (String str in auditData) {
      auditStr += '$str;';
    }
    await prefs.setString('auditData', auditStr);
  }

  Future addAuditData(String toAdd) async {
    while (auditData.length >= 25) {
      auditData.removeAt(0);
    }
    auditData.add('$toAdd:${getTimestamp()}');
    await saveAuditData();
  }

  void removeLastAudit() {
    int latestTime = 0;
    int latestIndex = 0;
    int i = 0;
    for (String str in auditData) {
      var arr = str.split(':');
      var t = int.parse(arr[1]);
      if (latestTime == 0 || t < latestTime) {
        latestTime = t;
        latestIndex = i;
      }
      i++;
    }
    auditData.removeAt(latestIndex);
  }

  void onSearchChanged(String text) {
    setState(() {});
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
                    Text('Item Count: ${displayList.length}'),
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
              useCheckboxes
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                                onPressed: () {
                                  cbViewMode = 0;
                                  setState(() {});
                                },
                                child: const Text('View All')),
                            TextButton(
                                onPressed: () {
                                  cbViewMode = 1;
                                  setState(() {});
                                },
                                child: const Text('View Checked')),
                            TextButton(
                                onPressed: () {
                                  cbViewMode = 2;
                                  setState(() {});
                                },
                                child: const Text('View Unchecked'))
                          ]))
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: TextField(
                  style:
                      TextStyle(color: darkMode ? Colors.white : Colors.black),
                  controller: _searchDisplayController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: darkMode ? Colors.white24 : Colors.black26,
                    hintText: 'Search',
                    hintStyle: TextStyle(
                        color: darkMode ? Colors.white : Colors.black),
                    prefixIcon: Icon(
                      Icons.search,
                      color: darkMode ? Colors.white : Colors.black,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchDisplayController.text = "";
                        onSearchChanged("");
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
              ),
            ],
          ),
          Expanded(
              key: UniqueKey(),
              child: RefreshIndicator(
                  onRefresh: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            getConfirmDialog('Shuffle', () {
                              shuffle();
                              Navigator.pop(context);
                              setState(() {});
                            }));
                    return Future(() => null);
                  },
                  child: ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (BuildContext context, int index) =>
                          getDataDisplay(index))))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_searchDisplayController.text.isEmpty) {
            showDialog(
                context: context,
                builder: (BuildContext context) => getAddDialog());
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Earth (Home planet): Water, Iron, Lead (Secret fish)

  Widget getDataDisplay(int index) {
    String displayItem = displayList[index].getDisplayData();
    Widget content;
    if (displayItem.contains(';')) {
      content = _buildDetailedListItems(index);
    } else {
      content = _buildDefaultListItem(index);
    }
    return getDefaultDisplay(index, content);
  }

  Widget getDefaultDisplay(int index, Widget content) {
    DisplayItem displayItem = displayList[index];
    return GestureDetector(
        onLongPress: () {
          showDialog(
              context: context,
              builder: (BuildContext context) =>
                  getAdvancedDialog(displayItem, index));
        },
        onTap: () async {
          await Clipboard.setData(
              ClipboardData(text: displayItem.getDisplayData()));
        },
        child: showCard(displayItem)
            ? Container(
                decoration: BoxDecoration(
                    color: !darkMode ? Colors.black12 : Colors.white10,
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: content)
            : Container());
  }

  Widget _buildDetailedListItems(int index) {
    DisplayItem displayItem = displayList[index];
    List<Widget> dataArr = [];
    List<String> attributes = [];
    attributes.addAll(displayItem.getDisplayData().split(';'));
    for (int i = 0; i < attributes.length; i++) {
      var attribute = attributes[i];
      dataArr.add(_buildDetailedListItem(attribute, i == 0));
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          flex: 8,
          child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: dataArr))),
      Expanded(
          flex: 2,
          child: Container(
              padding: const EdgeInsets.all(8.0),
              child: useCheckboxes
                  ? _buildDataListCheckbox(index)
                  : _buildMoveToBottomButton(index)))
    ]);
  }

  /// Example:
  /// Earth (Home planet): Water, Iron, Lead (Secret treasure)
  Widget _buildDetailedListItem(String str, bool isFirst) {
    List<Widget> dataArr = [];
    List<String> attributes = [];
    Widget head;
    if (str.contains(':')) {
      attributes.addAll(str.split(':'));
      head = Container(
          decoration: BoxDecoration(
              color: !darkMode ? Colors.black12 : Colors.white10,
              borderRadius: const BorderRadius.all(Radius.circular(12))),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Text(
            attributes.first,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ));
      attributes.removeAt(0);
    } else {
      if (str.contains(',')) {
        head = const SizedBox();
        attributes.add(str);
      } else {
        head = Container(
            decoration: BoxDecoration(
                color: !darkMode ? Colors.black12 : Colors.white10,
                borderRadius: const BorderRadius.all(Radius.circular(12))),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Text(
              str,
              style: isFirst
                  ? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  : null,
            ));
      }
    }
    for (var attribute in attributes) {
      List<String> data = attribute.split(',');
      data = data.map((e) => e.trim()).toList();
      for (var element in data) {
        Widget dataWidget = Container(
            decoration: BoxDecoration(
                color: !darkMode ? Colors.black12 : Colors.white10,
                borderRadius: const BorderRadius.all(Radius.circular(12))),
            margin: const EdgeInsets.fromLTRB(0, 8, 12, 0),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Text(element));
        dataArr.add(dataWidget);
      }
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          flex: 8,
          child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, child: head),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(children: dataArr))
              ]))),
      Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(8.0),
          ))
    ]);
  }

  Widget _buildDefaultListItem(int index) {
    DisplayItem displayItem = displayList[index];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            flex: 8,
            child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text(displayItem.getDisplayData())))),
        Expanded(
          flex: 2,
          child: Container(
              padding: const EdgeInsets.all(8.0),
              child: useCheckboxes
                  ? _buildDataListCheckbox(index)
                  : _buildMoveToBottomButton(index)),
        ),
      ],
    );
  }

  Widget _buildMoveToBottomButton(int index) {
    return IconButton(
      icon: Icon(
        Icons.move_down,
        color: darkMode ? Colors.white70 : Colors.black87,
      ),
      tooltip: 'Move to Bottom',
      onPressed: () async {
        var d = displayList.removeAt(index);
        displayList.add(d);
        await addAuditData(d.getDisplayData());
        setState(() {});
        writeFile();
      },
    );
  }

  Widget _buildDataListCheckbox(int index) {
    DisplayItem displayItem = displayList[index];
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: prefs.getBool(checkedItemKey(displayItem.trueData)) ?? false,
          onChanged: (condition) {
            prefs.setBool(
                checkedItemKey(displayItem.trueData), condition ?? false);
            setState(() {});
          });
    });
  }

  bool showCard(DisplayItem displayItem) {
    if (!displayItem
        .getDisplayData()
        .toLowerCase()
        .contains(_searchDisplayController.text.toLowerCase().trim())) {
      return false;
    }

    if (!useCheckboxes || cbViewMode == 0) return true;
    bool checked = prefs.getBool(checkedItemKey(displayItem.trueData)) ?? false;
    if ((cbViewMode == 1 && !checked)) return false;
    if ((cbViewMode == 2 && checked)) return false;
    return true;
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

  bool auditCurrent = true;
  int mode = 2;
  int modeSearch = 1;
  int modeAudit = 2;
  int modeEncrypt = 3;

  List<DisplayItem> searchList = [];

  Widget getSettingsScreen() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter state) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: getSettingsBody(context, state));
    });
  }

  Widget getSettingsBody(BuildContext context, StateSetter state) {
    if (mode == modeAudit) {
      return getAuditScreen(context, state);
    }
    if (mode == modeSearch) {
      return getSearchScreen(context, state);
    }
    if (mode == modeEncrypt) {
      return getEncryptScreen(context, state);
    } else {
      return getSettingsHeader(context, state);
    }
  }

  Widget getSettingsHeader(BuildContext context, StateSetter state) {
    return Column(children: [
      Row(children: [
        IconButton(
          icon: Icon(
            Icons.search,
            color: darkMode ? Colors.white70 : Colors.black87,
          ),
          tooltip: 'Search',
          onPressed: () {
            mode = modeSearch;
            state(() {});
          },
        ),
        IconButton(
          icon: Icon(
            Icons.menu_book,
            color: darkMode ? Colors.white70 : Colors.black87,
          ),
          tooltip: 'Audit',
          onPressed: () {
            mode = modeAudit;
            state(() {});
          },
        ),
      ]),
      Row(children: [
        const Text('Use Checkboxes?'),
        Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.0),
            ),
            side: MaterialStateBorderSide.resolveWith(
              (states) => const BorderSide(width: 2.0, color: Colors.white70),
            ),
            value: useCheckboxes,
            onChanged: (condition) {
              useCheckboxes = condition ?? false;
              prefs.setBool(useCheckboxesKey(), useCheckboxes);
              state(() {});
            }),
        const Text('Note Mode?'),
        Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.0),
            ),
            side: MaterialStateBorderSide.resolveWith(
              (states) => const BorderSide(width: 2.0, color: Colors.white70),
            ),
            value: useNotes,
            onChanged: (condition) {
              useNotes = condition ?? false;
              prefs.setBool('USES_NOTES', useNotes);
              state(() {});
            })
      ]),
    ]);
  }

  bool useCheckboxes = false;

  final TextEditingController _eC = TextEditingController();
  final TextEditingController _dC = TextEditingController();

  ec.Encrypted encrypt(String input) {
    return encrypter.encrypt(input, iv: iv);
  }

  String decrypt(String input) {
    return encrypter.decrypt16(input, iv: iv);
  }

  Widget getEncryptScreen(BuildContext context, StateSetter state) {
    return Column(children: [
      getSettingsHeader(context, state),
      Row(children: [
        Expanded(
            child: TextField(
          onChanged: (text) {
            if (text.isNotEmpty) {
              try {
                _dC.text = decrypt(text);
              } catch (e) {
                _dC.text = '';
              }
            }
          },
          style: TextStyle(color: darkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: darkMode ? Colors.white60 : Colors.black54),
            ),
            hintStyle:
                TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
            hintText: 'Enc',
            filled: true,
            fillColor: !darkMode ? Colors.white : dialogColor,
          ),
          controller: _eC,
        )),
        IconButton(
          icon: Icon(
            Icons.copy,
            color: darkMode ? Colors.white70 : Colors.black87,
          ),
          tooltip: 'Copy',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _eC.text));
          },
        ),
      ]),
      Row(children: [
        Expanded(
            child: TextField(
          onChanged: (text) {
            if (text.isNotEmpty) {
              _eC.text = encrypt(text).base16;
            }
          },
          style: TextStyle(color: darkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: darkMode ? Colors.white60 : Colors.black54),
            ),
            hintStyle:
                TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
            hintText: 'Dec',
            filled: true,
            fillColor: !darkMode ? Colors.white : dialogColor,
          ),
          controller: _dC,
        )),
        IconButton(
          icon: Icon(
            Icons.copy,
            color: darkMode ? Colors.white70 : Colors.black87,
          ),
          tooltip: 'Copy',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _dC.text));
          },
        ),
      ])
    ]);
  }

  Widget getSearchScreen(BuildContext context, StateSetter state) {
    return Column(children: [
      getSettingsHeader(context, state),
      TextField(
        onChanged: (text) {
          if (text == 'Hayhat12\$') {
            mode = modeEncrypt;
            state(() {});
          } else {
            searchList = displayList
                .where((element) => element
                    .getDisplayData()
                    .toLowerCase()
                    .contains(text.toLowerCase()))
                .toList();

            state(() {});
          }
        },
        style: TextStyle(color: darkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: darkMode ? Colors.white60 : Colors.black54),
          ),
          hintStyle:
              TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
          hintText: 'Search',
          filled: true,
          fillColor: !darkMode ? Colors.white : dialogColor,
        ),
        controller: _searchController,
      ),
      Expanded(
          child: ListView.builder(
              itemCount: searchList.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                    decoration: BoxDecoration(
                        color: !darkMode ? Colors.black12 : Colors.white10,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12))),
                    margin: const EdgeInsets.fromLTRB(12.0, 4, 12, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child:
                                    Text(searchList[index].getDisplayData())),
                          ),
                        ),
                      ],
                    ));
              })),
    ]);
  }

  Widget getAuditScreen(BuildContext context, StateSetter state) {
    List<Map<String, dynamic>> tempData = [];
    List<String> tempArr = [];
    for (var d in displayList) {
      tempArr.add(d.getDisplayData());
    }
    //getAuditData();
    for (String str in auditData) {
      var s = str.split(':');
      if (!auditCurrent || tempArr.contains(s.first)) {
        tempData.add({'name': s.first, 'time': s.last});
      }
    }
    tempData.sort((a, b) {
      return b['time'].compareTo(a['time']);
    });
    return Column(children: [
      getSettingsHeader(context, state),
      Text('---Audit---'),
      Row(children: [
        const Text('Current List only? '),
        Checkbox(
            value: auditCurrent,
            onChanged: (b) {
              auditCurrent = b ?? true;
              state(() {});
            })
      ]),
      Expanded(
          child: ListView.builder(
              itemCount: tempData.length,
              itemBuilder: (BuildContext context, int index) {
                String s = 'Invalid';
                String t = 'Invalid';
                try {
                  s = tempData[index]['name'];
                  DateTime time = DateTime.fromMicrosecondsSinceEpoch(
                      int.parse(tempData[index]['time']) * 1000);
                  t = getDisplayTimestamp(time);
                } catch (e) {}
                //return Text(
                //  s,
                //  style: TextStyle(color: Colors.white),
                //);
                return Container(
                    decoration: BoxDecoration(
                        color: !darkMode ? Colors.black12 : Colors.white10,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12))),
                    margin: const EdgeInsets.fromLTRB(12.0, 4, 12, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            //child: Center(child: Text('${index + 1} $s')),
                            child: Center(child: Text('$s')),
                          ),
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
                      ],
                    ));
              })),
    ]);
  }

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchDisplayController =
      TextEditingController();
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

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
                      child: Container(
                          decoration: BoxDecoration(
                              color: getSelectedCardColor(
                                  listList[index].selected),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12))),
                          margin: const EdgeInsets.fromLTRB(12.0, 4, 12, 4),
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
                obscureText: false,
                maxLines: null,
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
    String oldText = displayList[index].trueData;
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
              TextButton(
                  child: const Text(
                    'Move Up',
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: () async {
                    var d = displayList.removeAt(index);
                    displayList.insert(0, d);
                    await addAuditData(d.getDisplayData());
                    setState(() {});
                    state(() {});
                    writeFile();
                    Navigator.pop(context);
                  }),
              Row(children: [
                Expanded(
                    child: TextField(
                        obscureText: false,
                        maxLines: null,
                        style: TextStyle(
                            color: darkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    darkMode ? Colors.white60 : Colors.black54),
                          ),
                          hintStyle: TextStyle(
                              color:
                                  darkMode ? Colors.white60 : Colors.black54),
                          hintText: 'Name',
                          filled: true,
                          fillColor: !darkMode ? Colors.white : dialogColor,
                        ),
                        controller: _controller
                          ..text = displayList[index].trueData,
                        onChanged: (text) {
                          displayList[index].trueData = text;
                        })),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    color: darkMode ? Colors.white70 : Colors.black87,
                  ),
                  tooltip: 'Copy',
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: _controller.text));
                  },
                )
              ]),
              TextButton(
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    var condition =
                        prefs.getBool(checkedItemKey(oldText)) ?? false;
                    prefs.setBool(
                        checkedItemKey(displayList[index].trueData), condition);
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
                    reloadFile(index);
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  void reloadFile(int index) async {
    defaultFile = listList[index].trueData;
    await prefs.setString("defaultFile", defaultFile);
    await writeFile();
    await loadFile(listList[index].trueData);
    setState(() {});
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
    var themeColor = !darkMode ? Colors.black12 : Colors.white10;
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
