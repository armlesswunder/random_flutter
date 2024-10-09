import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_app/model/utils.dart';
import 'package:random_app/view/color_spec.dart';
import 'package:random_app/view/theme.dart';
import 'package:random_app/widget/components/favorite_button.dart';
import 'package:random_app/widget/components/image_builder.dart';
import 'package:random_app/widget/components/list_navigation_buttons.dart';
import 'package:random_app/widget/page/settings/page.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/audit.dart';
import 'model/data.dart';
import 'model/display_item.dart';
import 'model/file.dart';
import 'model/prefs.dart';
import 'model/web_utils_none.dart'
    if (dart.library.html) 'model/web_utils.dart';
import 'widget/components/searchbar_main.dart';
import 'widget/dialogs/dialog_add.dart';
import 'widget/page/list.dart';

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
            scrollBehavior: isMobile()
                ? ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                    },
                  )
                : ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
            title: 'List Wizard',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: mode,
            home: const MyHomePage(title: 'List Wizard'),
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

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Custom Key Definitions (WIP):
  /// main screen: alt a = searchbar toggle focus, ctrl > < = move back or forward in list, alt r: shows shuffle dialog, alt s: shows sort dialog
  /// all dialogs : enter completes, delete removes, esc exits (already handled)
  /// list item: ctrl up move up the list, down..., ctrl del removes, space toggles checked
  /// list screen: ctrl . moves up a directory, ctrl > < = move back or forward in list
  /// Double click list item: open item or directory if exists

  num lastHotkeyPress = 0;
  bool useHandles = false;
  Timer? cachePosTimer;

  late FocusNode _optionsFocusNode;
  List<String> checkedOptions = [' - ', 'View Checked', 'View Unchecked'];

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
    if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
      searchFocus.requestFocus();
      keyEventHandled = true;
    }
    if (keyEventHandled) {
      lastHotkeyPress = currentTime;
    }
  }

  @override
  void initState() {
    super.initState();

    if (isWeb()) {
      setupDefaultDirs();
    } else {
      setupDefaultDirs().then((value) {
        //logger = Logger(output: MyFileOutput());
        //logger.e('Logger Init; Timestamp=${getFileTimestamp(DateTime.now())}');

        sessionTimestamp = getFileTimestamp(DateTime.now());
        loggingFilepath =
            '$cacheDir${Platform.pathSeparator}log$sessionTimestamp.txt';
        loggingFile = File(loggingFilepath);
        if (!loggingFile.existsSync()) loggingFile.createSync();
        loggingFile.writeAsString(':: Logging session started ::\n\n',
            mode: FileMode.writeOnlyAppend);
        FlutterError.onError = (errorDetails) {
          if (loggingFile.existsSync()) {
            var out =
                ':: E ::${getFileTimestamp(DateTime.now())} ${errorDetails.exception.toString()} \n:: Stacktrace: ${errorDetails.stack.toString()} \n';
            loggingFile.writeAsString(out, mode: FileMode.writeOnlyAppend);
          }

          //logger.e('Timestamp=${getFileTimestamp(DateTime.now())}',
          //    error: errorDetails.toStringShort(), stackTrace: errorDetails.stack);
        };

        init();
      });
    }
    _optionsFocusNode = FocusNode();
    initGlobalData();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    disposeGlobalData();
    _optionsFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool paused = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // went to Background
      paused = true;
    }
    if (state == AppLifecycleState.resumed) {
      // came back to Foreground
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {});
      });
      paused = false;
    }
  }

  void init() async {
    List<Future> futures = [];
    prefs = await SharedPreferences.getInstance();
    await getSettings();
    createSystemFiles();
    initColorSpecs();
    loadAssets();
    var statusA = await Permission.storage.status;
    var statusB = await Permission.manageExternalStorage.status;
    if (!statusA.isGranted || !statusB.isGranted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.manageExternalStorage,
        Permission.storage,
      ].request();
    }
    await loadDirectory();
    await loadFile(defaultFile);
    _notifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;
    //findSelectedList();
    listIndex = getSelectedListIndexForTabs();
    historyList.add(listIndex);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black87,
    ));
    if (isMobile()) {
      // For sharing images coming from outside the app while the app is closed
      futures.add(ReceiveSharingIntent.getInitialMedia()
          .then((List<SharedMediaFile> value) async {
        sharedFiles = value;
        if (sharedFiles.isEmpty) return;
        prefs = await SharedPreferences.getInstance();
        final directory = await getBaseDir();
        androidDir = '${directory.path}/playlists';
        defaultDir = prefs.getString('defaultDir') ?? androidDir;
        unselectAllLists();
        await loadFile(sharedFiles.first.path.replaceAll(' ', '_'));
        sharedFiles.clear();
        //setState(() {});
      }));

      // For sharing or opening urls/text coming from outside the app while the app is closed
      futures.add(
          ReceiveSharingIntent.getInitialText().then((String? value) async {
        sharedText = value ?? '';
        if (sharedText.isEmpty) return;
        prefs = await SharedPreferences.getInstance();
        final directory = await getBaseDir();
        androidDir = '${directory.path}/playlists';
        defaultDir = prefs.getString('defaultDir') ?? androidDir;
        var fileName = '$defaultDir/${DateTime.now().toIso8601String()}'
            .replaceAll(' ', '_');
        unselectAllLists();
        await importFile(fileName, sharedText);
        sharedText = "";
        //setState(() {});
      }));
    }
    futures.add(FastCachedImageConfig.init(
        subDir: cacheDir, clearCacheAfter: const Duration(days: 365 * 99)));
    await Future.wait(futures).then((value) => setState(() {})).catchError((e) {
      print(e);
    });
  }

  Widget buildTabs() {
    int index = getSelectedListIndexForTabs();
    if (index != -1) {
      tabController = TabController(
          initialIndex: index, length: getFilteredLists().length, vsync: this);
      tabController!.addListener(() {
        listIndex = tabController!.index;
        // list changed logic
        filteredListChosen(listIndex);
        addHistory(listIndex);
        //setState(() {});
      });
    }
    return tabController == null
        ? buildListNavigationButtons(context, true)
        : TabBar(
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            indicatorPadding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            labelColor: Colors.white70,
            isScrollable: true,
            controller: tabController,
            tabs: buildListPicker());
  }

  List<Widget> buildListPicker() {
    List<Widget> temp = [];
    for (int i = 0; i < getFilteredLists().length; i++) {
      DisplayItem item = getFilteredLists()[i];
      temp.add(buildContainer(Text(item.getDisplayData()),
          color: i == listIndex ? Colors.white24 : Colors.white10));
    }
    return temp;
  }

  @override
  Widget build(BuildContext context) {
    mainState = setState;
    if ((screenWidth == 0 && isMobile()) || !isMobile()) {
      screenWidth = MediaQuery.of(context).size.width;
      screenHeight = MediaQuery.of(context).size.height;
    }

    if (scrollDataController.hasClients) {
      if (cachePos != null && saveScrollPosition) {
        scrollDataController = ScrollController(initialScrollOffset: cachePos!);
        cachePos = null;
      } else {
        if (resetScroll) {
          scrollDataController = ScrollController(initialScrollOffset: 0);
          resetScroll = false;
        } else {
          scrollDataController = ScrollController(
              initialScrollOffset: scrollDataController.position.pixels);
        }
      }
      scrollDataController.addListener(() {
        if (cachePosTimer != null && cachePosTimer!.isActive) {
          cachePosTimer!.cancel();
        }
        cachePosTimer = Timer(const Duration(milliseconds: 300), () {
          prefs.setDouble(cachePosKey(), scrollDataController.position.pixels);
          cachePosTimer?.cancel();
          cachePosTimer = null;
        });
      });
    }
    return _buildForPlatform();
  }

  Widget _buildForPlatform() {
    if (isMobile()) {
      return GestureDetector(
          onPanUpdate: (details) async {
            // Swiping in right direction.
            int sensitivity = 8;

            num currentTime = DateTime.now().millisecondsSinceEpoch;
            num timeDifference = currentTime - lastHotkeyPress;
            if (timeDifference < 200) return;

            if (details.delta.dx > sensitivity) {
              lastHotkeyPress = currentTime;
              await prevSelectedList();
            }

            // Swiping in left direction.
            if (details.delta.dx < -sensitivity) {
              lastHotkeyPress = currentTime;
              await nextSelectedList();
            }
          },
          child: _buildMainContent());
    } else {
      return RawKeyboardListener(
          autofocus: true,
          focusNode: mainFocus,
          onKey: _onKey,
          child: _buildMainContent());
    }
  }

  Widget _buildMainContent() {
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
                  children: [
                    Expanded(
                        child: Align(
                            alignment: Alignment.topLeft, child: buildCount())),
                    _buildOptionsPopup(),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.all(0),
                        onPressed: () {
                          settingsPressed();
                        },
                        icon: const Icon(Icons.settings)),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.all(0),
                        onPressed: () {
                          listsPressed();
                        },
                        icon: const Icon(Icons.list)),

                    //buildListNavigationButtons(context, true),
                  ],
                ),
              ),
              useFavs
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                                onPressed: () {
                                  favViewMode = 0;
                                  setState(() {});
                                },
                                child: const Text('View All')),
                            TextButton(
                                onPressed: () {
                                  favViewMode = 1;
                                  setState(() {});
                                },
                                child: const Text('View Favorites')),
                            TextButton(
                                onPressed: () {
                                  favViewMode = 2;
                                  setState(() {});
                                },
                                child: const Text('View Not Favorites'))
                          ]))
                  : Container(),
              Row(children: [
                historyList.length < 2 || historyIndex + 1 >= historyList.length
                    ? Container()
                    : IconButton(
                        padding: EdgeInsets.all(0),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          if (historyIndex >= historyList.length) {
                            historyIndex = 0;
                          } else {
                            historyIndex += 1;
                          }
                          var selected =
                              getFilteredLists()[historyList[historyIndex]];
                          listIndex = historyList[historyIndex];
                          // list changed logic
                          filteredListChosen(listIndex);
                        },
                        icon: Icon(Icons.arrow_back_ios_new)),
                Expanded(child: buildMainSearchBar()),
                historyList.length < 2 || historyIndex == 0
                    ? Container()
                    : IconButton(
                        padding: EdgeInsets.all(0),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          historyIndex -= 1;
                          var selected =
                              getFilteredLists()[historyList[historyIndex]];
                          listIndex = historyList[historyIndex];
                          // list changed logic
                          filteredListChosen(listIndex);
                        },
                        icon: Icon(Icons.arrow_forward_ios_rounded))
              ]),
              buildTabs(),
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
                  child: ReorderableListView.builder(
                    scrollController: scrollDataController,
                    buildDefaultDragHandles: false,
                    itemCount: displayList.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _buildDataDisplay(index),
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex = newIndex - 1;
                        }
                        final element = displayList.removeAt(oldIndex);
                        displayList.insert(newIndex, element);
                        addAuditData(
                            element.getDisplayData(), false, false, oldIndex);
                        writeFile();
                      });
                    },
                  )))
        ],
      ),
    );
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
        return const SettingsPage();
      },
    ));
  }

  void addBtnPressed() async {
    if (isWeb()) {
      webFilePicker();
      return;
    }
    showDialog(
        context: context, builder: (BuildContext context) => const AddDialog());
  }

  /// Earth (Home planet): Water, Iron, Lead (Secret fish)
  Widget _buildDataDisplay(int index) {
    DisplayItem displayItem = displayList[index];

    if (displayItem.isJson) {
      return showCard(displayItem)
          ? displayItem.buildJSONItem(context, index)
          : Container(
              key: Key('OrderedList-$index'),
            );
    } else {
      Widget content;
      if (displayItem.getDisplayData().contains(mainSep)) {
        content = _buildDetailedListItems(index);
      } else {
        content = _buildDefaultListItem(index);
      }
      return _buildDefaultDisplay(index, content);
    }
  }

  Widget _buildOptionsPopup() {
    return MenuAnchor(
      childFocusNode: _optionsFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () {
            useHandles = !useHandles;
            setState(() {});
          },
          child: const Text('Edit'),
        ),
        MenuItemButton(
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
          child: const Text('Shuffle'),
        ),
        MenuItemButton(
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
          child: const Text('Sort'),
        ),
        MenuItemButton(
          onPressed: addBtnPressed,
          child: const Text('Add'),
        ),
        //MenuItemButton(
        //  onPressed: () {
        //    settingsPressed();
        //  },
        //  child: const Text('Settings'),
        //),
        //MenuItemButton(
        //  onPressed: () {
        //    listsPressed();
        //  },
        //  child: const Text('Lists'),
        //),
        if (useCheckboxes)
          SubmenuButton(menuChildren: <Widget>[
            MenuItemButton(
              onPressed: () {
                cbViewMode = 0;
                prefs.setInt(checkboxFilterKey(), cbViewMode.toInt());
                setState(() {});
              },
              child: Text(checkedOptions[0]),
            ),
            MenuItemButton(
              onPressed: () {
                cbViewMode = 1;
                prefs.setInt(checkboxFilterKey(), cbViewMode.toInt());
                setState(() {});
              },
              child: Text(checkedOptions[1]),
            ),
            MenuItemButton(
              onPressed: () {
                cbViewMode = 2;
                prefs.setInt(checkboxFilterKey(), cbViewMode.toInt());
                setState(() {});
              },
              child: Text(checkedOptions[2]),
            ),
          ], child: const Text('Checked Filter'))
      ],
      builder: (_, MenuController controller, Widget? child) {
        return IconButton(
          visualDensity: VisualDensity.compact,
          focusNode: _optionsFocusNode,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }

  Widget _buildCheckedFilter() {
    if (!useCheckboxes) return Container();
    return DropdownButton<String>(
      value: checkedOptions[cbViewMode.toInt()],
      elevation: 16,
      onChanged: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          //
          cbViewMode = checkedOptions.indexOf(value!);
          prefs.setInt(checkboxFilterKey(), cbViewMode.toInt());
        });
      },
      items: checkedOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildDefaultDisplay(int index, Widget content) {
    DisplayItem displayItem = displayList[index];
    return GestureDetector(
        key: Key('OrderedList-$index'),
        onLongPress: () {
          showDialog(
              context: context,
              builder: (BuildContext context) =>
                  buildAdvancedDialog(displayItem, index));
        },
        onDoubleTap: () {
          List<String> lists =
              listList.map((e) => e.getDisplayData().toLowerCase()).toList();
          if (lists.contains(displayItem.getDisplayData().toLowerCase())) {
            int chosenItem = listList.indexWhere((element) => element
                .getDisplayData()
                .toLowerCase()
                .contains(displayItem.getDisplayData().toLowerCase()));
            if (chosenItem != -1 && chosenItem < listList.length) {
              listChosen(chosenItem);
              addHistory(getFilteredLists().indexWhere((element) => element
                  .getDisplayData()
                  .toLowerCase()
                  .contains(displayItem.getDisplayData().toLowerCase())));
            }
          }
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
                child: Row(
                  children: [
                    Expanded(child: content),
                    !useHandles
                        ? Container()
                        : ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                    !useHandles ? Container() : const SizedBox(width: 16)
                  ],
                ))
            : Container());
  }

  Widget _buildDetailedListItems(int index) {
    DisplayItem displayItem = displayList[index];
    List<Widget> dataArr = [];
    List<String> attributes = [];
    attributes.addAll(displayItem.trueData.split(mainSep));
    for (int i = 0; i < attributes.length; i++) {
      var attribute = attributes[i];
      dataArr.add(_buildDetailedListItem(attribute, i == 0));
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: dataArr))),
      hideActions
          ? Container()
          : Container(
              padding: const EdgeInsets.all(8.0),
              child: useCheckboxes
                  ? _buildDataListCheckbox(index)
                  : _buildMoveToBottomButton(index)),
      const SizedBox(width: 16)
    ]);
  }

  /// Example:
  /// Earth (Home planet): Water, Iron, Lead (Secret treasure)
  Widget _buildDetailedListItem(String str, bool isFirst) {
    List<Widget> dataArr = [];
    List<String> attributes = [];
    Widget head;
    if (str.contains(secSep)) {
      attributes.addAll(str.split(secSep));
      head = Container(
          decoration: BoxDecoration(
              color: !darkMode ? Colors.black12 : Colors.white10,
              borderRadius: const BorderRadius.all(Radius.circular(12))),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Text(
            decodeString(attributes.first.trim()),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: getColorSpec(attributes.first)),
          ));
      attributes.removeAt(0);
    } else {
      if (str.contains(',')) {
        head = const SizedBox();
        attributes.add(str.trim());
      } else {
        if (str.trim().isNotEmpty) {
          head = str.contains('img=')
              ? ImageBuilder(imageStr: str)
              : Container(
                  decoration: BoxDecoration(
                      color: !darkMode ? Colors.black12 : Colors.white10,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12))),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text(
                    decodeString(str.trim()),
                    style: isFirst
                        ? TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: getColorSpec(str))
                        : TextStyle(color: getColorSpec(str)),
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
          Widget dataWidget = element.contains('img=')
              ? ImageBuilder(imageStr: element)
              : Container(
                  decoration: BoxDecoration(
                      color: !darkMode ? Colors.black12 : Colors.white10,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(12))),
                  margin: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text(decodeString(element),
                      style: TextStyle(color: getColorSpec(element))));
          dataArr.add(dataWidget);
        }
      }
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, child: head),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(children: dataArr))
              ]))),
    ]);
  }

  Widget _buildDefaultListItem(int index) {
    DisplayItem displayItem = displayList[index];

    Widget fav = useFavs ? FavoriteButton(index: index) : Container();

    Widget btn = useCheckboxes
        ? _buildDataListCheckbox(index)
        : _buildMoveToBottomButton(index);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text(displayItem.getDisplayData())))),
        hideActions
            ? Container()
            : Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [fav, btn])),
        const SizedBox(
          width: 16,
        )
      ],
    );
  }

  Widget _buildMoveToBottomButton(int index) {
    if (hideActions) return Container();
    return IconButton(
      icon: Icon(
        Icons.move_down,
        color: darkMode ? Colors.white70 : Colors.black87,
      ),
      tooltip: 'Move to Bottom',
      onPressed: () async {
        var d = displayList.removeAt(index);
        displayList.add(d);

        /// TODO don't await?
        addAuditData(d.getDisplayData(), false, false, index);
        setState(() {});
        writeFile();
      },
    );
  }

  Widget _buildDataListCheckbox(int index) {
    if (hideActions) return Container();
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
          value: checkedItems.contains(displayItem.trueData),
          onChanged: (checked) {
            if (checked!) {
              checkedItems.add(displayItem.trueData);
            } else {
              checkedItems.remove(displayItem.trueData);
            }

            addAuditData(displayItem.getDisplayData(), true, checked, 0);
            saveCheckData();
            setState(() {});
          });
    });
  }

  bool showCard(DisplayItem displayItem) {
    if (!displayItem
        .getSearchStr()
        .toLowerCase()
        .contains(searchDisplayController.text.toLowerCase().trim())) {
      return false;
    }

    bool checked =
        checkedItems.contains(displayItem.trueData.replaceAll('\n', '<nl>'));
    if ((cbViewMode == 1 && !checked)) return false;
    if ((cbViewMode == 2 && checked)) return false;
    bool fav = favItems.contains(displayItem.trueData);
    if ((favViewMode == 1 && !fav)) return false;
    if ((favViewMode == 2 && fav)) return false;
    return true;
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
