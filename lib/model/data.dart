import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'display_item.dart';
import 'file.dart';

List<DisplayItem> displayList = [];
List<DisplayItem> listList = [];

List<String> auditData = [];

String defaultDir = '';
String defaultFile = '';
String androidDir = '';

final TextEditingController addController = TextEditingController();
final TextEditingController controller = TextEditingController();
final TextEditingController searchDisplayController = TextEditingController();
final TextEditingController searchListDisplayController =
    TextEditingController();
final TextEditingController searchController = TextEditingController();
List<DisplayItem> searchList = [];

bool useNotes = false;

late StreamSubscription intentDataStreamSubscription;
List<SharedMediaFile> sharedFiles = [];
String sharedText = '';

// 0 all, 1 unchecked, 2 checked
num cbViewMode = 0;

bool useCheckboxes = false;

final TextEditingController eC = TextEditingController();
final TextEditingController dC = TextEditingController();

///TODO create a common state setter
StateSetter? mainState;
StateSetter? listState;

void updateViews() {
  if (mainState != null) {
    mainState!(() {});
  }
  if (listState != null) {
    listState!(() {});
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
  for (int i = 0; i < listList.length; i++) {
    if (i != index) {
      listList[i].selected = false;
    }
  }
}

void setFilteredListSelected(int index) {
  getFilteredLists()[index].selected = !getFilteredLists()[index].selected;
  for (int i = 0; i < getFilteredLists().length; i++) {
    if (i != index) {
      getFilteredLists()[i].selected = false;
    }
  }
}

int getSelectedListIndex() {
  return getFilteredLists().indexWhere((element) => element.selected);
}

List<DisplayItem> getFilteredLists() {
  return listList
      .where((element) => element
          .getDisplayData()
          .trim()
          .toLowerCase()
          .contains(searchListDisplayController.text.toLowerCase()))
      .toList();
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

void nextSelectedList() {
  int currentIndex = getSelectedListIndex();
  if (currentIndex == -1) return;
  if (currentIndex < getFilteredLists().length - 1) {
    filteredListChosen(currentIndex + 1);
  } else {
    filteredListChosen(0);
  }
}

void prevSelectedList() {
  int currentIndex = getSelectedListIndex();
  if (currentIndex == -1) return;
  if (currentIndex != 0) {
    filteredListChosen(currentIndex - 1);
  } else {
    filteredListChosen(getFilteredLists().length - 1);
  }
}

void listChosen(int index) async {
  DisplayItem listItem = listList[index];
  setListSelected(index);
  await load(listItem.trueData);
  updateViews();
  //state(() {});
}

void filteredListChosen(int index) async {
  DisplayItem listItem = getFilteredLists()[index];
  setFilteredListSelected(index);
  await load(listItem.trueData);
  updateViews();
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
