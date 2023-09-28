import 'package:flutter/material.dart';
import 'package:random_app/widget/searchbar_list.dart';

import '../../model/data.dart';
import '../../model/display_item.dart';
import '../../model/file.dart';
import '../../view/theme.dart';
import '../list_navigation_buttons.dart';

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  @override
  void dispose() {
    listState = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildListScreen();
  }

  Widget buildListScreen() {
    return StatefulBuilder(builder: (BuildContext context, StateSetter state) {
      listState = state;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lists'),
        ),
        body: Column(
          children: [
            Row(children: [
              Container(
                  decoration: const BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                  margin: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                  child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextButton(
                          child: Text(
                            'Import List',
                            style: TextStyle(
                              color:
                                  darkMode ? Colors.white70 : Colors.deepPurple,
                            ),
                          ),
                          onPressed: () {
                            openFile(context, state);
                            state(() {});
                          }))),
              Container(
                  decoration: const BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                  margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                  child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextButton(
                          child: Text('Export List',
                              style: TextStyle(
                                color: darkMode
                                    ? Colors.white70
                                    : Colors.deepPurple,
                              )),
                          onPressed: () {
                            exportFile();
                            state(() {});
                          }))),
              Container(
                  decoration: const BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                  margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                  child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextButton(
                          child: Text('Choose Default List',
                              style: TextStyle(
                                color: darkMode
                                    ? Colors.white70
                                    : Colors.deepPurple,
                              )),
                          onPressed: () {
                            chooseDefaultDir(context);
                            state(() {});
                          })))
            ]),
            buildListSearchBar(),
            buildListNavigationButtons(context, false),
            Expanded(
              key: UniqueKey(),
              child: ListView.builder(
                  itemCount: listList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildListItem(context, index, state);
                  }),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => _buildAddListDialog(state));
          },
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add),
        ),
      );
    });
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
            onTap: () => listChosen(index),
            child: Container(
                decoration: BoxDecoration(
                    color: getSelectedCardColor(listItem.selected),
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
                        child: Center(
                          child: listItem.isDirectory()
                              ? Icon(Icons.folder_open_rounded,
                                  color: darkMode
                                      ? Colors.white70
                                      : Colors.black87)
                              : Icon(Icons.density_medium_rounded,
                                  color: darkMode
                                      ? Colors.white70
                                      : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                )),
          )
        : Container();
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
                    displayList.add(DisplayItem(addController.text));
                    createFile(addController.text, context, outerState);
                    addController.text = '';
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  Dialog _buildAdvancedListDialog(int index, StateSetter outerState) {
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
                    reloadFile(index);
                    Navigator.pop(context);
                  }),
            ],
          );
        }));
  }

  bool showCard(DisplayItem displayItem) {
    if (!displayItem
        .getDisplayData()
        .toLowerCase()
        .contains(searchListDisplayController.text.toLowerCase().trim())) {
      return false;
    }

    return true;
  }
}
