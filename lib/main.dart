import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_app/utils.dart';
import 'package:random_app/view/theme.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/audit.dart';
import 'model/data.dart';
import 'model/display_item.dart';
import 'model/ec.dart';
import 'model/ecs.dart';
import 'model/file.dart';
import 'model/prefs.dart';
import 'widget/dialogs/dialog_add.dart';
import 'widget/list_navigation_buttons.dart';
import 'widget/page/list.dart';
import 'widget/searchbar_main.dart';

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
  bool auditCurrent = true;
  int mode = 2;
  int modeSearch = 1;
  int modeAudit = 2;
  int modeEncrypt = 3;

  /// Custom Key Definitions (WIP):
  /// main screen: alt a = searchbar toggle focus, ctrl > < = move back or forward in list, alt r: shows shuffle dialog, alt s: shows sort dialog
  /// all dialogs : enter completes, delete removes, esc exits (already handled)
  /// list item: ctrl up move up the list, down..., ctrl del removes, space toggles checked
  /// list screen: ctrl . moves up a directory, ctrl > < = move back or forward in list
  /// Double click list item: open item or directory if exists

  num lastHotkeyPress = 0;

  void _onKey(RawKeyEvent event) {
    bool keyEventHandled = false;
    num currentTime = DateTime.now().millisecondsSinceEpoch;
    num timeDifference = currentTime - lastHotkeyPress;
    if (timeDifference < 200) return;
    if (event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
      addBtnPressed();
      keyEventHandled = true;
    }
    if (event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.digit2) {
      settingsPressed();
      keyEventHandled = true;
    }
    if (event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.digit1) {
      listsPressed();
      keyEventHandled = true;
    }
    if (event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
      searchClearPressed();
      keyEventHandled = true;
    }
    if (event.isAltPressed &&
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      nextSelectedList();
      keyEventHandled = true;
    }
    if (event.isAltPressed &&
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      prevSelectedList();
      keyEventHandled = true;
    }
    if (keyEventHandled) {
      lastHotkeyPress = currentTime;
    }
  }

  @override
  void initState() {
    super.initState();
    init();

    if (isMobile()) {
      // For sharing images coming from outside the app while the app is in the memory
      intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
          .listen((List<SharedMediaFile> value) async {
        //sharedFiles = value;
        //if (sharedFiles.isEmpty) return;
        //await getSettings();
        //await loadFile(sharedFiles.first.path);
        //sharedFiles.clear();
        //setState(() {});
      }, onError: (err) {
        print("getIntentDataStream error: $err");
      });

      // For sharing images coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialMedia()
          .then((List<SharedMediaFile> value) async {
        sharedFiles = value;
        if (sharedFiles.isEmpty) return;
        prefs = await SharedPreferences.getInstance();
        final directory = await getApplicationDocumentsDirectory();
        androidDir = '${directory.path}/playlists';
        defaultDir = androidDir;
        unselectAllLists();
        await loadFile(sharedFiles.first.path.replaceAll(' ', '_'));
        sharedFiles.clear();
        setState(() {});
      });

      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      intentDataStreamSubscription =
          ReceiveSharingIntent.getTextStream().listen((String value) async {
        //sharedText = value;
        //if (sharedText.isEmpty) return;
        //await getSettings();
        //var fileName = '$androidDir/${DateTime.timestamp()}';
        //importFile(fileName, sharedText);
        //sharedText = "";
        //setState(() {});
      }, onError: (err) {
        print("getLinkStream error: $err");
      });

      // For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialText().then((String? value) async {
        sharedText = value ?? '';
        if (sharedText.isEmpty) return;
        prefs = await SharedPreferences.getInstance();
        final directory = await getApplicationDocumentsDirectory();
        androidDir = '${directory.path}/playlists';
        defaultDir = androidDir;
        var fileName =
            '$androidDir/${DateTime.timestamp()}'.replaceAll(' ', '_');
        unselectAllLists();
        await importFile(fileName, sharedText);
        sharedText = "";
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    intentDataStreamSubscription.cancel();
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

  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    mainState = setState;
    return RawKeyboardListener(
        autofocus: true,
        focusNode: _focusNode,
        onKey: _onKey,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0.0,
          ),
          body: Column(
            children: <Widget>[
              Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.list,
                            color: darkMode ? Colors.white70 : Colors.black87,
                          ),
                          tooltip: 'Lists',
                          onPressed: () => listsPressed(),
                        ),
                        buildListNavigationButtons(context, true,
                            showDirectoryUpBtn: false),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: darkMode ? Colors.white70 : Colors.black87,
                          ),
                          tooltip: 'Settings',
                          onPressed: () {
                            settingsPressed();
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
                                  color: darkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                tooltip: 'Shuffle',
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          _buildConfirmDialog('Shuffle', () {
                                            shuffle();
                                            Navigator.pop(context);
                                            setState(() {});
                                          }));
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.sort_by_alpha,
                                  color: darkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                tooltip: 'Sort',
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          _buildConfirmDialog('Sort', () {
                                            sort();
                                            Navigator.pop(context);
                                            setState(() {});
                                          }));
                                },
                              ),
                            ],
                          ),
                        ),
                  buildMainSearchBar(),
                ],
              ),
              Expanded(
                  key: UniqueKey(),
                  child: RefreshIndicator(
                      onRefresh: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                _buildConfirmDialog('Shuffle', () {
                                  shuffle();
                                  Navigator.pop(context);
                                  setState(() {});
                                }));
                        return Future(() => null);
                      },
                      child: ListView.builder(
                          itemCount: displayList.length,
                          itemBuilder: (BuildContext context, int index) =>
                              _buildDataDisplay(index))))
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => addBtnPressed(),
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.add),
          ),
        ));
  }

  void listsPressed() {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return const ListPage();
      },
    ));
  }

  void settingsPressed() {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return _buildSettingsScreen();
      },
    ));
  }

  void addBtnPressed() {
    showDialog(
        context: context, builder: (BuildContext context) => const AddDialog());
  }

  /// Earth (Home planet): Water, Iron, Lead (Secret fish)

  Widget _buildDataDisplay(int index) {
    String displayItem = displayList[index].getDisplayData();
    Widget content;
    if (displayItem.contains(';')) {
      content = _buildDetailedListItems(index);
    } else {
      content = _buildDefaultListItem(index);
    }
    return _buildDefaultDisplay(index, content);
  }

  Widget _buildDefaultDisplay(int index, Widget content) {
    DisplayItem displayItem = displayList[index];
    return GestureDetector(
        onLongPress: () {
          showDialog(
              context: context,
              builder: (BuildContext context) =>
                  _buildAdvancedDialog(displayItem, index));
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
            attributes.first.trim(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ));
      attributes.removeAt(0);
    } else {
      if (str.contains(',')) {
        head = const SizedBox();
        attributes.add(str.trim());
      } else {
        if (str.trim().isNotEmpty) {
          head = Container(
              decoration: BoxDecoration(
                  color: !darkMode ? Colors.black12 : Colors.white10,
                  borderRadius: const BorderRadius.all(Radius.circular(12))),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Text(
                str.trim(),
                style: isFirst
                    ? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                    : null,
              ));
        } else {
          head = Container();
        }
      }
    }
    for (var attribute in attributes) {
      List<String> data = attribute.split(',');
      data = data.map((e) => e.trim()).toList();
      for (var element in data) {
        if (element.trim().isNotEmpty) {
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
        .contains(searchDisplayController.text.toLowerCase().trim())) {
      return false;
    }

    if (!useCheckboxes || cbViewMode == 0) return true;
    bool checked = prefs.getBool(checkedItemKey(displayItem.trueData)) ?? false;
    if ((cbViewMode == 1 && !checked)) return false;
    if ((cbViewMode == 2 && checked)) return false;
    return true;
  }

  Widget _buildSettingsScreen() {
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
      return _buildAuditScreen(context, state);
    }
    if (mode == modeSearch) {
      return _buildSearchScreen(context, state);
    }
    if (mode == modeEncrypt) {
      return _buildEncryptScreen(context, state);
    } else {
      return _buildSettingsHeader(context, state);
    }
  }

  Widget _buildSettingsHeader(BuildContext context, StateSetter state) {
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

  Widget _buildEncryptScreen(BuildContext context, StateSetter state) {
    return Column(children: [
      _buildSettingsHeader(context, state),
      Row(children: [
        Expanded(
            child: TextField(
          onChanged: (text) {
            if (text.isNotEmpty) {
              try {
                dC.text = decrypt(text);
              } catch (e) {
                dC.text = '';
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
          controller: eC,
        )),
        IconButton(
          icon: Icon(
            Icons.copy,
            color: darkMode ? Colors.white70 : Colors.black87,
          ),
          tooltip: 'Copy',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: eC.text));
          },
        ),
      ]),
      Row(children: [
        Expanded(
            child: TextField(
          onChanged: (text) {
            if (text.isNotEmpty) {
              eC.text = encrypt(text).base16;
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
          controller: dC,
        )),
        IconButton(
          icon: Icon(
            Icons.copy,
            color: darkMode ? Colors.white70 : Colors.black87,
          ),
          tooltip: 'Copy',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: dC.text));
          },
        ),
      ])
    ]);
  }

  Widget _buildSearchScreen(BuildContext context, StateSetter state) {
    return Column(children: [
      _buildSettingsHeader(context, state),
      TextField(
        onChanged: (text) {
          if (text == ecp) {
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
        controller: searchController,
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

  Widget _buildAuditScreen(BuildContext context, StateSetter state) {
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
      _buildSettingsHeader(context, state),
      const Text('---Audit---'),
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

  Dialog _buildAdvancedDialog(DisplayItem displayItem, int index) {
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
                        controller: controller
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
                        ClipboardData(text: controller.text));
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

  Dialog _buildConfirmDialog(String title, dynamic callback) {
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
}
