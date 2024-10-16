import 'dart:io';

import 'package:flutter/material.dart';
import 'package:random_app/model/prefs.dart';
import 'package:random_app/model/web_client.dart';
import 'package:random_app/widget/components/searchbar_list.dart';

import '../../model/data.dart';
import '../../model/display_item.dart';
import '../../model/file.dart';
import '../../model/utils.dart';
import '../../model/web_utils.dart';
import '../../view/theme.dart';

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  bool hideStuff = true;

  ScrollController _listController = ScrollController();
  late FocusNode _optionsFocusNode;
  MenuController? _menuController;

  void mSetState() {
    if (listState != null) {
      listState!(() {});
      if (_listController.hasClients) {
        cacheListsPosition = _listController.position.pixels;
        prefs.setDouble(listScrollCacheKey(), cacheListsPosition);
        _listController = ScrollController(
            initialScrollOffset: _listController.position.pixels);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (cacheListsPosition > 0) {
      _listController =
          ScrollController(initialScrollOffset: cacheListsPosition);
    }
    _optionsFocusNode = FocusNode();
    urlController = TextEditingController();
    urlController.text = webPath;
    //hideStuff = isAndroid() ? true : false;
  }

  @override
  void dispose() {
    listState = null;
    _optionsFocusNode.dispose();
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildListScreen();
  }

  Widget buildListScreen() {
    listState = setState;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lists'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(width: showDirUpBtn() ? 16 : 0),
              showDirUpBtn()
                  ? Container(
                      decoration: const BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () => moveToParentDirectory(context),
                        icon: Icon(Icons.upload_rounded,
                            color: darkMode ? Colors.white : Colors.black),
                      ))
                  : Container(),
              Expanded(child: buildListSearchBar()),
              _buildOptionsPopup()
            ],
          ),
          if (isWebMode)
            Row(children: [
              const Text('Server Address: '),
              Expanded(
                  child: TextField(
                controller: urlController,
                onSubmitted: (value) async {
                  webPath = value;
                  prefs.setString('WEB_PATH', value);
                  await WebClient().loadFiles(value);
                  updateViews();
                },
              )),
              const SizedBox(
                width: 16,
              )
            ]),
          Expanded(
              key: UniqueKey(),
              child: Scrollbar(
                thumbVisibility: isMobile() ? false : true,
                thickness: isMobile() ? 0.0 : 16.0,
                controller: _listController,
                child: ListView.builder(
                    controller: _listController,
                    itemCount: listList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildListItem(context, index, setState);
                    }),
              ))
        ],
      ),
    );
  }

  Widget _buildOptionsPopup() {
    return MenuAnchor(
      childFocusNode: _optionsFocusNode,
      menuChildren: <Widget>[
        if (isWeb())
          MenuItemButton(
            onPressed: webModeCheckboxChanged,
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [const Text("Web files?"), _buildWebModeCheckbox()],
                )),
          ),
        if (!isWeb())
          MenuItemButton(
            onPressed: systemCheckboxChanged,
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Text("Show System Files?"),
                    _buildShowSystemFilesCheckbox()
                  ],
                )),
          ),
        if (!isWeb())
          MenuItemButton(
            onPressed: showDirCheckboxChanged,
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Text("Show Directories?  "),
                    _buildShowDirectoryCheckbox(),
                  ],
                )),
          ),
        if (!isMobile())
          MenuItemButton(
              onPressed: () {
                chooseDefaultDir(context);
                setState(() {});
              },
              child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Text('Choose Default List'))),
        if (isMobile() || isWeb())
          MenuItemButton(
              onPressed: () {
                openFile(context, setState);
                setState(() {});
              },
              child: const Padding(
                  padding: EdgeInsets.all(4), child: Text('Import List'))),
        if (isMobile())
          MenuItemButton(
              onPressed: () {
                exportFile();
                setState(() {});
              },
              child: const Padding(
                  padding: EdgeInsets.all(4), child: Text('Export List'))),
        if (isMobile() || isWeb())
          MenuItemButton(
              onPressed: () {
                exportAllFiles();
                setState(() {});
              },
              child: const Padding(
                  padding: EdgeInsets.all(4), child: Text('Export All'))),
        MenuItemButton(
            onPressed: () {
              if (isWeb()) {
                webFilePicker();
                return;
              }
              showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      _buildAddListDialog(setState));
            },
            child:
                const Padding(padding: EdgeInsets.all(4), child: Text('Add'))),
      ],
      builder: (_, MenuController controller, Widget? child) {
        _menuController = controller;
        return IconButton(
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

  bool showDirUpBtn() {
    if (isMobile()) {
      return showDirectories && !isTopLevelDir();
    } else {
      return showDirectories;
    }
  }

  //TODO Test me
  bool isTopLevelDir() {
    if (currentDir.isEmpty) {
      currentDir = defaultDir;
    }
    return currentDir == androidDir;
  }

  Widget _buildListItem(BuildContext context, int index, StateSetter state) {
    DisplayItem listItem = listList[index];
    return showCard(listItem)
        ? GestureDetector(
            onLongPress: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      _buildAdvancedListDialog(index, state));
            },
            onTap: () async {
              await listChosen(index, setState: false);
              if (isWebMode) {
                prefs.setString('WEB_PATH', webPath);
                await WebClient().loadFiles(webPath);
                updateViews();
              }
              historyIndex = 0;
              historyList = [getSelectedListIndexForTabs()];
              if (mainState != null) {
                mainState!(() {});
              }
              if (listItem.isDirectory()) {
                _listController.jumpTo(0);
              }
              mSetState();
            },
            child: Container(
                decoration: BoxDecoration(
                    color:
                        getSelectedCardColor(index == getSelectedListIndex()),
                    borderRadius: const BorderRadius.all(Radius.circular(12))),
                margin: const EdgeInsets.fromLTRB(12.0, 4, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(listItem.getDisplayData()),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(child: getIcon(listItem)),
                      ),
                    ),
                  ],
                )),
          )
        : Container();
  }

  Widget getIcon(DisplayItem listItem) {
    if (listItem.isSystemFile()) {
      return Icon(Icons.data_object,
          color: darkMode ? Colors.white70 : Colors.black87);
    }
    if (listItem.isDirectory()) {
      return Icon(Icons.folder_open_rounded,
          color: darkMode ? Colors.white70 : Colors.black87);
    }
    return Icon(Icons.density_medium_rounded,
        color: darkMode ? Colors.white70 : Colors.black87);
  }

  bool showCard(DisplayItem listItem) {
    if (listItem.isSystemFile() && !showSystemFiles) {
      return false;
    }
    if (listItem.isDirectory() && !showDirectories) {
      return false;
    }
    if (!listItem
        .getDisplayData()
        .toLowerCase()
        .contains(searchListDisplayController.text.toLowerCase().trim())) {
      return false;
    }
    return true;
  }

  Dialog _buildAddListDialog(StateSetter outerState) {
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
              Row(children: [
                Text('Create Directory?: '),
                _buildNewFileCheckbox()
              ]),
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
                controller: addController,
              ),
              TextButton(
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    if (createDirs) {
                      var dirPath =
                          '$defaultDir${Platform.pathSeparator}${addController.text.replaceAll(' ', '_')}';
                      print(dirPath);
                      Directory(dirPath).createSync();
                      loadDirectory();
                    } else {
                      var newFileName = addController.text.replaceAll(' ', '_');
                      displayList.add(DisplayItem(newFileName));
                      var st =
                          '$defaultDir${Platform.pathSeparator}$newFileName';
                      File file = File(st);
                      if (file.existsSync()) {
                        file.deleteSync();
                      }
                      file.createSync();
                      defaultFile = st;
                    }
                    addController.text = '';
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  Dialog _buildAdvancedListDialog(int index, StateSetter outerState) {
    String oldFp = listList[index].trueData;
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
                    var cp =
                        getCheckedFilePath(filePath: listList[index].trueData);
                    print(cp);
                    File(cp).deleteSync();

                    prefs.remove('${listList[index].trueData}_auditData');
                    deleteFile(listList[index].trueData);
                    listList.remove(listList[index]);
                    updateViews();
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
                  controller: controller..text = listList[index].trueData,
                  onChanged: (text) {
                    listList[index].trueData = text;
                  }),
              TextButton(
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: () {
                    //adjust fav data
                    var oldFavFp = getFavFilePath(filePath: oldFp);
                    var newFavFp =
                        getFavFilePath(filePath: listList[index].trueData);
                    File(oldFavFp).renameSync(newFavFp);
                    var usesFavs =
                        prefs.getBool(useFavKey(path: oldFp)) ?? false;
                    prefs.remove(useFavKey(path: oldFp));
                    //print(newFavFp);
                    if (usesFavs) {
                      prefs.setBool(
                          useFavKey(path: listList[index].trueData), true);
                    }

                    //adjust check and audit data
                    var oldCheckFp = getCheckedFilePath(filePath: oldFp);
                    var newCheckFp =
                        getCheckedFilePath(filePath: listList[index].trueData);
                    File(oldCheckFp).renameSync(newCheckFp);
                    var usesChecks =
                        prefs.getBool(useCheckboxesKey(path: oldFp)) ?? false;
                    prefs.remove(useCheckboxesKey(path: oldFp));
                    //print(newCheckFp);
                    if (usesChecks) {
                      prefs.setBool(
                          useCheckboxesKey(path: listList[index].trueData),
                          true);
                    }
                    var hidActions =
                        prefs.getBool(hideActionsKey(path: oldFp)) ?? false;
                    var hidScroll =
                        prefs.getBool(saveScrollPositionKey(path: oldFp)) ??
                            false;
                    prefs.remove(hideActionsKey(path: oldFp));
                    prefs.remove(cacheSearchStrKey(path: oldFp));
                    prefs.remove(cachePosKey(path: oldFp));
                    prefs.remove(saveScrollPositionKey(path: oldFp));
                    //print(newCheckFp);
                    if (hidActions) {
                      prefs.setBool(
                          hideActionsKey(path: listList[index].trueData), true);
                    }
                    if (hidScroll) {
                      prefs.setBool(
                          saveScrollPositionKey(path: listList[index].trueData),
                          true);
                    }
                    //audit rename
                    var audit = prefs.getString('${oldFp}_auditData') ?? '';
                    prefs.remove('${oldFp}_auditData');
                    prefs.setString(
                        '${listList[index].trueData}_auditData', audit);
                    //File Rename
                    File(oldFp).renameSync(listList[index].trueData);

                    reloadFile(index);
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  Widget _buildShowSystemFilesCheckbox() {
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: showSystemFiles,
          onChanged: (condition) => systemCheckboxChanged());
    });
  }

  void systemCheckboxChanged() {
    showSystemFiles = !showSystemFiles;
    prefs.setBool('SHOW_SYSTEM_FILES', showSystemFiles);
    updateViews();
    _menuController?.close();
    setState(() {});
  }

  Widget _buildWebModeCheckbox() {
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: isWebMode,
          onChanged: (condition) => webModeCheckboxChanged());
    });
  }

  void webModeCheckboxChanged() async {
    isWebMode = !isWebMode;
    prefs.setBool('WEB_MODE', isWebMode);
    if (isWebMode) {
      await WebClient().loadFiles(webPath);
    } else {
      loadDirectory();
    }
    updateViews();
    _menuController?.close();
    setState(() {});
  }

  Widget _buildShowDirectoryCheckbox() {
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: showDirectories,
          onChanged: (condition) => showDirCheckboxChanged());
    });
  }

  void showDirCheckboxChanged() {
    showDirectories = !showDirectories;
    prefs.setBool('SHOW_DIRS', showDirectories);
    updateViews();
    _menuController?.close();
    setState(() {});
  }

  bool createDirs = false;

  Widget _buildNewFileCheckbox() {
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return Checkbox(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(width: 2.0, color: Colors.white70),
          ),
          value: createDirs,
          onChanged: (condition) {
            createDirs = condition ?? false;
            setState(() {});
          });
    });
  }
}
