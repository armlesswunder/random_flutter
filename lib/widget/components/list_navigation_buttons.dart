import 'package:flutter/material.dart';

import '../../model/data.dart';
import '../../view/theme.dart';

Widget buildListNavigationButtons(BuildContext context, bool showListName) {
  return Row(children: [
    Container(
        width: 80,
        decoration: const BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Center(
            child: IconButton(
          onPressed: () => prevSelectedList(),
          icon: Icon(Icons.skip_previous_rounded,
              color: darkMode ? Colors.white : Colors.black),
        ))),
    Expanded(
        child: SizedBox(
            width: screenWidth / 2,
            child: showListName ? buildTitle() : Container())),
    Container(
        alignment: Alignment.centerRight,
        width: 80,
        decoration: const BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Center(
            child: IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onPressed: () => nextSelectedList(),
          icon: Icon(Icons.skip_next_rounded,
              color: darkMode ? Colors.white : Colors.black),
        ))),
  ]);
}

StateSetter? countState;

Widget buildTitle() {
  return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            child: Text(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          getSelectedListName(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        )),
        const SizedBox(
          width: 8,
        ),
        Flexible(child: buildCount())
      ]);
}

Widget buildCount() {
  return StatefulBuilder(builder: (BuildContext context, state) {
    var count = displayList.length;
    var sub = displayList.where((element) => element
        .getSearchStr()
        .trim()
        .toLowerCase()
        .contains(searchDisplayController.text.trim().toLowerCase()));
    count = sub.length;
    countState = state;
    return Text('Count: ${count}',
        //return Text(urlRoute,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white60));
  });
}
