import 'package:flutter/material.dart';
import 'package:random_app/widget/page/settings/page.dart';

import '../../../model/data.dart';
import '../../../model/ecs.dart';
import '../../../view/theme.dart';
import 'header.dart';

Widget buildSearchScreen(BuildContext context, StateSetter state) {
  return Column(children: [
    buildSettingsHeader(context, state),
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
        hintStyle: TextStyle(color: darkMode ? Colors.white60 : Colors.black54),
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
                              child: Text(searchList[index].getDisplayData())),
                        ),
                      ),
                    ],
                  ));
            })),
  ]);
}
