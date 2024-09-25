import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:json_text_field/json_text_field.dart';
import 'package:logger/logger.dart';
import 'package:random_app/model/audit.dart';
import 'package:random_app/widget/components/list_navigation_buttons.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'display_item.dart';
import 'file.dart';

const mainSep = '|';
const secSep = ';';

List<DisplayItem> displayList = [];
List<DisplayItem> listList = [];

List<String> auditData = [];

String defaultDir = '';
String dataDir = '';
String defaultFile = '';
String androidDir = '';
String androidTempDir = '';
String assetDir = '';
String cacheDir = '';
String guideTxt = '';

double imgSize = 80;

late ScrollController scrollDataController;

late TextEditingController addController;
late TextEditingController controller;
late JsonTextFieldController jsonController;
late TextEditingController searchDisplayController;
late TextEditingController searchListDisplayController;
late TextEditingController searchController;
List<DisplayItem> searchList = [];

bool useNotes = false;
bool resetScroll = false;

late StreamSubscription intentDataStreamSubscription;
List<SharedMediaFile> sharedFiles = [];
String sharedText = '';

// 0 all, 1 unchecked, 2 checked
num cbViewMode = 0;
// 0 all, 1 unchecked, 2 checked
num favViewMode = 0;

bool useCheckboxes = false;
bool useFavs = false;
bool saveScrollPosition = false;
bool hideActions = false;
bool showSystemFiles = false;
bool showDirectories = false;

double screenWidth = 0;
double screenHeight = 0;

double? cachePos;

int listIndex = 0;
int historyIndex = 0;
TabController? tabController;

double cacheListsPosition = 0.0;
double cacheDataPosition = 0.0;

late TextEditingController eC;
late TextEditingController dC;

late FocusNode mainFocus;
late FocusNode searchFocus;
late FocusNode auditFocus;

late Logger logger;
String loggingFilepath = '';
late File loggingFile;

String sessionTimestamp = 'null';

List<String> checkedItems = [];
List<String> favItems = [];
List<int> historyList = [];

///TODO create a common state setter
StateSetter? mainState;
StateSetter? listState;

void initGlobalData() {
  mainFocus = FocusNode();
  searchFocus = FocusNode();
  auditFocus = FocusNode();
  addController = TextEditingController();
  controller = TextEditingController();
  jsonController = JsonTextFieldController();
  searchDisplayController = TextEditingController();
  searchListDisplayController = TextEditingController();
  searchController = TextEditingController();
  scrollDataController = ScrollController();
  eC = TextEditingController();
  dC = TextEditingController();
}

void disposeGlobalData() {
  mainFocus.dispose();
  searchFocus.dispose();
  auditFocus.dispose();
  addController.dispose();
  controller.dispose();
  jsonController.dispose();
  searchDisplayController.dispose();
  searchController.dispose();
  scrollDataController.dispose();
  eC.dispose();
  dC.dispose();
  intentDataStreamSubscription.cancel();
  //tabController?.dispose();
}

void updateViews() {
  if (mainState != null) {
    mainState!(() {});
  }
  if (listState != null) {
    listState!(() {});
  }
  if (countState != null) {
    countState!(() {});
  }
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

void setListSelected(int index) {
  listList[index].selected = !listList[index].selected;
  listIndex = index;
  for (int i = 0; i < listList.length; i++) {
    if (i != index) {
      listList[i].selected = false;
    }
  }
}

void setFilteredListSelected(int index) {
  getFilteredLists()[index].selected = !getFilteredLists()[index].selected;
  listIndex = index;
  for (int i = 0; i < getFilteredLists().length; i++) {
    if (i != index) {
      getFilteredLists()[i].selected = false;
    }
  }
}

int getSelectedListIndex() {
  return listList.indexWhere((element) => element.trueData == defaultFile);
}

int getSelectedListIndexForTabs() {
  var i = getFilteredLists()
      .indexWhere((element) => element.trueData == defaultFile);
  listIndex = i;
  return i;
}

List<DisplayItem> getFilteredLists() {
  var tmp = listList
      .where((element) => element
          .getDisplayData()
          .trim()
          .toLowerCase()
          .contains(searchListDisplayController.text.toLowerCase()))
      .toList();
  tmp.removeWhere((element) => element.isDirectory() || element.isSystemFile());
  return tmp;
}

String getSelectedListName() {
  try {
    DisplayItem? list =
        getFilteredLists().firstWhere((element) => element.selected);
    return list.getDisplayData();
  } catch (e) {
    return "Unknown";
  }
}

Future nextSelectedList() async {
  int currentIndex = getSelectedListIndexForTabs();
  if (currentIndex == -1) return;
  if (currentIndex < getFilteredLists().length - 1) {
    await filteredListChosen(currentIndex + 1);
    addHistory(currentIndex + 1);
  } else {
    await filteredListChosen(0);
    addHistory(0);
  }
}

Future prevSelectedList() async {
  int currentIndex = getSelectedListIndexForTabs();
  if (currentIndex == -1) return;
  if (currentIndex != 0) {
    await filteredListChosen(currentIndex - 1);
    addHistory(currentIndex - 1);
  } else {
    await filteredListChosen(getFilteredLists().length - 1);
    addHistory(getFilteredLists().length - 1);
  }
}

void addHistory(int index) {
  if (historyList[historyIndex] == index) return;
  historyList = historyList.sublist(historyIndex);
  historyList.insert(0, index);
  historyIndex = 0;
}

Future<void> listChosen(int index, {bool setState = true}) async {
  DisplayItem listItem = listList[index];
  setListSelected(index);
  await load(listItem.trueData);
  if (setState) {
    updateViews();
  }
  getAuditData();
  //state(() {});
}

Future filteredListChosen(int index) async {
  DisplayItem listItem = getFilteredLists()[index];
  setFilteredListSelected(index);
  await load(listItem.trueData);
  updateViews();
  getAuditData();
  //state(() {});
}

void shuffle({bool writeChanges = true}) {
  displayList.shuffle();
  updateViews();
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
  updateViews();
  if (writeChanges) {
    writeFile();
  }
}
