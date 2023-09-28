import 'package:flutter/material.dart';

import '../model/data.dart';
import '../model/file.dart';
import '../view/theme.dart';

Widget buildListNavigationButtons(BuildContext context, bool showListName,
    {bool showDirectoryUpBtn = true}) {
  return Row(children: [
    showDirectoryUpBtn
        ? Container(
            decoration: const BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.all(Radius.circular(12))),
            margin: const EdgeInsets.fromLTRB(16, 8, 0, 8),
            child: IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () => moveToParentDirectory(context),
              icon: Icon(Icons.upload_rounded,
                  color: darkMode ? Colors.white : Colors.black),
            ))
        : const SizedBox(width: 16),
    Container(
        decoration: const BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.all(Radius.circular(12))),
        margin: EdgeInsets.fromLTRB(16, 8, showDirectoryUpBtn ? 0 : 8, 8),
        child: IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: () => prevSelectedList(),
          icon: Icon(Icons.skip_previous_rounded,
              color: darkMode ? Colors.white : Colors.black),
        )),
    showListName ? buildTitle() : Container(),
    Container(
        decoration: const BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.all(Radius.circular(12))),
        margin: const EdgeInsets.fromLTRB(16, 8, 0, 8),
        child: IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: () => nextSelectedList(),
          icon: Icon(Icons.skip_next_rounded,
              color: darkMode ? Colors.white : Colors.black),
        )),
  ]);
}

Widget buildTitle() {
  return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(children: [
        Text(
          getSelectedListName(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(
          width: 8,
        ),
        Text('Item Count: ${displayList.length}',
            style: const TextStyle(color: Colors.white60)),
      ]));
}
